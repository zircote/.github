---
diataxis_type: tutorial
diataxis_learning_goals:
  - build and push a container image whose digest is signed and attested by the centralized workflow
  - verify SLSA provenance, signature, and SBOM for a digest from your own machine
---

# Tutorial: Your First Attested Release

In this tutorial, we will build a tiny container image in a sandbox repo, have
the centralized `build-attest.yml` workflow sign and attest it, and then
verify the proof ourselves from the command line. By the end you will have
produced a digest that carries SLSA provenance, a keyless signature, an SBOM,
and a vulnerability report — and confirmed all of it independently.

## What you'll learn

- How an application repo hands its build to the centralized attestation
  authority with one `uses:` call.
- What "attested" actually looks like: the verification commands and their
  output.

## Prerequisites

- Permission to create a repo under `zircote` (or your own account — the
  central workflows are public and callable from anywhere; substitute your
  owner in the commands below).
- [`gh`](https://cli.github.com/) (authenticated) and
  [`cosign`](https://docs.sigstore.dev/cosign/system_config/installation/) installed locally.

## Steps

### Step 1: Create a sandbox repo

```sh
gh repo create zircote/attested-hello --private --clone
cd attested-hello
```

### Step 2: Add a minimal Dockerfile

```sh
cat > Dockerfile <<'EOF'
FROM alpine:3.21
CMD ["echo", "hello, attested world"]
EOF
```

### Step 3: Resolve the central workflow SHA

Callers pin the centralized workflow by full commit SHA. Resolve the latest
commit that touched `build-attest.yml` on `main` (the default branch of
`zircote/.github`):

```sh
gh api 'repos/zircote/.github/commits?path=.github/workflows/build-attest.yml&per_page=1' \
  --jq '.[0].sha'
```

The output is a 40-character SHA. Copy it — we use it in the next step.
`uses: ...@<SHA>` accepts any commit SHA in the repo, so the pin keeps
working even after the branch moves on.

### Step 4: Add the release workflow

Create `.github/workflows/release.yml`, replacing `<SHA>` with the SHA from
Step 3:

```yaml
name: release
on:
  push:
    branches: [main]

jobs:
  build-attest:
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    uses: zircote/.github/.github/workflows/build-attest.yml@<SHA>
    with:
      image-name: ghcr.io/zircote/attested-hello
```

### Step 5: Push and watch the run

```sh
git add -A && git commit -m "First attested release" && git push
gh run watch
```

You will notice two jobs: `build` (runs in *your* repo's context) and
`attest` (runs inside the centralized workflow you cannot modify — that
separation is the SLSA L3 isolation boundary). The run ends with
`Verify SLSA L3 provenance` succeeding: the workflow self-verifies before
finishing.

### Step 6: Capture the digest

The pushed image's digest is the package version name in GHCR. `zircote` is a
user account, so the package API lives under `users/` (for an organization,
substitute `orgs/<org>/`):

```sh
DIGEST=$(gh api "users/zircote/packages/container/attested-hello/versions" \
  --jq '.[0].name')
echo "$DIGEST"
```

The output should look like `sha256:2d0586...` — that digest, not any tag, is
the release candidate.

### Step 7: Verify the SLSA provenance yourself

```sh
gh attestation verify "oci://ghcr.io/zircote/attested-hello@${DIGEST}" \
  --repo zircote/attested-hello \
  --signer-workflow zircote/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1
```

The output ends with `✓ Verification succeeded!` and names the workflow that
built it. Both flags are required: `--repo` asserts where the build ran, and
`--signer-workflow` asserts the certificate identity — under SLSA L3 the
certificate names the *central signer*, so `--repo` alone fails by design.

### Step 8: Verify the signature and SBOM

```sh
cosign verify "ghcr.io/zircote/attested-hello@${DIGEST}" \
  --certificate-identity-regexp \
    '^https://github.com/zircote/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

cosign verify-attestation "ghcr.io/zircote/attested-hello@${DIGEST}" \
  --type cyclonedx \
  --certificate-identity-regexp \
    '^https://github.com/zircote/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

Both commands print the verified claims. Note the certificate identity in the
output: it is the *centralized* signing workflow, not your repo — no workflow
you control could have produced an acceptable signature.

## What you've accomplished

You built an image whose digest carries machine-verifiable proof of how it was
built and what is inside it, and you checked that proof from your own machine
using only public verification tooling. Everything downstream — promotion,
admission, the production change gate — is built on the verification you just
performed by hand.

Clean up when done: `gh repo delete zircote/attested-hello`.

## Next steps

- [Onboard a real repo to attested delivery](../how-to/onboard-a-repo-to-attested-delivery.md) —
  gate releases on verification, and add promotion when you have a deploy target.
- [Why attested delivery](../explanation/attested-delivery.md) — the
  reasoning behind what you just did.
