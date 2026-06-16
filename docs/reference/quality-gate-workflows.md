---
diataxis_type: reference
diataxis_describes: the centralized attested quality-gate reusable workflows in zircote/.github
---

# Attested Quality-Gate Workflows Reference

The quality-gate suite is a sibling of the
[attested-delivery workflows](workflows.md). Each workflow runs a CI gate and —
through the seam — turns its verdict into a signed, digest-bound attestation. All
live in `zircote/.github/.github/workflows/` and are called with `uses:`, pinned
to a full 40-character commit SHA:

```yaml
uses: zircote/.github/.github/workflows/<workflow>.yml@<SHA>
```

> **Canonical inputs.** The exhaustive per-workflow input list is maintained in
> the [`gh-attested` skill](../../.github/skills/gh-attested/SKILL.md)'s
> `references/gate-catalog.md` (so it stays single-sourced with the skill that
> wires it). This page is the docs-tree index: each gate's role, key inputs,
> evidence, predicate type, and signer. Pin third-party actions **by SHA, never a
> tag** — the `aquasecurity/trivy-action` compromise (CVE-2026-33634) is the
> standing cautionary case.

## The gates

| Workflow | Gate | Key inputs | Evidence | Predicate type | Signed by |
|----------|------|-----------|----------|----------------|-----------|
| `reusable-attest-scan.yml` | **The seam** — signs any evidence file as a custom-predicate attestation bound to a digest | `subject-name`, `subject-digest`, `predicate-type`, `predicate-artifact`, `predicate-filename` | (any) | (the gate's) | itself |
| `reusable-sast-codeql.yml` | SAST (CodeQL → code scanning) | `languages`, `build-mode` | CodeQL SARIF | `…/attestations/sast/v1` | seam |
| `reusable-sca-osv.yml` | SCA (OSV-Scanner + dependency review PR gate) | `fail-on-severity`, `scan-args` | OSV SARIF + PR check | `…/attestations/sca/v1` | seam |
| `reusable-trivy.yml` | Container vuln + IaC misconfig + license | `image-ref`, `severity`, `scan-iac` | Trivy SARIF | `…/attestations/container-scan/v1`, `…/attestations/iac-license/v1` | seam |
| `reusable-scorecard.yml` | Supply-chain posture (OpenSSF Scorecard) | `publish-results` | Scorecard SARIF | `…/attestations/scorecard/v1` | seam |
| `reusable-vex.yml` | Vulnerability disposition (OpenVEX via `vexctl`) | `subject-name`, `subject-digest`, `vex-path` | OpenVEX JSON | `https://openvex.dev/ns/v0.2.0` | itself |
| `reusable-zap.yml` | DAST (OWASP ZAP; opt-in, needs a target) | `target`, `fail-action` | ZAP SARIF (AF) | `…/attestations/dast/v1` | seam |
| `reusable-k6.yml` | Load / performance (opt-in, needs a target) | `script-path`, `attest` | k6 summary JSON | `…/attestations/k6-load/v1` | itself |
| `reusable-verify-gates.yml` | Fail-closed `gh attestation verify` before deploy | `subject-ref`, `owner`, `signer-workflow`, `predicate-types` | — (fails on any verification error) | — | — |

`…/attestations/<gate>/v1` is shorthand for
`https://zircote.github.io/attestations/<gate>/v1`. Full body format, verdict
rule, and JSON Schema per type:
[attestation predicate definitions](attestation-predicates/README.md).

## Composition with other suites

These gates **compose with, and do not duplicate**:

- [Attested delivery](workflows.md) — build provenance, the keyless signature,
  and SBOM signing on the image digest (`build-attest.yml`,
  `sign-and-attest.yml`, `sbom-and-scan.yml`). Defer those to it.
- `reusable-security.yml` — gitleaks + per-language dependency audits (secret
  detection).

## Signer pinning (verification)

Under SLSA L3 the certificate SAN is the central signer, so verifiers pin
`--signer-workflow`, one per predicate group:

| Predicate group | `--signer-workflow` |
|-----------------|---------------------|
| SARIF gates (sast, sca, container-scan, iac-license, scorecard, dast) | `…/reusable-attest-scan.yml` |
| Vulnerability disposition (OpenVEX) | `…/reusable-vex.yml` |
| Load (k6) | `…/reusable-k6.yml` |

A signed attestation proves a gate **ran and recorded a verdict, not that it
passed** — the policy reads the verdict field. Do not use the cosign-only flags
`--cert-identity-regexp` / `--cert-oidc-issuer` with `gh attestation verify`; it
rejects them.

## See also

- [How to onboard a repo to attested quality gates](../how-to/onboard-a-repo-to-attested-quality-gates.md)
- [Wire your first attested quality gate](../tutorials/first-attested-quality-gate.md)
- [Why attested quality gates](../explanation/attested-quality-gates.md)
- [Attestation predicate definitions](attestation-predicates/README.md)
