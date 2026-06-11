---
diataxis_type: how-to
diataxis_goal: block unverified images from running in Kubernetes and webhook-less runtimes
---

# How to Enforce Admission of Attested Images

## Overview

This guide wires the runtime gate: nothing unverified can actually run. Two
mechanisms cover the common runtime shapes — a Kyverno admission policy for
Kubernetes, and a pre-deploy verification step for runtimes without an
admission webhook (ECS, Lambda, plain hosts). For why enforcement happens at
admission rather than at build, see
[Why attested delivery](../explanation/attested-delivery.md).

No zircote deploy target currently enforces admission — this guide is the
design reference for consumers (and future zircote services) that deploy
attested images anywhere.

## Kubernetes — Kyverno

Kyverno's image-verification policy intercepts pod admission and verifies the
image's signature and attestations before the pod is allowed to start.

Roll out in two stages to avoid blocking legitimate workloads:

1. **Audit** — the policy reports violations but admits the pod. Run for at
   least one full deploy + rollback cycle per workload and confirm zero false
   positives.
2. **Enforce** — flip `validationFailureAction` to `Enforce`. Now an image
   that is unsigned, or signed by an identity other than the centralized
   signer, is denied.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-attested-images
spec:
  validationFailureAction: Audit   # flip to Enforce after the audit soak
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-signature-and-provenance
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "ghcr.io/zircote/*"
          attestors:
            - entries:
                - keyless:
                    issuer: "https://token.actions.githubusercontent.com"
                    subject: "https://github.com/zircote/.github/.github/workflows/sign-and-attest.yml@*"
                    rekor:
                      url: https://rekor.sigstore.dev
          attestations:
            - type: https://slsa.dev/provenance/v1
              attestors:
                - entries:
                    - keyless:
                        issuer: "https://token.actions.githubusercontent.com"
                        subject: "https://github.com/zircote/.github/.github/workflows/sign-and-attest.yml@*"
```

Pin the policy to the centralized signer identity so a signature from any
other workflow is rejected. Primary source:
[Kyverno — Verify Images](https://kyverno.io/docs/policy-types/cluster-policy/verify-images/).

## Runtimes without an admission webhook — pre-deploy verification gate

ECS, Lambda, and plain-host deploys have no admission webhook, so enforcement
happens **in the deploy workflow**: verify the image digest *before* the
service update. The deploy job calls the
[`verify-attestation.yml`](../reference/workflows.md#verify-attestationyml)
reusable workflow and the deploy step `needs:` it, so a bad digest never
reaches the service update:

```yaml
  verify-before-deploy:
    permissions:
      id-token: write
      contents: read
      packages: read
      attestations: read
    uses: zircote/.github/.github/workflows/verify-attestation.yml@<SHA>
    with:
      image-ref: ghcr.io/zircote/<your-repo>@${{ inputs.image-digest }}
      attestation-repo: zircote/<your-repo>

  deploy:
    needs: [verify-before-deploy]
    # only reached when verification passed — fails closed otherwise
```

`cosign verify` and `cosign verify-attestation` exit non-zero on any failure,
which fails the job. Primary source:
[cosign — Verifying](https://docs.sigstore.dev/cosign/verifying/verify/).

### Optional detective control

A deploy-time gate is preventive only at deploy time. For continuously running
workloads, add a scheduled job (or an event rule on task/pod state changes)
that re-verifies each running workload's image digest against the verified
set, alerting on drift.

## Related

- [Why attested delivery](../explanation/attested-delivery.md) — why admission, not build, is the gate
- [Reusable workflows reference](../reference/workflows.md) — `verify-attestation.yml` inputs
- [Rollout status](../attested-delivery/rollout-status.md) — Audit→Enforce sequencing
