# Rollout Checklist — phases, exit gates, acceptance tests

Pace: pilot-first, with soak windows between phases. Do not advance past a
failing exit gate. Phases 2–3 apply only when targets deploy (Phase 0
discovery decides).

## Phase 0 — Constitute and prove the loop on a pilot

- [ ] Central repo holds the canonical workflows; every action inside them
      pinned by full SHA; Actions access level = `organization`.
- [ ] Registry mirrors stood up and populated, if single-registry policy
      applies; mirror packages internal/public visibility.
- [ ] Pilot repo wired per its shape (recipes A–D), publication gated on
      the fail-closed verify job; release dry-run dispatchable.
- [ ] pin-check job in pilot CI; full SHA migration done; required check.
- [ ] SECURITY.md verification section published in the pilot.
- [ ] **Exit gate:** AT-05 and AT-06 pass from a workstation against a
      published digest; the dry-run chain (build → sign → verify) is green.

## Phase 1 — Standardize

- [ ] SBOM standardized (CycloneDX primary) as an attested referrer.
- [ ] Pin-by-SHA codified as org policy; pin-check required on the
      candidate repo set.
- [ ] CODEOWNERS on the central signing workflows (platform/security
      review required to change the signer).
- [ ] **Exit gate:** AT-06 (SBOM retrievable + verifiable) on all pilots;
      second repo onboarded by following the skill alone.

## Phase 2 — Promotion and governance (deploying targets only)

- [ ] `promote.yml` between environments; post-copy re-verify (AT-02).
- [ ] `promote-prod.yml` behind the change-record gate: an approved GitHub
      change-record issue recording the promoting digest (issue↔digest
      equality, AT-07).
- [ ] DORA emission live (deployment = prod digest promotion, AT-08).
- [ ] **Exit gate:** AT-01/AT-02/AT-07 pass; a promotion without an
      approved change record is blocked before any copy.

## Phase 3 — Admission and operations (deploying targets only)

- [ ] Admission control audit → enforce (Kyverno/Gatekeeper for k8s;
      pre-deploy verify gate for ECS/Lambda) (AT-01 at runtime).
- [ ] Running-digest equality checks (AT-03); rollback drill to a verified
      digest (AT-04).
- [ ] Org ruleset expansion to the full repo set.

## Acceptance tests

| ID | Property | How to check |
| --- | --- | --- |
| AT-01 | Unsigned digest denied | admission denies the pod / pre-deploy gate fails before service update |
| AT-02 | Attestations survive promotion | `cosign verify-attestation --type cyclonedx <dest>@<digest>` exits 0 at the destination registry |
| AT-03 | Running digest == approved digest | three-way sha256 equality: running workload, validated, change record |
| AT-04 | Rollback re-points to a verified digest | roll back, then run the verify set against the target digest |
| AT-05 | SLSA provenance verifies, signer pinned | `gh attestation verify oci://<image>@<digest> --repo <org>/<repo> --signer-workflow <org>/.github/.github/workflows/sign-and-attest.yml --predicate-type https://slsa.dev/provenance/v1` |
| AT-06 | Signature + SBOM verify against the central signer identity | `cosign verify` + `cosign verify-attestation --type cyclonedx` with the signer identity regexp (see verification.md) |
| AT-07 | Promotion without change record blocked | `promote-prod.yml` fails at the gate; no copy executes |
| AT-08 | Deployment events emit | production promotion increments the deployment metric (and failures emit via `if: always()`) |
