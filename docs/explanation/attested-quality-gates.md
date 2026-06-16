---
diataxis_type: explanation
diataxis_topic: why each CI quality gate's verdict becomes a signed, digest-bound attestation
---

# Why Attested Quality Gates

Attested delivery proves *how* an artifact was built and *what* is inside it.
Attested quality **gates** add the orthogonal claim: that the repository's CI
checks — SAST, SCA, secret detection, container/IaC/license scanning, SBOM,
vulnerability disposition, supply-chain posture, peer review, and (optionally)
load and DAST — actually **ran and recorded a verdict**, and that the verdict is
the same one a deployment decision later trusts. This document explains the
design: why a clean Security tab is not enough, why the verdict is signed as an
attestation, why the signer identity is pinned, and the honest limits of the
claim. It builds on [Why attested delivery](attested-delivery.md) and the
[`gh-attested` skill](../../.github/skills/gh-attested/SKILL.md), which automates
the assess → plan → implement path.

## The enforceable claim is the attestation, not the SARIF

Every gate produces evidence — almost always SARIF in the GitHub code-scanning
Security tab. That evidence is necessary but not *enforceable*: a Security tab is
a dashboard, queryable and mutable, not something a deploy pipeline can pin a
trust decision to. The enforceable claim is an **in-toto attestation** that binds
a typed predicate (the gate's evidence document) to a subject **by digest**,
signed by a workflow's OIDC identity. A deploy gate can then demand "this exact
digest carries a `sast` attestation signed by the expected workflow" and fail
closed if it does not. The Security tab informs humans; the attestation
constrains machines.

## Why the signer identity is pinned, not just the owner

The same SLSA Build L3 reasoning from attested delivery applies here. Gate
signing runs in a **central reusable workflow** the calling repo cannot modify —
[`reusable-attest-scan.yml`](../reference/quality-gate-workflows.md), "the seam,"
for the SARIF gates; `reusable-vex.yml` and `reusable-k6.yml` self-sign their own
predicates. Because the signer is a central workflow, the Fulcio certificate SAN
names that workflow, not the source repo. So a verifier must pin
`--signer-workflow`, not merely `--owner`:

```bash
gh attestation verify "$SUBJECT" --owner zircote \
  --signer-workflow zircote/.github/.github/workflows/reusable-attest-scan.yml \
  --predicate-type https://zircote.github.io/attestations/sast/v1
```

`--owner` alone passes for any attestation under the owner; pinning the signer is
what makes "a centralized gate signed this" non-forgeable by a repo that controls
its own workflows. One signer per predicate group — the seam for the SARIF gates,
`reusable-vex.yml` for OpenVEX, `reusable-k6.yml` for k6.

## Why custom predicate types

Most gates have no standard predicate type, so this org defines its own under the
`https://zircote.github.io/attestations/<gate>/v1` namespace — stable *type
identifiers*, not necessarily live URLs. Each type's body is the tool's native
evidence (CodeQL SARIF, OSV SARIF, Trivy SARIF, k6 summary JSON), and each
carries a **verdict rule** a verifier applies. Two gates reuse standard types
instead: vulnerability disposition uses OpenVEX (`https://openvex.dev/ns/v0.2.0`)
and build provenance uses SLSA (`https://slsa.dev/provenance/v1`). The canonical
definitions — URI, body format, verdict rule, JSON Schema — live in the
[attestation predicate reference](../reference/attestation-predicates/README.md).

## Signed is not passed

This is the load-bearing caveat, and it is deliberate. A successful
`gh attestation verify` proves the attestation is **authentic and bound to the
subject** — it does **not** prove the gate *passed*. The signed predicate is the
tool's evidence document; whether it represents a pass is determined by applying
the verdict rule to the body:

```bash
gh attestation verify "$SUBJECT" --owner zircote \
  --signer-workflow zircote/.github/.github/workflows/reusable-attest-scan.yml \
  --predicate-type https://zircote.github.io/attestations/sast/v1 \
  --format json \
  | jq '[.[0].verificationResult.statement.predicate.runs[].results[]?
         | select(.level=="error")] | length'   # 0 ⇒ pass
```

A gating policy that checks only the signature, not the verdict, is verifying the
wrong thing. Signing turns "a gate produced this evidence" into a portable,
tamper-evident fact; reading the verdict is still the policy's job.

## Why this targets public repositories

The GitHub-proprietary scanners — CodeQL, secret scanning, and dependency review
— are free **only on public repositories**. The attested-quality-gates path is
built for that free tier. Private repos need GitHub Advanced Security licenses
for those gates; the OSS scanners (OSV-Scanner, Trivy, Scorecard, gitleaks, k6,
ZAP) and keyless Sigstore signing remain free regardless. The boundary is a
licensing fact, not a design choice — it is documented in the skill's
`references/limitations.md`.

## Where enforcement actually happens

Two distinct decisions consume the gates:

- **Merge** — SARIF-emitting gates converge on the one code-scanning check;
  making it a required status check fails a PR on any `error`/high finding. Peer
  review, CODEOWNERS, and SHA-pinning are enforced by rulesets.
- **Deploy** — the signed attestations are verified fail-closed
  (`reusable-verify-gates.yml` in the deploy job's `needs:`) before anything
  ships. GitHub has **no Kubernetes admission control**; cluster-side enforcement
  is external (Kyverno / sigstore policy-controller), exactly as for
  [attested delivery](attested-delivery.md).

## Relationship to attested delivery

The two systems compose and do not overlap. Attested delivery owns build
provenance, the keyless signature, and SBOM signing on the image digest; attested
quality gates own the scanning/testing verdicts and the seam that signs them.
A fully covered repo runs both: `build-attest.yml` → `sign-and-attest.yml` for
the artifact, and the quality-gates caller → the seam for the gate verdicts.

## Further reading

- [Wire your first attested quality gate](../tutorials/first-attested-quality-gate.md)
  — see the loop hands-on.
- [How to onboard a repo to attested quality gates](../how-to/onboard-a-repo-to-attested-quality-gates.md)
  — the manual onboarding path.
- [Quality-gate workflows reference](../reference/quality-gate-workflows.md) —
  the workflows, key inputs, and predicate types.
- [Attestation predicate definitions](../reference/attestation-predicates/README.md)
  — each custom type's body, verdict rule, and schema.
