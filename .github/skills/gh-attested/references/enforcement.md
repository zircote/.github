# Enforcement — merge-time and deploy-time, all GitHub-native

## Merge-time: required status checks + rulesets

Every SARIF-emitting gate lands in the code-scanning hub; the **code scanning
results** check fails a PR on any error/critical/high finding. Make gates merge
blockers by adding their checks to **required status checks** in a ruleset (or
branch protection). The context name for a reusable-workflow job is
`<caller job id> / <called job name>` — e.g. a caller job `sast:` calling
`reusable-sast-codeql.yml` (job `analyze`) surfaces as `sast / analyze`.

Recommended required checks for a wired repo:

- `Code scanning results / CodeQL` (and the third-party SARIF categories)
- `sca / dependency-review`
- `trivy / iac-license` (and `trivy / image` when an image is built)
- `pin-check / pin-check`
- the repo's own build/test checks

Ruleset also enforces: required PR reviews + review from CODEOWNERS, dismiss
stale approvals, **require signed commits** (satisfiable keyless via Gitsign),
linear history, block force-push. Template: `templates/ruleset.json`.

## Deploy-time: environments + fail-closed verify

Deployment **Environments** add required reviewers, a wait timer, and
deployment-branch policies; a job referencing an environment must clear them
before it runs or reads the environment's secrets.

The cryptographic gate slots into the same deploy job: `reusable-verify-gates.yml`
runs `gh attestation verify` for each required predicate and exits non-zero on
any failure. **It verifies one signer per invocation** — pin `signer-workflow`
to the workflow that actually produced those predicates (the "Signed by" column
in `docs/reference/attestation-predicates/`). The seam
(`reusable-attest-scan.yml`) signs the SARIF gates; OpenVEX self-signs in
`reusable-vex.yml`; k6 in `reusable-k6.yml`. Mixing predicates from different
signers into one call fails closed on a *valid* artifact, so call it once per
signer group and have the deploy job `needs:` them all:

```yaml
verify-seam:
  permissions:
    contents: read
    attestations: read
    packages: read
  uses: zircote/.github/.github/workflows/reusable-verify-gates.yml@<sha>
  with:
    subject-ref: oci://ghcr.io/zircote/app@${{ needs.build.outputs.digest }}
    owner: zircote
    signer-workflow: zircote/.github/.github/workflows/reusable-attest-scan.yml
    predicate-types: |-
      https://zircote.github.io/attestations/sast/v1
      https://zircote.github.io/attestations/sca/v1
verify-vex:
  permissions:
    contents: read
    attestations: read
    packages: read
  uses: zircote/.github/.github/workflows/reusable-verify-gates.yml@<sha>
  with:
    subject-ref: oci://ghcr.io/zircote/app@${{ needs.build.outputs.digest }}
    owner: zircote
    signer-workflow: zircote/.github/.github/workflows/reusable-vex.yml
    predicate-types: https://openvex.dev/ns/v0.2.0
deploy:
  needs: [verify-seam, verify-vex]
  environment: production
  ...
```

## The honest boundary — no Kubernetes admission control

GitHub gates **merges** and **deployment jobs**; it does **not** validate or
reject workloads as they admit to a cluster. If you need the runtime gate —
verify the same attestations at the cluster boundary — that piece (Sigstore
policy-controller or Kyverno) is **external** to GitHub. The OSS tools are free,
but they are not GitHub features and are out of scope for this skill. Design
references for admission live in the central repo's
`docs/how-to/enforce-admission-of-attested-images.md` (attested-delivery).
