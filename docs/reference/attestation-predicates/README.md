---
diataxis_type: reference
diataxis_describes: the custom attestation predicate types the quality gates sign
---

# Attestation Predicate Definitions

The `gh-attested` quality gates turn each gate's verdict into a signed,
digest-bound in-toto attestation (see the
[`gh-attested` skill](../../../.github/skills/gh-attested/SKILL.md) and its
`references/attestation-seam.md`). Most gates use a **custom predicate type**
because no standard one exists. This directory is the canonical definition of
each custom type: its identifier (URI), the predicate **body** that
`reusable-attest-scan.yml` (or `reusable-k6.yml`) signs, the **verdict rule** a
verifier applies, and a JSON Schema for the body.

> **Namespace note.** The `https://zircote.github.io/attestations/<gate>/v1`
> URIs are **stable type identifiers**, used with `gh attestation verify
> --predicate-type`. They need not be live URLs to function. These definitions
> are the source of truth; if/when `zircote.github.io` serves them, this tree is
> what gets published.

## Custom predicate types

| Predicate type (URI) | Signed by | Body format | Verdict rule | Schema |
|----------------------|-----------|-------------|--------------|--------|
| `…/attestations/sast/v1` | `reusable-attest-scan.yml` | CodeQL SARIF 2.1.0 | fail on any `error`/high+ result | [sast/v1](sast/v1/schema.json) |
| `…/attestations/sca/v1` | `reusable-attest-scan.yml` | OSV-Scanner SARIF 2.1.0 | fail on vuln ≥ threshold | [sca/v1](sca/v1/schema.json) |
| `…/attestations/container-scan/v1` | `reusable-attest-scan.yml` | Trivy image SARIF 2.1.0 | fail on vuln ≥ severity | [container-scan/v1](container-scan/v1/schema.json) |
| `…/attestations/iac-license/v1` | `reusable-attest-scan.yml` | Trivy fs SARIF 2.1.0 | fail on misconfig/license ≥ severity | [iac-license/v1](iac-license/v1/schema.json) |
| `…/attestations/scorecard/v1` | `reusable-attest-scan.yml` | OpenSSF Scorecard SARIF 2.1.0 | advisory; enforce min score | [scorecard/v1](scorecard/v1/schema.json) |
| `…/attestations/dast/v1` | `reusable-attest-scan.yml` | OWASP ZAP SARIF 2.1.0 (AF) | fail on alert ≥ risk | [dast/v1](dast/v1/schema.json) |
| `…/attestations/k6-load/v1` | `reusable-k6.yml` | k6 `--summary-export` JSON | fail if any threshold failed | [k6-load/v1](k6-load/v1/schema.json) |

## Standard predicate types (not defined here)

These gates use predicate types defined upstream — do **not** redefine them:

- **Vulnerability disposition** — `https://openvex.dev/ns/v0.2.0` (OpenVEX),
  signed by `reusable-vex.yml`.
- **Build provenance** — `https://slsa.dev/provenance/v1` (SLSA), signed by
  `attested-delivery`'s `sign-and-attest.yml`.
- **SBOM** — SPDX / CycloneDX via `actions/attest-sbom` (attested-delivery /
  `sbom-and-scan.yml`).

## Reading the verdict

Every custom type's body is the tool's native evidence document. A valid
`gh attestation verify` proves the attestation is authentic and bound to the
subject — **not** that the gate passed. Apply the verdict rule against the body:

```bash
gh attestation verify "$SUBJECT" --owner zircote \
  --signer-workflow zircote/.github/.github/workflows/reusable-attest-scan.yml \
  --predicate-type https://zircote.github.io/attestations/sast/v1 \
  --format json \
  | jq '[.[0].verificationResult.statement.predicate.runs[].results[]?
         | select(.level=="error")] | length'   # 0 ⇒ pass
```

## Versioning

A predicate type's URI ends in a major version (`/v1`). A breaking change to the
body contract or verdict rule bumps to `/v2` (a new directory); `/v1` stays
immutable so existing attestations keep verifying.

## Related

- [How to onboard a repo to attested quality gates](../../how-to/onboard-a-repo-to-attested-quality-gates.md)
  — the guide that wires the gates which sign these predicates.
- [Quality-gate workflows reference](../quality-gate-workflows.md) — the
  workflows that emit each predicate, with key inputs.
- [Why attested quality gates](../../explanation/attested-quality-gates.md) —
  the verdict-as-attestation model behind these types.
