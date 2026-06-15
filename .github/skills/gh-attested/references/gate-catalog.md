# Gate catalog — the 12 gates

Distilled from `GITHUB-NATIVE-ATTESTED-QUALITY-GATES.md` (§3–§4). Every box is
free-for-OSS (public repos). Predicate-type URIs under `zircote.github.io/...`
are this org's custom predicates (no standard type exists for those gates);
OpenVEX and SLSA provenance use their standard URIs. Pin actions are listed with
the SHA used by the central reusable workflow.

| # | Gate | Central reusable | Tool / pinned action | Evidence | Predicate type | Merge gate | Deploy gate |
|---|------|------------------|----------------------|----------|----------------|:---:|:---:|
| 1 | SAST | `reusable-sast-codeql.yml` | `github/codeql-action@38697555…` (v4.34.1) | SARIF → code scanning | `https://zircote.github.io/attestations/sast/v1` | ✅ code-scanning check | ✅ seam |
| 2 | SCA | `reusable-sca-osv.yml` | `google/osv-scanner-action@9a498708…` (v2.3.8) + `actions/dependency-review-action@a1d282b3…` (v5.0.0) | SARIF + PR check | `https://zircote.github.io/attestations/sca/v1` | ✅ dep-review + check | ✅ seam |
| 3 | Secret detection | native + `reusable-security.yml` | secret scanning + push protection (config) + `gitleaks/gitleaks-action` | alerts; push block | n/a (preventive) | ✅ push protection | — |
| 4 | Container vuln | `reusable-trivy.yml` (image) | `aquasecurity/trivy-action@ed142fd0…` (v0.36.0) | SARIF | `https://zircote.github.io/attestations/container-scan/v1` | ✅ | ✅ seam |
| 5 | IaC + license | `reusable-trivy.yml` (fs) | `aquasecurity/trivy-action@ed142fd0…` | SARIF | `https://zircote.github.io/attestations/iac-license/v1` | ✅ code-scanning check | ✅ seam |
| 6 | SBOM | `sbom-and-scan.yml` + attested-delivery | Syft / `actions/attest-sbom` | SPDX / CycloneDX | `attest-sbom` (SPDX/CycloneDX) | — | ✅ (attested-delivery) |
| 7 | Vuln disposition | `reusable-vex.yml` | `vexctl@v0.4.1` (go install) | OpenVEX JSON | `https://openvex.dev/ns/v0.2.0` | — | ✅ |
| 8 | Build provenance | attested-delivery `sign-and-attest.yml` | `actions/attest-build-provenance@a2bbfa25…` / SLSA generator | SLSA provenance | `https://slsa.dev/provenance/v1` | — | ✅ |
| 9 | Supply-chain posture | `reusable-scorecard.yml` | `ossf/scorecard-action@4eaacf05…` (v2.4.3) | SARIF + OSSF API | `https://zircote.github.io/attestations/scorecard/v1` | ⚠️ advisory | — |
| 10 | Peer review | rulesets / branch protection / CODEOWNERS / Gitsign | config | reviews API; signed commits | n/a (config) | ✅ | — |
| 11 | Load / perf (opt-in) | `reusable-k6.yml` | `grafana/setup-k6-action@db07bd97…` + `grafana/run-k6-action@de51a739…` | JSON summary + exit 99 | `https://zircote.github.io/attestations/k6-load/v1` | ⚠️ optional | ✅ seam |
| 12 | DAST (opt-in) | `reusable-zap.yml` | `zaproxy/action-full-scan@3c583881…` (v0.13.0) | report (+ SARIF via AF) | `https://zircote.github.io/attestations/dast/v1` | ⚠️ optional | ✅ seam |

The attestation seam itself — `reusable-attest-scan.yml` (`actions/attest@59d89421…`
v4.1.0) — is what turns any evidence file in rows 1, 2, 4, 5, 9, 11, 12 into a
signed, digest-bound claim.

## SARIF hub

CodeQL, OSV-Scanner, Trivy, Scorecard, and ZAP all normalize on SARIF 2.1.0, so
every gate's findings converge on the one code-scanning Security tab. The
code-scanning required status check fails a PR on any `error`/`critical`/`high`
finding — that single check gates merge for rows 1, 2, 4, 5 at once.

## Notes per gate

- **CodeQL languages** — interpreted (`javascript-typescript`, `python`, `ruby`,
  `actions`) run with `build-mode: none`; compiled (`c-cpp`, `csharp`, `go`,
  `java-kotlin`, `swift`) need `autobuild`/`manual` and usually one call each.
- **OSV-Scanner** is the SCA *second opinion* alongside Dependabot (free on all
  plans, configured in `dependabot.yml`) and dependency review (PR gate).
- **Trivy image scan** runs only when the caller passes `image-ref` (a digest).
  IaC + license scan run on the repo filesystem unconditionally.
- **ZAP SARIF** is an engine (Automation Framework) report, not a native action
  input — emit via `cmd-options` and upload as a follow-on step if you want it
  in code scanning. The action attaches an HTML/JSON report artifact by default.
- **k6 / ZAP** require a running target; treat as opt-in.
