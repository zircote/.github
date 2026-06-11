---
diataxis_type: explanation
diataxis_topic: why zircote promotes attested artifacts by digest
---

# Why Attested Delivery

zircote delivers containers through a single, caller-immutable
signing/verify/promote authority that every repository calls. This document
explains the reasoning behind that design: why the digest is the identity, why
signing is isolated in a central reusable workflow, why verification happens at
admission rather than only at build, and why production promotion is gated on a
change record. The design is standards-led, built on
[SLSA](https://slsa.dev/spec/v1.0/levels), [Sigstore](https://docs.sigstore.dev/),
and the [OCI referrers model](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#listing-referrers).

## The promotion invariant

A digest may advance — to a registry tag consumers pull, to the next
environment, to production — only when all three hold:

1. **Byte-identical to what was validated** — promotion copies by digest,
   never by rebuild or tag.
2. **Attestations travel and re-verify** — the SLSA provenance, keyless
   signature, CycloneDX SBOM, and vulnerability report move with the image as
   OCI referrers and re-verify at each hop.
3. **Publication is fail-closed** — a verification job gates every release;
   where a deploy pipeline with change governance exists, production promotion
   additionally requires an approved change record whose recorded digest equals
   the digest being promoted.

### Digest is identity

A container image is identified by its content digest, not by its tag. The OCI
image specification defines the digest as a content identifier: the same bytes
always yield the same digest, and different bytes always yield a different one.
A tag, by contrast, is a mutable pointer — `myimage:latest` can point at one
set of bytes today and a different set tomorrow. Identifying a release
candidate by tag would mean the thing you verified and the thing you run could
silently differ. So the release candidate is the digest, and only the digest.
Tags (the commit SHA is applied as a tag at build time) are informational.

### Build once, promote many

Because the digest is the identity, the artifact is built exactly once. That
digest moves through every environment. Rebuilding per environment produces new
bytes (timestamps, dependency drift, a freshly compromised build tool) and
therefore a different digest: the thing verified in staging would not be the
thing running in production. Build-once-promote-many is not an optimization;
it is the precondition for any verification claim surviving the trip to
production.

### Promotion must carry the referrers

The signature, SLSA provenance, SBOM, and vulnerability report attach to the
digest as OCI *referrers*. A naïve copy (`crane cp`) moves only the manifest
and layers and silently orphans every referrer — the image arrives, the proof
does not. That is why [`promote.yml`](../reference/workflows.md#promoteyml)
uses `cosign copy` (referrer-aware) and re-runs full verification at the
destination before the promotion is considered successful.

## Why signing is a reusable workflow, not a composite action

SLSA Build L3 requires the signing steps to run in a context the calling repo
cannot tamper with. A **reusable workflow** runs with its own
`job_workflow_ref`, so the provenance subject identity is the central workflow
— `zircote/.github/.github/workflows/sign-and-attest.yml` — not the caller. A
composite action runs inside the caller's job and shares its token, so it
provides no such isolation: any repo could alter the steps and still produce a
signature that looks centralized.

This is also why every verifier in the system — `verify-attestation.yml`, an
admission policy, a pre-deploy gate, a consumer running the commands in
[SECURITY.md](../../SECURITY.md#verifying-release-artifacts) — pins the
expected signer identity to that one workflow path. A signature from any other
identity, even one under the same owner, is rejected. See
[SLSA Build L3](https://slsa.dev/spec/v1.0/levels#build-l3) and
[GitHub artifact attestations](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds).

## Why verification happens at admission, not only at build

A build-time check proves the digest was good when it was built. It proves
nothing about what is actually admitted to a runtime months later — a stale
digest, a manually pushed image, or a signature from a compromised workflow.
Enforcement therefore happens at the last possible gate:

- **Kubernetes** — a Kyverno image-verification policy intercepts pod
  admission and verifies signature + attestations against the pinned signer
  identity before the pod starts (rolled out Audit → Enforce).
- **Runtimes without an admission webhook** (ECS, Lambda, bare hosts) — the
  deploy workflow verifies the digest immediately before the service update
  and fails closed.

The practical steps are in
[Enforce admission of attested images](../how-to/enforce-admission-of-attested-images.md).

## Why production promotion is gated on a change record

The first two legs of the invariant are cryptographic; the third is
organizational. An approved change-record ticket that records the digest binds
the technical promotion to a human-authorized change. `promote-prod.yml`
queries the ticket and blocks unless its status is `Approved` — and, when the
digest custom field is configured, unless the ticket's recorded digest equals
the digest being promoted. This is automated evidence checking, not a convened
change board: the gate is a fail-closed API call in the pipeline, which keeps
delivery flowing while preserving an auditable authorization trail.

## Why a deployment is "a production digest promotion"

DORA metrics are only comparable when "deployment" has a precise definition.
Here it is the successful promotion of a digest into production —
[`dora-emit.yml`](../reference/workflows.md#dora-emityml) emits the deployment
event and frequency metric at exactly that moment, tagged by service, status,
and (optionally) AI-authoring cohort so throughput and stability can be
segmented by how the change was authored.

## Further reading

- [Your first attested release](../tutorials/first-attested-release.md) — see
  the whole loop hands-on.
- [Reusable workflows reference](../reference/workflows.md) — exact inputs,
  outputs, and identities.
- [Rollout status](../attested-delivery/rollout-status.md) — what is in place
  today and what comes next.
