# Integration Recipes — language awareness and caller patterns

## Per-ecosystem table

Syft (inside `sign-and-attest.yml`) generates the image SBOM regardless of
language — ecosystem SBOMs are optional extras, not substitutes. The image
attestation chain is language-agnostic; what varies is the CI you must
preserve and the pinning equivalents.

| Ecosystem | Build/test gates to preserve | Reproducibility flag | Supply-chain tooling notes |
| --- | --- | --- | --- |
| Rust (Cargo.toml) | fmt, clippy, `cargo test` (all feature sets), tarpaulin/grcov if present | `--locked` everywhere | `cargo audit` BEFORE `cargo deny` in a shared job (constraint 5); `deny.toml` may pin `db-path` |
| Node (package.json) | lint, typecheck, test | `npm ci` / `pnpm install --frozen-lockfile` | `npm audit` advisory; consider `npm publish --provenance` for the package itself, separate from image attestation |
| Python (pyproject.toml) | lint (ruff), typecheck, pytest | `uv sync --frozen` / hash-pinned requirements | `pip-audit`; bandit if present |
| Go (go.mod) | vet, test | go.sum is the lock | `govulncheck` |
| JVM (pom.xml / gradle) | test, verify | lockfiles vary (gradle locking / maven enforcer) | OWASP dependency-check if present |
| Generic / other | whatever CI exists — never remove gates while wiring attestation | pin what the toolchain allows | image-level Grype from sign-and-attest still applies |

Channel-encoding actions: any action whose ref selects behavior (e.g.
`dtolnay/rust-toolchain@stable`) needs an explicit input
(`with: toolchain: stable`) once pinned to a SHA.

## Caller recipe A — repo with no container build

```yaml
jobs:
  build-attest:
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    uses: <org>/.github/.github/workflows/build-attest.yml@<full-sha>
    with:
      image-name: ghcr.io/<org>/<repo>
```

## Caller recipe B — build already pushes by digest

```yaml
  sign:
    needs: [build]
    permissions:
      id-token: write
      attestations: write
      packages: write
      contents: read
    uses: <org>/.github/.github/workflows/sign-and-attest.yml@<full-sha>
    with:
      image-name: ghcr.io/<org>/<repo>
      image-digest: ${{ needs.build.outputs.image-digest }}

  verify:
    needs: [build, sign]
    permissions:
      id-token: write
      contents: read
      packages: read
      attestations: read
    uses: <org>/.github/.github/workflows/verify-attestation.yml@<full-sha>
    with:
      image-ref: ghcr.io/<org>/<repo>@${{ needs.build.outputs.image-digest }}
      attestation-repo: <org>/<repo>
```

## Caller recipe C — multi-arch matrix (the proven pattern)

Keep the existing per-platform matrix (`push-by-digest=true`) and manifest
merge; add digest capture as a job output of the merge job, then recipes
B's `sign`/`verify` consuming `needs.container-merge.outputs.image-digest`:

```yaml
  container-merge:
    needs: [container-build]
    outputs:
      image-digest: ${{ steps.digest.outputs.image-digest }}
    steps:
      # login BEFORE buildx setup (constraint 6); driver-opts from the
      # mirror when registry policy applies
      # ... docker buildx imagetools create -t <tags> <repo>@sha256:<digests> ...
      - name: Resolve manifest digest
        id: digest
        env:
          DOCKER_METADATA_OUTPUT_JSON: ${{ steps.meta.outputs.json }}
        run: |
          TAG=$(jq -r '.tags[0]' <<< "$DOCKER_METADATA_OUTPUT_JSON")
          DIGEST=$(docker buildx imagetools inspect "$TAG" \
            --format '{{json .Manifest}}' | jq -r '.digest')
          echo "image-digest=$DIGEST" >> "$GITHUB_OUTPUT"
```

## Caller recipe D — binaries/bundles (the proven full release shape)

Reference implementations: `zircote/rlm-rs` and `zircote/rust-template`
(`release.yml`, `publish.yml`, `package-homebrew.yml`). The shape:

```text
[meta] -> [build xN + attest] -> [sbom + attest] -> [verify]** -> [release]*
          [test] [audit] ---------------------------^
(* tag-gated; ** fail-closed BEFORE the release exists)
```

Required elements:

1. **meta job** — resolve ALL project specificity at runtime so nothing
   is renamed when a template is instantiated (var-driven):
   ```sh
   META=$(cargo metadata --no-deps --format-version 1)
   BIN=$(jq -r '[.packages[0].targets[] | select(.kind | index("bin"))][0].name' <<< "$META")
   # tag pushes: VERSION="${GITHUB_REF#refs/tags/v}"; dispatch dry-runs:
   # VERSION="$(jq -r '.packages[0].version' <<< "$META")-dev"
   ```
2. **Build matrix** with versioned artifact names
   `{bin}-{version}-{platform}` and `cargo build --release --locked`;
   `actions/attest-build-provenance` per leg AT BUILD TIME (before any
   release exists), then upload-artifact.
3. **test + audit gates inside the release workflow** — tags are not
   guaranteed to point at CI-green commits; the release tests itself.
4. **SBOM**: anchore/sbom-action (CycloneDX) + `actions/attest-sbom` with
   `subject-path: dist/*` — binds every binary to the SBOM.
5. **Fail-closed verify job** before the release: assert the artifact
   COUNT (a partial set must never publish), then per binary:
   `gh attestation verify "$f" --repo "$GITHUB_REPOSITORY"` and the same
   with `--predicate-type https://cyclonedx.org/bom`.
6. **Tag-gated release job** (`needs: [meta, verify, audit, test]`) with a
   single `{bin}-{version}-checksums.txt`; `tag_name: ${{ github.ref_name }}`.

**crates.io** (separate `publish.yml`): pre-publish gauntlet with
`--locked`, then Trusted Publishing (OIDC, `rust-lang/crates-io-auth-action`,
no long-lived token; one-time crates.io setup names the workflow file and
environment). After publish: download the registry-served `.crate`
(`curl -fsSL -A '<name>-release-check'` — constraint 15), byte-compare to
`target/package/`, attest the registry bytes. Guard BEFORE publish:
tag version must equal the manifest version (constraint 14).

**Homebrew** (separate `package-homebrew.yml`): `workflow_run` on the
Release workflow (constraint 17); formula SHA via
`set -euo pipefail` + `curl -fsSL` (constraint 16); generate the formula
into the workspace so dry-runs need neither the tap nor its token.

**Template gate**: template repos ship `publish = false` in Cargo.toml.
Each publication job reads it via `cargo metadata` AT THE PACKAGED REF
(`if .packages[0].publish == [] then "false" else "true" end`) and skips
release creation / crates.io / Homebrew while the attest→verify chain
still runs as CI validation. Downstream projects delete the one line to
arm all channels; cargo itself refuses `cargo publish` as a second lock.

Verification for consumers: `gh attestation verify <file> --repo <org>/<repo>`
(no `--signer-workflow` here — the SAN *is* the repo's own workflow when
attestation happens outside the central signer); SBOM binding via
`--predicate-type https://cyclonedx.org/bom`.

## Release gating and dry-run (all shapes)

- Publish job: `needs: [..., verify]` — a tag publishes nothing unsigned.
- Add `workflow_dispatch` to the release workflow; tag-gate publish-side
  jobs with `if: startsWith(github.ref, 'refs/tags/')`. Ensure the image
  tag set includes a non-semver tag (e.g. `type=sha`) so dispatch runs
  still produce a taggable manifest.

## SHA-pin migration procedure

1. Inventory: `grep -rhoE 'uses:\s*\S+' .github/ | sort | uniq -c`.
2. Resolve each tag: `gh api repos/<owner>/<action>/commits/<tag> --jq .sha`;
   prefer the latest *release* tag over moving major tags; keep the version
   as a trailing comment (`@<sha>  # vX.Y.Z`).
3. Branch refs (`@master`, `@main`): pin to the latest release instead.
4. Add the pin-check job to CI (central `pin-check.yml`), then add
   `pin-check / pin-check` to required status checks once green.
5. Dependabot's `github-actions` ecosystem keeps SHAs current afterward.
