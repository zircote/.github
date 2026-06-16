---
diataxis_type: tutorial
diataxis_learning_goals:
  - run a CodeQL SAST gate on a repo and turn its verdict into a signed, digest-bound attestation
  - verify a gate attestation and read its verdict from your own machine
---

# Tutorial: Wire Your First Attested Quality Gate

In this tutorial, we will take a small public repo, run the centralized CodeQL
SAST gate on it, and have the attestation **seam** turn that gate's verdict into
a signed claim bound to a source bundle by digest. Then we will verify the claim
ourselves and read its verdict from the command line. By the end you will have
produced a signed `sast/v1` attestation and confirmed it independently — the same
move every deploy gate makes.

## What you'll learn

- How a repo runs a gate and binds its verdict to a subject through one
  `reusable-attest-scan.yml` call.
- What "attested gate" actually looks like: the verify command, the signer pin,
  and reading the verdict (signed ≠ passed).

## Prerequisites

- A **public** repo under your account (CodeQL is free only on public repos —
  substitute your owner for `<owner>` below; the central workflows are public and
  callable from anywhere).
- [`gh`](https://cli.github.com/) authenticated.

## Steps

### Step 1: Create a public sandbox repo with a little code

CodeQL needs source to analyze. We give it one tiny JavaScript file.

```sh
gh repo create <owner>/attested-gate-hello --public --clone
cd attested-gate-hello
cat > app.js <<'EOF'
function greet(name) {
  return "hello, " + name;
}
module.exports = { greet };
EOF
git add app.js && git commit -m "Add app"
```

### Step 2: Resolve the central workflow SHAs

Callers pin centralized workflows by full commit SHA. Resolve the current HEAD of
`zircote/.github` (one SHA pins every central workflow used below):

```sh
SHA=$(gh api repos/zircote/.github/commits/main --jq .sha)
echo "$SHA"
```

The output is a 40-character SHA. We use it in the next step.

### Step 3: Add the quality-gates workflow

Create `.github/workflows/quality-gates.yml`, replacing each `<SHA>` with the SHA
from Step 2 and `<owner>` with your account. Three jobs: build a subject the
verdict will bind to, run the SAST gate, then sign the gate's verdict.

```yaml
name: quality-gates
on:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  bundle:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      digest: ${{ steps.b.outputs.digest }}
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - id: b
        run: |
          git archive --format=tar.gz -o app.tar.gz HEAD
          echo "digest=sha256:$(sha256sum app.tar.gz | cut -d' ' -f1)" >> "$GITHUB_OUTPUT"
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: app-bundle
          path: app.tar.gz
          if-no-files-found: error

  sast:
    permissions:
      security-events: write
      contents: read
      actions: read
    uses: zircote/.github/.github/workflows/reusable-sast-codeql.yml@<SHA>
    with:
      languages: javascript-typescript

  attest-sast:
    needs: [bundle, sast]
    permissions:
      id-token: write
      attestations: write
      contents: read
    uses: zircote/.github/.github/workflows/reusable-attest-scan.yml@<SHA>
    with:
      subject-name: attested-gate-hello
      subject-digest: ${{ needs.bundle.outputs.digest }}
      predicate-type: https://zircote.github.io/attestations/sast/v1
      predicate-artifact: ${{ needs.sast.outputs.sarif-artifact }}
      predicate-filename: ${{ needs.sast.outputs.sarif-filename }}
```

The `sast` job emits its SARIF as the `sast-sarif` artifact (`results.sarif`);
`attest-sast` feeds exactly that into the seam, bound to the bundle's digest.

### Step 4: Push and watch the run

```sh
git add .github/workflows/quality-gates.yml
git commit -m "Wire attested SAST gate"
git push
gh run watch
```

You will notice three jobs. `sast` runs CodeQL and uploads SARIF to the Security
tab; `attest-sast` runs inside the centralized seam you cannot modify — that is
the signer-isolation boundary — and ends by persisting a signed attestation. The
run succeeds: a clean `app.js` produces zero findings.

### Step 5: Download the subject and verify the attestation

The attestation is bound to the bundle's digest, so we fetch the bundle and let
`gh` recompute and match it:

```sh
RUN=$(gh run list --workflow quality-gates.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run download "$RUN" --name app-bundle

gh attestation verify app.tar.gz --owner <owner> \
  --signer-workflow zircote/.github/.github/workflows/reusable-attest-scan.yml \
  --predicate-type https://zircote.github.io/attestations/sast/v1
```

The output ends with `✓ Verification succeeded!` and names the signing workflow.
`--signer-workflow` is required: under SLSA L3 the certificate identity is the
central seam, so `--owner` alone fails by design. Note the signer in the output —
it is `reusable-attest-scan.yml`, not any workflow in *your* repo.

### Step 6: Read the verdict (signed ≠ passed)

A successful verify proves the attestation is authentic and bound to your
bundle — **not** that the gate passed. Apply the `sast/v1` verdict rule to the
signed SARIF body:

```sh
gh attestation verify app.tar.gz --owner <owner> \
  --signer-workflow zircote/.github/.github/workflows/reusable-attest-scan.yml \
  --predicate-type https://zircote.github.io/attestations/sast/v1 \
  --format json \
  | jq '[.[0].verificationResult.statement.predicate.runs[].results[]?
         | select(.level=="error")] | length'
```

The output is `0` — zero error-level results, so the gate passed. Edit `app.js`
to introduce a flagged pattern, push, and re-run this command to watch the count
rise: the *signature* still verifies, but the *verdict* changes. That separation
is the whole point.

## What you've accomplished

You ran a real SAST gate, turned its verdict into a signed `sast/v1` attestation
bound to a digest, verified it from your own machine against the pinned central
signer, and read the verdict out of the signed evidence. Every deploy-time gate —
`reusable-verify-gates.yml`, an external admission policy — is built on the
verification you just did by hand.

Clean up when done: `gh repo delete <owner>/attested-gate-hello`.

## Next steps

- [Onboard a repo to attested quality gates](../how-to/onboard-a-repo-to-attested-quality-gates.md)
  — wire the full 12-gate suite and make the gates merge/deploy requirements.
- [Why attested quality gates](../explanation/attested-quality-gates.md) — the
  reasoning behind what you just did.
- [Quality-gate workflows reference](../reference/quality-gate-workflows.md) —
  the other gates and their predicate types.
