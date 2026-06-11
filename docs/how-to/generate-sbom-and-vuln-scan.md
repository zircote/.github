---
diataxis_type: how-to
diataxis_goal: produce CycloneDX + SPDX SBOMs and a Grype report for an image digest
---

# How to Generate an SBOM and Vulnerability Scan

## Overview

`sbom-and-scan.yml` produces a CycloneDX SBOM (primary), an SPDX export, and a
Grype vulnerability report for any image digest, uploaded as a build artifact.
Use it when you need the documents themselves — compliance requests, audits,
offline analysis. If you only need the SBOM and vulnerability report *attached
to the digest*, `build-attest.yml` / `sign-and-attest.yml` already do that;
you do not need this workflow in a standard release pipeline.

## Prerequisites

- The image already pushed and addressable by digest.
- For images in a private AWS ECR registry: an IAM role the job can assume to
  pull (GHCR images need only `packages: read`).

## Steps

### 1. Call the workflow with the digest

```yaml
jobs:
  sbom:
    permissions:
      id-token: write
      contents: read
      packages: write
    uses: zircote/.github/.github/workflows/sbom-and-scan.yml@<SHA>
    with:
      image-ref: ghcr.io/zircote/<your-repo>@sha256:<digest>
```

For an image in ECR, add the role so the job can authenticate:

```yaml
    with:
      image-ref: <account>.dkr.ecr.<region>.amazonaws.com/<repo>@sha256:<digest>
      aws-role-arn: ${{ vars.PROMOTE_ROLE_ARN }}
```

### 2. (Optional) Attest the SBOM to the digest

Only for standalone callers that want the CycloneDX SBOM attached as an OCI
referrer without running a full build:

```yaml
    with:
      image-ref: ghcr.io/zircote/<your-repo>@sha256:<digest>
      attest: true
```

### 3. Download the artifact

The run uploads one artifact named `sbom-and-scan` containing `sbom.cdx.json`,
`sbom.spdx.json`, and `grype.json`:

```sh
gh run download <run-id> --name sbom-and-scan
```

## Verification

```sh
jq .bomFormat sbom.cdx.json          # "CycloneDX"
jq .spdxVersion sbom.spdx.json       # "SPDX-2.x"
jq '.matches | length' grype.json    # vulnerability match count
```

The Grype scan never fails the run (`fail-build: false`) — it reports; gating
happens at promotion and admission.

## Related

- [Reusable workflows reference](../reference/workflows.md#sbom-and-scanyml) — full inputs
- [Onboard a repo to attested delivery](onboard-a-repo-to-attested-delivery.md) — the standard pipeline that attests SBOMs automatically
