# Attested Delivery — Centralized Workflows

zircote delivers containers through a single, caller-immutable
signing/verify/promote authority that every repository calls. A container
digest reaches consumers only if it is byte-identical to what was validated,
carries signed attestations that re-verify at every hop, and publication is
gated on fail-closed verification.

The documentation for this system lives in the
[docs index](../README.md), organized by the
[Diátaxis](https://diataxis.fr/) framework:

| Need | Document |
| --- | --- |
| Learn it hands-on | [Tutorial: your first attested release](../tutorials/first-attested-release.md) |
| Onboard a repo | [How to onboard a repo to attested delivery](../how-to/onboard-a-repo-to-attested-delivery.md) |
| Enforce pinning | [How to enforce action SHA pinning](../how-to/enforce-action-sha-pinning.md) |
| Generate SBOMs | [How to generate an SBOM and vulnerability scan](../how-to/generate-sbom-and-vuln-scan.md) |
| Measure deployments | [How to emit DORA deployment metrics](../how-to/emit-dora-deployment-metrics.md) |
| Enforce at runtime | [How to enforce admission of attested images](../how-to/enforce-admission-of-attested-images.md) |
| Look up workflow inputs/outputs | [Reusable workflows reference](../reference/workflows.md) |
| Understand the design | [Why attested delivery](../explanation/attested-delivery.md) |
| Verify a release as a consumer | [SECURITY.md — Verifying Release Artifacts](../../SECURITY.md#verifying-release-artifacts) |

This directory retains the working project plan:

- [Rollout status](rollout-status.md) — what is constituted, the current
  caller pin, and the remaining phases with acceptance tests.
