---
diataxis_type: reference
diataxis_describes: centralized attested-delivery reusable workflows in zircote/.github
---

# Attested-Delivery Workflows Reference

All workflows live in `zircote/.github/.github/workflows/` and are called
with `uses:`, **pinned to a full 40-character commit SHA** — never a branch or
tag:

```yaml
uses: zircote/.github/.github/workflows/<workflow>.yml@<SHA>
```

Dependabot's `github-actions` ecosystem keeps the SHA current via PRs.

Unless stated otherwise: `aws-region` defaults to `us-east-1`, and
`cosign-version` defaults to `v3.0.6`. Inputs that take a full image
reference (`image-ref`, `source-ref`) must be digest-pinned
(`registry/repo@sha256:...`) — those workflows fail on tag-only refs. Inputs
that take a repository (`image-name`, `dest-repo`) carry no tag or digest;
the digest travels as a separate `image-digest` input or output.

The language CI, release, security, and docs workflows (`reusable-ci-*.yml`,
`reusable-release.yml`, `reusable-security.yml`, `reusable-docs.yml`) are
documented in the [repo README](../../README.md#reusable-workflows).

## `build-attest.yml`

Build a container, push it to GHCR by digest, then sign + attest it via the
isolated `sign-and-attest.yml`. The single entry point for application repos.
The build runs in the caller's context; signing happens inside the isolated
workflow the caller cannot modify. The digest is canonical; the commit-SHA tag
is informational.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `image-name` | string | Yes | — | Image repository without tag/digest (e.g. `ghcr.io/zircote/app`) |
| `context` | string | No | `.` | Docker build context path |
| `dockerfile` | string | No | `Dockerfile` | Path to the Dockerfile |
| `build-args` | string | No | `""` | Newline-delimited build args |
| `sbom` | boolean | No | `true` | Generate + attest a CycloneDX SBOM |
| `vuln-scan` | boolean | No | `true` | Generate + attest a Grype vulnerability report |
| `cosign-version` | string | No | `v3.0.6` | cosign release to install |

**Outputs:**

| Name | Description |
| --- | --- |
| `image-digest` | The immutable sha256 digest of the pushed image |
| `provenance-verified` | `true` when sign-and-attest verified SLSA L3 in this run |

**Caller permissions:** `contents: read`, `packages: write`, `id-token: write`,
`attestations: write`.

## `sign-and-attest.yml`

The SLSA Build L3 isolation boundary. Generates SLSA build provenance, a
keyless cosign signature, a CycloneDX SBOM attestation, and a Grype
vulnerability attestation — all attached to the digest as OCI referrers — then
self-verifies the provenance. The provenance subject identity is this
workflow's `job_workflow_ref`, not the caller's.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `image-name` | string | Yes | — | Image repository without tag/digest |
| `image-digest` | string | Yes | — | Immutable digest pushed by the caller's build (`sha256:...`) |
| `sbom` | boolean | No | `true` | Generate + attest a CycloneDX SBOM |
| `vuln-scan` | boolean | No | `true` | Generate + attest a Grype vulnerability report |
| `cosign-version` | string | No | `v3.0.6` | cosign release to install |

**Outputs:**

| Name | Description |
| --- | --- |
| `provenance-verified` | `true` when `gh attestation verify` (SLSA provenance) passed in this run |

**Caller permissions:** `id-token: write`, `attestations: write`,
`packages: write`, `contents: read`.

**Attestation types produced:**

| Predicate type | Tooling |
| --- | --- |
| `https://slsa.dev/provenance/v1` | `actions/attest-build-provenance` |
| `cyclonedx` (SBOM) | Syft via `anchore/sbom-action`, attested with cosign |
| `https://in-toto.io/attestation/vulns/v0.1` | Grype via `anchore/scan-action`, attested with cosign |

The Grype scan never fails this workflow (`fail-build: false`); gating happens
at promotion and admission.

## `verify-attestation.yml`

Fail-closed verification gate: verifies the keyless signature, the SLSA
provenance, and (optionally) the SBOM attestation against the pinned signer
identity. Reused by `promote.yml` between registry hops and callable before
any publish or deploy.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `image-ref` | string | Yes | — | Fully-qualified image ref by digest |
| `attestation-repo` | string | Yes | — | `owner/repo` that produced the attestation |
| `certificate-identity-regexp` | string | No | central signer regexp¹ | Expected Fulcio cert identity |
| `certificate-oidc-issuer` | string | No | `https://token.actions.githubusercontent.com` | Expected OIDC issuer |
| `require-sbom` | boolean | No | `true` | Also verify the CycloneDX SBOM attestation |
| `aws-role-arn` | string | No | `""` | If set, assume this role and log into ECR before verifying |
| `aws-region` | string | No | `us-east-1` | AWS region |
| `signer-workflow` | string | No | central signer path² | Signer workflow for `gh attestation verify` (`owner/repo/path` form) |

¹ `^https://github.com/zircote/\.github/\.github/workflows/sign-and-attest\.yml@.*$`

² `zircote/.github/.github/workflows/sign-and-attest.yml` — under SLSA L3
the cert SAN is the central signer, so `--repo` alone would fail; the signer
is asserted separately.

**Outputs:** none. The workflow fails on any verification error.

**Caller permissions:** `id-token: write`, `contents: read`, `packages: read`,
`attestations: read`.

## `promote.yml`

Referrer-aware promotion between registries: `cosign copy` carries the image
plus signature and all attestations from the source (e.g. GHCR) to the
destination (e.g. a per-environment registry), preserving the digest, then
re-runs `verify-attestation.yml` at the destination. Fails if `source-ref` is
not digest-pinned or if post-copy verification fails. Runs in the GitHub
Environment named by `target-env`.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `source-ref` | string | Yes | — | Source image by digest |
| `dest-repo` | string | Yes | — | Destination repository without tag/digest |
| `target-env` | string | Yes | — | Environment label (e.g. `staging` \| `prod`) |
| `aws-role-arn` | string | Yes | — | IAM role to assume for an ECR destination registry |
| `aws-region` | string | No | `us-east-1` | AWS region |
| `signer-profile-arn` | string | No | `""` | Optional AWS Signer profile ARN; when set, adds an ECR-native Notation secondary signature on the promoted digest |

**Caller permissions:** `id-token: write`, `contents: read`, `packages: read`,
`attestations: read`.

## `promote-prod.yml`

`promote.yml` behind the change-record gate and the `production` GitHub
Environment. The promotion proceeds only when the change-record ticket's
status is `Approved` — and, when `jira-digest-field` is set, only when the
ticket's recorded digest equals the digest being promoted. Without
`jira-digest-field` a status-only gate is in effect and the run emits a
warning.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `source-ref` | string | Yes | — | Pre-production-verified image by digest |
| `dest-repo` | string | Yes | — | Production repository without tag/digest |
| `aws-role-arn` | string | Yes | — | Production registry IAM role to assume (ECR) |
| `jira-issue-key` | string | Yes | — | Change-record ticket key (e.g. `CHG-1234`) |
| `jira-digest-field` | string | No | `""` | JIRA custom field id holding the approved digest (e.g. `customfield_NNNNN`); enables the ticket↔digest equality assertion |
| `signer-profile-arn` | string | No | `""` | Passed through to `promote.yml` |
| `aws-region` | string | No | `us-east-1` | AWS region |

**Secrets:**

| Name | Required | Description |
| --- | --- | --- |
| `JIRA_BASE_URL` | Yes | JIRA Cloud base URL |
| `JIRA_EMAIL` | Yes | API user email |
| `JIRA_API_TOKEN` | Yes | API token |

**Caller permissions:** `id-token: write`, `contents: read`, `packages: read`,
`attestations: read`.

## `sbom-and-scan.yml`

Standalone SBOM + vulnerability scan for an image by digest. Produces
`sbom.cdx.json` (CycloneDX, primary), `sbom.spdx.json` (SPDX export), and
`grype.json` as a build artifact. `sign-and-attest.yml` already attaches the
CycloneDX SBOM and Grype report as OCI referrers, so `attest` defaults to
`false` here — set it only for standalone callers that want the SBOM
attestation without a full build.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `image-ref` | string | Yes | — | Fully-qualified image ref by digest |
| `attest` | boolean | No | `false` | Also cosign-attest the CycloneDX SBOM to the digest |
| `aws-role-arn` | string | No | `""` | If set, assume role + ECR login before reading the image |
| `aws-region` | string | No | `us-east-1` | AWS region |
| `cosign-version` | string | No | `v3.0.6` | cosign release (when `attest: true`) |

**Outputs:**

| Name | Description |
| --- | --- |
| `artifact-name` | Always `sbom-and-scan` — the uploaded artifact holding both SBOMs and the Grype report |

**Caller permissions:** `id-token: write`, `contents: read`, `packages: write`.

## `dora-emit.yml`

Emit a DORA deployment event and metrics to Datadog. A deployment is defined
as a production digest promotion. Emits a deployment event, a
`zircote.dora.deployment` count metric, and — when `lead-time-seconds` is
nonzero — a `zircote.dora.lead_time_seconds` gauge, all tagged by `env`,
`service`, `status`, and optionally `ai_authoring_mode`.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `environment` | string | Yes | — | Deployment environment |
| `service` | string | Yes | — | Service name (Datadog `service` tag) |
| `status` | string | Yes | — | `success` \| `failure` |
| `git-sha` | string | Yes | — | Commit SHA deployed |
| `image-digest` | string | Yes | — | The promoted image digest |
| `lead-time-seconds` | number | No | `0` | PR-created → deploy lead time (0 if unknown) |
| `authoring-cohort` | string | No | `""` | AI-authoring cohort for DORA segmentation |
| `dd-site` | string | No | `datadoghq.com` | Datadog site (allowlisted domains only) |

**Secrets:**

| Name | Required | Description |
| --- | --- | --- |
| `DD_API_KEY` | Yes | Datadog API key |

**Caller permissions:** `contents: read`.

## `pin-check.yml`

Assert every GitHub Actions `uses:` reference in the caller is pinned to a
full 40-character commit SHA. Local reusable-workflow calls (`uses: ./...`)
and digest-pinned container actions (`uses: docker://...@sha256:...`) are
exempt. Fails on the first unpinned reference.

**Inputs:**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `scan-dir` | string | No | `.github` | Directory to scan for workflow/action files |

**Caller permissions:** `contents: read`.

## `mirror-images.yml`

The single controlled ingress from external registries: `cosign copy` of
pinned upstream images (BuildKit builder, language base images, runtime base
images) into `ghcr.io/zircote/mirror/*`, on a weekly schedule and on dispatch.
Only needed where registry policy restricts external pulls; zircote does not
currently restrict, so the mirror is dormant by default.

**Caller permissions (dispatch):** `packages: write`, `contents: read`.

## Tool baseline

Versions pinned inside the workflows (verify against upstream before relying
on them):

| Tool | Version |
| --- | --- |
| cosign (`sigstore/cosign-installer`) | v3.0.6 (installer v4.1.2) |
| Syft (`anchore/sbom-action`) | v0.24.0 |
| Grype (`anchore/scan-action`) | v7.4.0 |
| `actions/attest-build-provenance` | v4.1.0 |

## See also

- [Onboard a repo to attested delivery](../how-to/onboard-a-repo-to-attested-delivery.md)
- [Why attested delivery](../explanation/attested-delivery.md)
- [Rollout status](../attested-delivery/rollout-status.md)
