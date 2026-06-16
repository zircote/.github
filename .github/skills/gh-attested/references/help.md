# gh-attested — help text

When the user asks how to use this skill, or passes `--help`, `-h`, or a bare
`help`, print the block below **verbatim** (inside a fenced block), then stop —
make no changes and run no phase.

`gh-attested` is a Claude skill, not a shell command: you invoke it by
**describing your intent** ("assess quality gates for zircote/widget"). It is
not a literal flag parser — the tokens shown below (`assess`, `--dry-run`, …)
are recognized as scoping intent whether typed as flags or plain English.

```
GH-ATTESTED                       zircote skills                      gh-attested

NAME
    gh-attested — assess, wire, enforce, and verify attested quality gates
                  for a public open-source repository

INVOCATION
    Describe your intent in natural language; the skill recognizes the scoping
    tokens below. Equivalent forms:
        "assess quality gates for zircote/widget"   ==   gh-attested zircote/widget assess

    gh-attested [owner/repo] [assess | plan | implement | enforce | verify]
                [--dry-run] [--include=k6,zap] [--help]

DESCRIPTION
    Brings a public repo to complete quality-gate coverage using only
    GitHub-native and free-for-OSS tooling, and turns each gate's verdict into
    a signed, digest-bound attestation. The target is wired as a thin caller of
    this org's central reusable workflows — every `uses:` pinned to a full
    40-char commit SHA, every deploy-gating verdict fail-closed verified.

    The work runs as a five-phase pipeline. Each phase ends at a gate that must
    pass before the next begins; the skill pauses for confirmation before any
    write or config change.

      PHASE        WRITES?            PRODUCES
      0 assess     read-only          12-gate coverage matrix + gap list
      1 plan       read-only          gap -> reusable -> inputs -> predicate type
      2 implement  PR only            quality-gates.yml caller, dependabot.yml,
                                      SECURITY.md verify section, pin-check job
      3 enforce    config (confirm)   rulesets, required checks, native scanners,
                                      environments  (secret NAMES only)
      4 verify     read-only          independent `gh attestation verify` runs

    The 12 gates and their providers: SAST (CodeQL), SCA (OSV-Scanner +
    dependency review + Dependabot), secret detection (native + gitleaks),
    container/IaC/license (Trivy), SBOM, vuln disposition (OpenVEX), build
    provenance (attested-delivery), supply-chain posture (Scorecard), peer
    review (rulesets/CODEOWNERS), load (k6, opt-in), DAST (ZAP, opt-in), and the
    attestation seam that signs each verdict.

ARGUMENTS
    owner/repo
        Repository to operate on. Defaults to the current repo
        (`gh repo view --json nameWithOwner -q .nameWithOwner`). Never guessed —
        if it cannot be resolved, the skill asks.

    phase
        Stop after the named phase. Omit to run the whole pipeline, gated.
          assess     Phase 0 only. Safe, read-only "where do I stand?".
          plan       Phases 0-1. Read-only; ends with the wiring list.
          implement  Phases 0-2. Opens a PR; never commits to a default branch.
          enforce    Phase 3. Applies repo config behind diff-preview + confirm.
          verify     Phase 4. Re-verifies existing attestations from a shell.

OPTIONS
    --dry-run
        Render every artifact and every `gh`/`git` command, but write no files,
        open no PR, and apply no configuration. Turns implement/enforce into a
        preview you can read before committing to anything.

    --include=LIST
        Opt in to gates that require a running target (comma-separated:
        k6, zap). Ignored unless a load script (k6) or target URL (ZAP) exists;
        otherwise those gates stay documented-not-wired.

    --help, -h
        Show this help and stop.

GUARANTEES (the safety contract)
    * Phases 0, 1, and verify never write.
    * Every config mutation is shown as a command and diffed against current
      state before apply; re-running the skill is a no-op (idempotent).
    * Nothing is force-applied. Tightening protection on an active branch
      requires an explicit confirm.
    * Secrets and credentials are never read, written, committed, or logged.
      The skill emits only the secret NAME and the `gh secret set NAME` command
      for you to run yourself.
    * Third-party actions are pinned by full 40-char commit SHA, never a tag
      (the trivy-action CVE-2026-33634 force-push compromise is the standing
      reason).

HONEST LIMITS (read before relying on a gate)
    * CodeQL, secret scanning, and dependency review are free only on PUBLIC
      repos. Private repos need GitHub Advanced Security — see
      references/limitations.md for the licensed path.
    * A signed attestation proves a gate RAN and RECORDED a verdict, not that it
      PASSED. The gating policy must read the verdict field.
    * GitHub has no Kubernetes admission control. Enforce image/attestation
      policy at the cluster with Kyverno or sigstore policy-controller.
    * There is no standard performance predicate; k6 uses this org's custom one.
    * ZAP SARIF is an Automation-Framework report, not a native action output.

PREREQUISITES
    * `gh` authenticated (`gh auth status`) with repo scope on the target.
    * Target repo PUBLIC for the free-for-OSS tier (else see HONEST LIMITS).
    * Phase 3 (enforce) needs admin permission on the repo.
    * `verify` needs a recent `gh` with the built-in `gh attestation` command.

EXAMPLES
    gh-attested zircote/widget assess
        Read-only. Print the 12-gate coverage matrix and the gaps. Changes
        nothing — the right first call on any repo.

    gh-attested zircote/widget
        Run the full pipeline against zircote/widget, pausing for confirmation
        at every phase gate.

    gh-attested zircote/widget implement --dry-run
        Show the caller workflow, the SHA pins, and the PR body that WOULD be
        created. Writes nothing.

    gh-attested zircote/api implement --include=zap
        Wire the merge-time gates AND the ZAP DAST gate (a target URL must
        already be configured).

    gh-attested verify
        From a workstation, independently verify the current repo's gate
        attestations with the pinned `--signer-workflow`.

SEE ALSO
    references/gate-catalog.md     the 12 gates: tool, reusable, predicate type
    references/assessment.md       Phase 0 queries + coverage-matrix template
    references/verification.md     the exact `gh attestation verify` commands
    references/repo-config.md      Phase 3 deploy-vs-guide safety contract
    references/limitations.md      the licensing line and other honest limits
    skill: attested-delivery       the container release / build-provenance backbone

GH-ATTESTED                       zircote skills                      gh-attested
```
