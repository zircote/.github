# Architecture — invariant, components, interfaces

## The invariant

An artifact (canonically: a container digest) may advance — to a registry
tag consumers pull, to the next environment, to production — only when all
three hold:

1. **Byte-identical** to what was validated: promotion copies by digest,
   never rebuilds, never re-tags loosely.
2. **Attestations travel and re-verify**: SLSA provenance, keyless
   signature, CycloneDX SBOM, and a vulnerability report are attached to
   the digest as OCI referrers and re-verify at each hop.
3. **Publication/promotion is fail-closed**: a verification job gates the
   release; production promotion additionally requires an approved change
   record whose recorded digest equals the digest being promoted.

## Why a reusable workflow is the signer (SLSA Build L3)

Signing runs in a centralized **reusable workflow** the calling repo cannot
modify. The Fulcio certificate's SAN (`job_workflow_ref`) is therefore the
central workflow — `<org>/.github/.github/workflows/sign-and-attest.yml@<sha>`
— while the certificate extensions record the *caller* as the source
repository and ref. Verifiers assert both independently (source repo via
`--repo` / extension 1.3.6.1.4.1.57264.1.12; signer via
`--signer-workflow` / SAN). A composite action cannot provide this
isolation: it runs in the caller's job with the caller's token.

## Components (the central repo's `.github/workflows/`)

| Workflow | Role | Key inputs | Key outputs |
| --- | --- | --- | --- |
| `build-attest.yml` | Single entry point: build → push by digest → sign/attest → self-verify | `image-name`, `context`, `dockerfile`, `build-args`, `sbom`, `vuln-scan` | `image-digest`, `provenance-verified` |
| `sign-and-attest.yml` | The L3 signing boundary: SLSA provenance (GitHub attestation, pushed as referrer), cosign keyless signature, Syft CycloneDX SBOM attestation, Grype vuln attestation, then self-verify with `--signer-workflow` | `image-name` (bare repo), `image-digest` (sha256:…), `sbom`, `vuln-scan`, `cosign-version` | `provenance-verified` |
| `verify-attestation.yml` | Fail-closed gate, callable before any publish/deploy and reused between registry hops | `image-ref` (by digest), `attestation-repo` (owner/repo), `signer-workflow`, `certificate-identity-regexp`, `require-sbom`, optional `aws-role-arn` for ECR | none — fails on any verification error |
| `promote.yml` | Referrer-carrying `cosign copy` between registries + post-copy re-verify | `source-ref` (by digest), `dest-repo` (bare), `target-env`, `aws-role-arn` | promoted ref |
| `promote-prod.yml` | `promote.yml` behind the change-record gate (GitHub issue: open + approval label + digest recorded in the body) and the production environment | + `change-issue`, `approval-label`, `project-number` (optional Projects v2 `Status` assertion via `CHANGE_RECORD_TOKEN`) | |
| `sbom-and-scan.yml` | Standalone SBOM (CycloneDX + SPDX) and Grype scan | `image-ref` | reports as artifacts |
| `dora-emit.yml` | Deployment events (deployment = production digest promotion); call with `if: always()` so failures emit | `image-digest`, env/metadata | |
| `pin-check.yml` | Fails on the first `uses:` not pinned to a full 40-char SHA (local `./` and `docker://...@sha256:` exempt) | `scan-dir` (default `.github`) | |
| `mirror-images.yml` | The single controlled ingress from external registries: `cosign copy` of pinned upstream images into `ghcr.io/<org>/mirror/*` (weekly + dispatch) | matrix of source→dest | |

Caller permission sets (job-level, for the `uses:` jobs):
- sign: `id-token: write`, `attestations: write`, `packages: write`, `contents: read`
- verify: `id-token: write`, `contents: read`, `packages: read`, `attestations: read`
- pin-check: `contents: read`

Conventions: every `uses:` of a central workflow is pinned
`@<full 40-char SHA>`; Dependabot's `github-actions` ecosystem keeps pins
current; inputs taking a full image reference (`image-ref`, `source-ref`)
are digest-pinned, inputs taking a repository (`image-name`, `dest-repo`)
carry no tag/digest.

## Registry posture (when org policy is single-registry)

Application repos pull and push **only** the org registry. The mirror
workflow is the one sanctioned ingress: BuildKit builder image, language
base images, and runtime base images are copied to
`ghcr.io/<org>/mirror/*` (internal visibility) and consumed via
`driver-opts: image=…` and Dockerfile `FROM` lines. Logins precede Buildx
setup so every pull is authenticated.

## Release pipeline shape (the proven caller DAG)

```text
test ─┬─ build (binary) ──────────┬─ publish   (tag only,
      ├─ sbom / changelog / bundle┘             needs verify)
      └─ container-build (matrix) → container-merge (digest out)
                                        → sign-and-attest → verify ─┘
```

Publication requires `verify`. `workflow_dispatch` runs the same chain
with publish jobs tag-gated — the dry run that lets the attested chain be
exercised without cutting a version.

## CI shape (the recommended fail-fast consolidation)

Stage 0: lint (+ `pin-check` in parallel, gating merge not stages) →
Stage 1: test, supply-chain → Stage 2: coverage, container scan. One
concurrency group per ref; PR pushes cancel the superseded pipeline.
