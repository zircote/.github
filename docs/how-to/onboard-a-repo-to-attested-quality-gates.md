---
diataxis_type: how-to
diataxis_goal: bring a public OSS repo to complete, attested quality-gate coverage
---

# How to Onboard a Repo to Attested Quality Gates

## Overview

This guide wires a **public** open-source repository to the centralized quality
gates — SAST, SCA, secret detection, container/IaC/license scanning, SBOM,
vulnerability disposition, supply-chain posture, peer review, and (optionally)
load and DAST — and turns each gate's verdict into a signed, digest-bound
attestation. It composes with
[attested delivery](./onboard-a-repo-to-attested-delivery.md): build provenance
and SBOM signing come from there; this guide adds the scanning/testing gates and
the attestation seam.

The `gh-attested` skill automates this end to end (assess → plan → implement).
This guide is the manual path and the mental model.

## Prerequisites

- A **public** repository (the GitHub-proprietary scanners — CodeQL, secret
  scanning, dependency review — are free only on public repos).
- `gh` CLI authenticated; permission to edit workflows and repo settings.
- The central reusable workflows live on `zircote/.github`; record its HEAD SHA
  — it is the pin for every caller.

## 1. Assess current coverage

Run the queries in the skill's `references/assessment.md` and fill the coverage
matrix: for each of the 12 gates — present? attested? a merge gate? a deploy
gate? Note the repo's languages (drives CodeQL `languages`) and whether a
container image or running app exists (drives Trivy image scan, k6, ZAP).

## 2. Wire the merge-time gates

Copy `templates/quality-gates-caller.yml` to `.github/workflows/quality-gates.yml`,
replace `__org__` with `zircote`, pin every `@<sha>`, and set `languages:` and
gate inputs for the repo. The universal core:

```yaml
jobs:
  sast:    # CodeQL → code scanning
  sca:     # OSV-Scanner + dependency-review PR gate
  posture: # OpenSSF Scorecard
  trivy:   # IaC + license (+ image when image-ref is set)
  pin-check:
```

Add `dependabot.yml` (github-actions ecosystem) and a `CODEOWNERS` from the
templates.

## 3. Add the attestation seam (deploy-time gates)

For each gate whose verdict must gate *deployment* (not just merge), have the
gate job upload its evidence file as an artifact, then call
`reusable-attest-scan.yml` with that gate's predicate type (see
`references/attestation-seam.md`). Defer build-provenance and SBOM signing to
`sign-and-attest.yml` (attested delivery).

## 4. Enforce

- **Merge**: apply `templates/ruleset.json` (`gh api -X POST
  repos/<o>/<r>/rulesets --input ruleset.json`) after a diff-against-current
  preview — required status checks (`sast / analyze`, `sca / dependency-review`,
  `trivy / iac-license`, `pin-check / pin-check`), required reviews + CODEOWNERS,
  signed commits, linear history.
- **Native scanners**: enable code-scanning default setup, secret scanning, and
  push protection via the API (see `references/repo-config.md`).
- **Deploy**: put `reusable-verify-gates.yml` in the deploy job's `needs:` —
  fail-closed `gh attestation verify` before anything ships.

Secrets and variables are **guided, never written**: most gates need none. Set
any optional ones (`GITLEAKS_LICENSE`, deploy credentials) yourself with
`gh secret set`.

## 5. Verify end-to-end

Run `actionlint` and `pin-check` (zero unpinned `uses:`), dispatch the caller,
confirm SARIF lands in the Security tab and the seam produces a signed
attestation, then run every command in `references/verification.md`
**independently** from a workstation against the produced attestation.

## Boundaries

GitHub gates merges and deployment jobs, not Kubernetes admission (external —
Kyverno / policy-controller). Private repos need GHAS licenses for
CodeQL/secret-scanning/dependency-review. A signed attestation proves a gate ran
and recorded a verdict, not that it passed — read the verdict.
