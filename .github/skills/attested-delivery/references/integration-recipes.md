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

## Caller recipe D — binaries/bundles only

```yaml
      - uses: actions/attest-build-provenance@<full-sha>  # vX.Y.Z
        with:
          subject-path: target/release/<binary>
```
Verification for consumers: `gh attestation verify <file> --repo <org>/<repo>`
(no `--signer-workflow` here — the SAN *is* the repo's own workflow when
attestation happens outside the central signer).

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
