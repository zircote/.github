# Honest limitations

From `GITHUB-NATIVE-ATTESTED-QUALITY-GATES.md` §9, plus this skill's scope.

- **CodeQL, secret scanning, and dependency review are free only on public
  repos.** On private/internal repos they require licenses — GitHub Code
  Security ($30/active committer/month: code scanning, premium Dependabot,
  dependency review) and GitHub Secret Protection ($19/active committer/month:
  secret scanning + push protection). The OSS Actions (Trivy, OSV-Scanner, ZAP,
  Scorecard, Syft, vexctl, k6) close the gap *functionally* at only Actions-
  compute cost, but Trivy is not a like-for-like CodeQL replacement (CodeQL's
  dataflow depth is distinctive). **This skill targets the public-repo free
  path.**

- **GitHub provides no Kubernetes admission control.** It gates merges and
  deployment jobs, not workload admission. The runtime verify-at-admission gate
  is external (Kyverno / Sigstore policy-controller) and out of scope.

- **No standard performance predicate.** k6 results ride a custom predicate
  (`https://zircote.github.io/attestations/k6-load/v1`); SARIF and JUnit are
  evidence formats, not predicate types.

- **ZAP SARIF is an engine report, not a native action input.** Emit it via the
  Automation Framework / `cmd-options` and upload as a separate step; the action
  attaches an HTML/JSON report artifact by default.

- **Third-party action supply-chain risk is real.** The Trivy `trivy-action`
  compromise (CVE-2026-33634, March 2026 — 76 of 77 version tags force-pushed to
  credential-stealing malware) is the cautionary case. Pin every third-party
  action to a full 40-char commit SHA; run Scorecard's `Pinned-Dependencies` and
  `Dangerous-Workflow` checks over your own workflows; `pin-check.yml` enforces
  it in CI.

- **Private-repo artifact attestations** route to GitHub's Sigstore instance
  (Enterprise Cloud) rather than the public-good transparency log; verify
  against the appropriate trusted root.

- **A signed attestation proves a gate ran and recorded a verdict, not that it
  passed.** The verifying policy must inspect the verdict field, and signer
  identity must be pinned first (`--signer-workflow`).

- **k6 and ZAP need a running target.** They are opt-in; wire them only when a
  load script / deployed preview exists.
