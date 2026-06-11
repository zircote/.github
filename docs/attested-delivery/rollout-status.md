# Attested Delivery — Rollout Status

Working project record: what is constituted under zircote, and what remains.
Each phase has an exit gate expressed as acceptance tests (AT-NN). Do not
advance past a failing gate.

## Status

### Done — Constitution (2026-06-11)

- Nine centralized workflows live in `zircote/.github/.github/workflows/`
  (PRs [#438](https://github.com/zircote/.github/pull/438),
  [#439](https://github.com/zircote/.github/pull/439)): `build-attest`,
  `sign-and-attest`, `verify-attestation`, `promote`, `promote-prod`,
  `sbom-and-scan`, `dora-emit`, `pin-check`, `mirror-images`.
- Every action inside them pinned by full SHA; Dependabot keeps pins current.
- **Caller pin:** `2192c47863886d7a867b5042fb08de414f948f49` — resolve the
  current pin with
  `gh api repos/zircote/.github/commits/main --jq .sha` when onboarding.
- `pin-check` runs on every PR to this repo
  ([`pin-check-ci.yml`](../../.github/workflows/pin-check-ci.yml)) and both
  contexts (`pin-check / pin-check`, `pin-check-actions / pin-check`) are
  required status checks on `main`.
- Consumer verification commands published in
  [SECURITY.md](../../SECURITY.md#verifying-release-artifacts).
- The [attested-delivery skill](../../.github/skills/attested-delivery/SKILL.md)
  (self-contained templates + onboarding protocol) is canonical in this repo.

Notes specific to zircote: it is a user account, so GHCR package APIs use
`users/zircote/...` and the central repo is public — its reusable workflows
are callable from any repo without an Actions access-level grant. No registry
restriction applies, so `mirror-images.yml` is dormant.

### Next — Pilot repo (open)

Exit: a real repo cuts a release whose digest verifies independently from a
workstation.

- [ ] Pick a pilot container-shaped repo and wire it per the
  [onboarding guide](../how-to/onboard-a-repo-to-attested-delivery.md)
  (build → sign → verify → publish gated on verify; release dry-run via
  `workflow_dispatch`).
- [ ] `pin-check` as a required check in the pilot.
- [ ] **Gate:** AT-05 and AT-06 pass from a workstation against a published
  digest.

### Later — Promotion, measurement, admission (when a deploy target exists)

- [ ] `promote.yml` between environments; post-copy re-verify (AT-02).
- [ ] `promote-prod.yml` behind the change-record gate with
  `jira-digest-field` set (ticket↔digest equality, AT-07).
- [ ] DORA emission (deployment = production digest promotion, AT-08), with
  `if: always()` so failures emit.
- [ ] Admission enforcement per the
  [admission guide](../how-to/enforce-admission-of-attested-images.md)
  (Audit → Enforce), AT-01 at runtime; running-digest equality (AT-03);
  rollback drill (AT-04).

## Acceptance tests

| ID | Property | How to check |
| --- | --- | --- |
| AT-01 | Unsigned digest denied | admission denies the pod / pre-deploy gate fails before the service update |
| AT-02 | Attestations survive promotion | `cosign verify-attestation --type cyclonedx <dest>@<digest>` exits 0 at the destination registry |
| AT-03 | Running digest == approved digest | three-way sha256 equality: running workload, validated digest, change record |
| AT-04 | Rollback re-points to a verified digest | roll back, then run the verify set against the target digest |
| AT-05 | SLSA provenance verifies, signer pinned | `gh attestation verify oci://<image>@<digest> --repo zircote/<repo> --signer-workflow zircote/.github/.github/workflows/sign-and-attest.yml --predicate-type https://slsa.dev/provenance/v1` |
| AT-06 | Signature + SBOM verify against the central signer identity | `cosign verify` + `cosign verify-attestation --type cyclonedx` with the signer identity regexp (see [SECURITY.md](../../SECURITY.md#verifying-release-artifacts)) |
| AT-07 | Promotion without change record blocked | `promote-prod.yml` fails at the gate; no copy executes |
| AT-08 | Deployment events emit | production promotion increments `zircote.dora.deployment` (and failures emit via `if: always()`) |
