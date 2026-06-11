---
diataxis_type: how-to
diataxis_goal: add signing, attestation, and fail-closed verified releases to an application repo
---

# How to Onboard a Repo to Attested Delivery

## Overview

This guide adds signing, attestation, and fail-closed verification to an
application repo by calling the centralized workflows. Full inputs and outputs
for every workflow are in the
[reusable workflows reference](../reference/workflows.md).

## Prerequisites

- The repo builds a container image from a Dockerfile (for binary-only repos,
  use `actions/attest-build-provenance` per artifact instead — see the
  [attested-delivery skill](../../.github/skills/attested-delivery/SKILL.md)
  caller recipes).
- Only if you use registry promotion and the production change gate:
  per-environment registry variables, promotion role ARNs, and a
  change-record issue convention (an approval label; optionally a GitHub
  Projects v2 board with a `Status` field).

## 1. Build and attest in one call

`build-attest.yml` builds, pushes to GHCR by digest, and signs + attests
through the isolated signing workflow. Pin it by full commit SHA:

```yaml
# .github/workflows/release.yml in an application repo
jobs:
  build-attest:
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    uses: zircote/.github/.github/workflows/build-attest.yml@<SHA>
    with:
      image-name: ghcr.io/zircote/<your-repo>
```

If your repo already has a build job that pushes by digest and you only need
signing, call `sign-and-attest.yml` directly instead:

```yaml
  sign:
    needs: build
    permissions:
      id-token: write
      attestations: write
      packages: write
      contents: read
    uses: zircote/.github/.github/workflows/sign-and-attest.yml@<SHA>
    with:
      image-name: ghcr.io/zircote/<your-repo>
      image-digest: ${{ needs.build.outputs.image-digest }}
```

Pin `@<SHA>` to a full commit SHA, never a moving tag. Dependabot's
`github-actions` ecosystem keeps the SHA current via PRs.

## 2. Gate publication on fail-closed verification

Add a verify job between signing and anything that publishes, and make every
publish job `needs:` it — a tag publishes nothing unsigned. With the Step 1
`build-attest` job (which signs internally and outputs the digest):

```yaml
  verify:
    needs: [build-attest]
    permissions:
      id-token: write
      contents: read
      packages: read
      attestations: read
    uses: zircote/.github/.github/workflows/verify-attestation.yml@<SHA>
    with:
      image-ref: ghcr.io/zircote/<your-repo>@${{ needs.build-attest.outputs.image-digest }}
      attestation-repo: zircote/<your-repo>

  publish:
    needs: [verify]
    if: startsWith(github.ref, 'refs/tags/')
    # create the GitHub Release, push tags, etc.
```

(For the own-build + `sign-and-attest.yml` variant, the verify job is
`needs: [build, sign]` and the digest comes from
`${{ needs.build.outputs.image-digest }}`.)

Add `workflow_dispatch` to the release workflow and tag-gate the publish jobs
(as above) so the build → sign → verify chain is exercisable as a dry run
without cutting a version.

## 3. (When you have a deploy target) Promote with verification

Replace any `crane cp`-style promotion with `promote.yml`, which carries the
attestations and re-verifies them at the destination:

```yaml
  promote-staging:
    needs: build-attest
    permissions:
      id-token: write
      contents: read
      packages: read
      attestations: read
    uses: zircote/.github/.github/workflows/promote.yml@<SHA>
    with:
      source-ref: ghcr.io/zircote/<your-repo>@${{ needs.build-attest.outputs.image-digest }}
      dest-repo: ${{ vars.STAGING_REGISTRY_REPO }}
      target-env: staging
      aws-role-arn: ${{ vars.STAGING_PROMOTE_ROLE_ARN }}  # only for ECR destinations
```

## 4. (When you have change governance) Gate production on a change record

Production promotion goes through `promote-prod.yml`, which blocks unless a
GitHub change-record issue is open, carries the approval label
(`change-approved` by default), and records the exact digest being promoted in
its body. Optionally assert a GitHub Projects v2 `Status` as well:

```yaml
  promote-prod:
    permissions:
      id-token: write
      contents: read
      packages: read
      attestations: read
      issues: read
    uses: zircote/.github/.github/workflows/promote-prod.yml@<SHA>
    with:
      source-ref: ${{ vars.STAGING_REGISTRY_REPO }}@${{ inputs.image-digest }}
      dest-repo: ${{ vars.PROD_REGISTRY_REPO }}
      aws-role-arn: ${{ vars.PROD_PROMOTE_ROLE_ARN }}
      change-issue: ${{ inputs.change_issue }}
      project-number: "3"          # optional: also require Projects v2 Status == Approved
    secrets:
      CHANGE_RECORD_TOKEN: ${{ secrets.CHANGE_RECORD_TOKEN }}  # only needed for project-number / cross-repo issues
```

## 5. Add the pin-check gate and document verification

- Add a `pin-check` job to the repo's CI calling the central
  [`pin-check.yml`](enforce-action-sha-pinning.md), then make it a required
  status check.
- Add a "Verifying Release Artifacts" section to the repo's SECURITY.md (or
  rely on the org-wide [SECURITY.md](../../SECURITY.md#verifying-release-artifacts)).

## Verification

```sh
# SLSA L3 provenance
gh attestation verify oci://<image>@<digest> \
  --repo zircote/<your-repo> \
  --signer-workflow zircote/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1

# Signature + SBOM (pin the centralized signer identity)
cosign verify <image>@<digest> \
  --certificate-identity-regexp '^https://github.com/zircote/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

Run these from a workstation, not just in-pipeline — in-pipeline success is
necessary, but independent verification is the acceptance test.

## Requirements checklist

- [ ] Callers pin every centralized workflow `@<SHA>` (full 40-char commit SHA).
- [ ] Every publish/release job `needs:` the verify job (fail closed).
- [ ] `pin-check` runs in CI and is a required status check.
- [ ] Release workflow has a `workflow_dispatch` dry-run path with tag-gated publish jobs.
- [ ] (Promotion only) registry variables and role ARNs configured.
- [ ] (Production gate only) change-record issue convention in place: approval label, digest recorded in the issue body, and — for the Projects v2 status assertion — `CHANGE_RECORD_TOKEN` with project read access.

## Related

- [Reusable workflows reference](../reference/workflows.md) — all inputs, outputs, and secrets
- [Why attested delivery](../explanation/attested-delivery.md) — the invariant behind these steps
- [Enforce admission of attested images](enforce-admission-of-attested-images.md) — the runtime gate
