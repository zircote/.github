---
name: gh-attested
description: Assess, plan, and implement complete attested quality-gate coverage for a public open-source repo using GitHub-native + free-for-OSS tooling — SAST, SCA, secrets, container/IaC/license, SBOM, VEX, provenance, posture, peer review, load, DAST — each gate's verdict turned into a signed, digest-bound attestation. USE THIS SKILL when user says "assess quality gates", "attested quality gates", "attest CI gates", "add CodeQL/OSV-Scanner/Trivy/Scorecard", "SAST/SCA/DAST attestation", "free-for-OSS security gates", or "wire attested quality gates".
argument-hint: '[owner/repo] [assess|plan|implement|enforce|verify] [--dry-run] [--include=k6,zap] [--help]'
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# gh-attested — Attested Quality Gates (assess → plan → implement)

## Purpose

Bring a public open-source repository to **complete quality-gate coverage**
using only GitHub-native and free-for-OSS tooling, and turn each gate's verdict
into a **signed, digest-bound attestation**. The skill **assesses** current
coverage against the 12-gate map, **plans** the gaps, and **implements** them by
wiring the target as a thin caller of this org's central reusable workflows.

This skill **composes with**, and does not duplicate:

- `attested-delivery` — the container release backbone (SLSA L3 build
  provenance, cosign signing, SBOM/vuln attestation, fail-closed verify,
  `pin-check`). Defer build-provenance and `attest-sbom` to it.
- `reusable-security.yml` — gitleaks + per-language dependency audits.
- `sbom-and-scan.yml` — CycloneDX/SPDX SBOM + Grype.

## Triggers

- "assess this repo's quality-gate coverage"
- "wire attested quality gates / make every CI gate produce an attestation"
- "add CodeQL SAST / OSV-Scanner / Trivy / OpenSSF Scorecard / OpenVEX"
- "set up free-for-OSS security gates and enforce them"
- "verify the gate attestations for a release"

## Using this skill

Invoke by describing intent ("assess quality gates for zircote/widget"). The
skill recognizes these scoping tokens — typed as flags **or** plain English:

- **target** `<owner/repo>` — repo to operate on. Default: the current repo
  (`gh repo view --json nameWithOwner -q .nameWithOwner`). Never guessed.
- **phase** — stop after one phase instead of running the whole pipeline:
  `assess` (read-only coverage matrix), `plan` (read-only wiring list),
  `implement` (opens a PR), `enforce` (apply repo config behind a
  preview + confirm), `verify` (re-verify existing attestations). Omit to run
  Phase 0→4, pausing at each gate.
- **`--dry-run`** — render every artifact and command as a preview; write
  nothing, open no PR, apply no config.
- **`--include=k6,zap`** — opt in to gates that need a running target
  (otherwise k6/ZAP stay documented-not-wired).

Prerequisites: `gh` authenticated; target repo **public** for the free tier
(private ⇒ `references/limitations.md`); Phase 3 (enforce) needs repo admin.

**Help**: when the user asks how to use this skill, or passes `--help` / `-h` /
`help`, read `references/help.md` and present it, then stop.

## Architecture invariant

A gate's verdict reaches the **merge or deploy decision only as a signed
attestation whose signer identity is pinned**. A clean SARIF in the Security
tab is *evidence*; the attestation — an in-toto statement binding a typed
predicate to a subject by digest, signed by a central reusable workflow's OIDC
identity — is the *enforceable claim*. Because signing runs in a central
reusable workflow the caller cannot modify, the Fulcio certificate SAN is the
central signer (SLSA Build L3); verifiers MUST pin `--signer-workflow`, not just
`--owner`.

Two honest caveats, always in force:

- **A signed attestation proves a gate ran and recorded a verdict, not that it
  passed.** The verifying policy must read the verdict field.
- **Free GitHub-proprietary scanners (CodeQL, secret scanning, dependency
  review) are free only on public repos.** This skill targets the public-repo
  free path; the private/licensed path is documented in
  `references/limitations.md`.

## The 12-gate map → provider

| Gate | Provider workflow |
| --- | --- |
| SAST | `reusable-sast-codeql.yml` |
| SCA | `reusable-sca-osv.yml` (+ Dependabot, repo config) |
| Secret detection | native secret scanning + push protection (config) + gitleaks in `reusable-security.yml` |
| Container + IaC + license | `reusable-trivy.yml` |
| SBOM | `sbom-and-scan.yml` + `attest-sbom` (attested-delivery) |
| Vuln disposition (VEX) | `reusable-vex.yml` |
| Build provenance | `attested-delivery` (`sign-and-attest.yml`) |
| Supply-chain posture | `reusable-scorecard.yml` |
| Peer review | rulesets / branch protection / CODEOWNERS / Gitsign (config) |
| Load / perf (opt-in) | `reusable-k6.yml` |
| DAST (opt-in) | `reusable-zap.yml` |
| Attestation seam | `reusable-attest-scan.yml` (signs any evidence file) |
| Fail-closed gate verify | `reusable-verify-gates.yml` |

## Phase protocol

Each phase ends with a verify gate. Do not proceed past a failing gate. Scope
to the phase requested under **Using this skill**; with no phase given, run
0→4, stopping at each gate. Honor `--dry-run` (preview only) throughout.

### Phase 0 — Assess (read-only)

Run the queries in `references/assessment.md` and emit a **coverage matrix**:
for each of the 12 gates — present? attested? a merge gate? a deploy gate? Cover
repo visibility (public ⇒ free tier), languages/build systems (drives CodeQL
languages and which SCA ecosystems), whether a container image or a running app
exists (drives Trivy image scan, k6, ZAP), default branch via the API
(`gh api repos/<o>/<r> --jq .default_branch`), existing workflows, branch
protection / rulesets, environments, and Dependabot config.

Gate: a written coverage matrix naming present gates, gaps, and in-scope gates.

### Phase 1 — Plan

Map each gap to the provider table. Include k6/ZAP **only** when a running app
and a load script / target URL exist — otherwise mark them documented-not-wired.
Confirm public-repo free tier vs the private licensing note. Produce the wiring
list (which reusables, which inputs, which predicate types).

Gate: an agreed gate list with predicate-type assignments (see
`references/gate-catalog.md`).

### Phase 2 — Implement (repo level)

Wire the target as a thin caller of the central reusables, **pinned by the full
40-char commit SHA** of this central repo. Required elements:

1. A `quality-gates.yml` caller (model: `templates/quality-gates-caller.yml`)
   that fans out the in-scope gates on `push` / `pull_request`.
2. **The seam**: for every gate whose verdict must gate *deployment* (not just
   merge), upload the evidence file as an artifact and call
   `reusable-attest-scan.yml` with the gate's predicate type so it becomes a
   signed, digest-bound attestation.
3. `dependabot.yml` (github-actions ecosystem) so the new pins stay fresh.
4. SECURITY.md "Verifying Quality-Gate Attestations" (from
   `references/verification.md`).
5. Migrate every `uses:` to full 40-char SHAs; add the central `pin-check.yml`
   as a CI job (later a required check).

Gate: `actionlint` clean; PR opens; pipeline green including `pin-check`.

### Phase 3 — Enforce & provision (the safety contract)

Apply the templated repo configuration per `references/repo-config.md`. The
hard split:

- **Deploy automatically (idempotent, non-secret, reversible)** — but only
  after a **diff-against-current preview + explicit confirm**: the ruleset
  (`templates/ruleset.json`: required status checks for the in-scope gates +
  `pin-check / pin-check`, required reviews + CODEOWNERS, dismiss-stale, signed
  commits, linear history, block force-push); repo settings (auto-merge,
  delete-branch-on-merge); native free-tier scanners (code-scanning default
  setup, secret scanning, push protection); `dependabot.yml` and `CODEOWNERS`
  (committed via PR); deploy environments + wait timer + branch policy.
  Compose with the `gpm` skills (`gpm-branch-protection`, `gpm-repo-settings`,
  `gpm-labels`) — call them, do not reinvent.
- **Guide only — never written, never logged**: secrets and variables. Emit the
  required **names** and the exact `gh secret set NAME` / `gh variable set NAME`
  command for the user to run; never read, write, commit, or print a secret
  value. Most gates need **no secrets** (keyless signing + OSS scanners);
  `GITLEAKS_LICENSE` and deploy credentials are the only common optionals.
  Environment required-reviewers (human identities) are a manual step.

Deploy-time: `reusable-verify-gates.yml` in the deploy job's `needs:` —
fail-closed `gh attestation verify` before anything ships.

Gate: config applied idempotently (re-run = no-op); transcript shows only secret
*names* and user-run commands, never values.

### Phase 4 — Verify end-to-end

1. `actionlint` clean; `pin-check` zero unpinned `uses:`.
2. Dispatch the caller (or open the first PR). The chain runs SAST → SCA →
   posture → container/IaC/license → SBOM → seam-attest → verify; SARIF lands in
   the Security tab; `reusable-attest-scan.yml` produces a signed attestation.
3. Run every command in `references/verification.md` **independently** from a
   workstation against the produced attestation — in-pipeline success is not the
   acceptance test.

## Hard rules

1. **Pin every third-party action by full 40-char SHA.** The Trivy
   `trivy-action` compromise (CVE-2026-33634, March 2026 — 76 of 77 tags
   force-pushed to malware) is the standing cautionary case. Tags are unsafe.
2. `gh attestation verify` under SLSA L3: `--owner` alone is insufficient —
   the SAN is the central signer; always add `--signer-workflow`.
   `--cert-identity-regexp` / `--cert-oidc-issuer` are cosign flags; `gh`
   rejects them.
3. **Least privilege.** `id-token: write` + `attestations: write` only on jobs
   that sign; `security-events: write` only on jobs that upload SARIF.
4. **Never read, write, commit, or log a secret value.** Emit names + the
   user-run command only.
5. A signed attestation proves a gate *ran and recorded a verdict*, not that it
   *passed* — the policy reads the verdict.
6. Default branch from the API, never local `origin/HEAD`.

## References

- `references/help.md` — end-user help / usage (present on `--help`; honest invocation framing)
- `references/gate-catalog.md` — the 12 gates: tool, reusable, pinned action, evidence, predicate-type URI, merge vs deploy, free-for-OSS
- `references/assessment.md` — coverage-assessment `gh` queries + the matrix template
- `references/attestation-seam.md` — `actions/attest` custom-predicate mechanics; per-gate predicate URIs; compose-with-attested-delivery
- `references/enforcement.md` — SARIF hub → required checks → rulesets → environments → fail-closed verify; the k8s-admission boundary
- `references/verification.md` — the exact `gh attestation verify` command set per predicate
- `references/repo-config.md` — the deploy-vs-guide safety contract for repo configuration
- `references/limitations.md` — honest limits: licensing line, no k8s admission, no perf predicate, ZAP SARIF caveat, action supply-chain risk, "signed ≠ passed"
