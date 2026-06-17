# Security Policy

## Supported Versions

The current **consumer-recommended release is `v0.2.0`**
(commit `67d8539d888070b1d00b9a59462c60dfad2f4fae`). When consuming this repo's
reusable workflows or composite actions, pin every `uses:` to that **full 40-char
commit SHA**, never the tag — per the repo's SHA-pinning rule; Dependabot's
`github-actions` ecosystem keeps the pin current.

```yaml
uses: zircote/.github/.github/workflows/<workflow>.yml@67d8539d888070b1d00b9a59462c60dfad2f4fae # v0.2.0
```

| Version | Supported |
|---------|-----------|
| `v0.2.0` (recommended) | Yes |
| `< v0.2.0` | Best-effort |

The `v0.2.0` source release is itself signed and attested — verify it before
relying on it (see [Verifying this repo's own release](#verifying-this-repos-own-source-release)).

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Please do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please send an email to the project maintainers at security@zircote.com with:

1. A description of the vulnerability
2. Steps to reproduce the issue
3. Potential impact assessment
4. Any suggested fixes (if applicable)

## Response Timeline

- **Acknowledgment**: Within 48 hours of receipt
- **Initial assessment**: Within 5 business days
- **Resolution target**: Within 30 days for confirmed vulnerabilities

## Disclosure Policy

We follow coordinated disclosure. We ask that you:

1. Allow us reasonable time to address the issue before public disclosure
2. Make a good-faith effort to avoid privacy violations, data loss, and service disruption
3. Do not exploit the vulnerability beyond what is necessary to demonstrate it

## Recognition

We appreciate the efforts of security researchers. Contributors who report valid vulnerabilities will be acknowledged (with permission) in our release notes.

## Verifying Release Artifacts

Repositories onboarded to the attested release architecture sign container images
through the centralized signer workflow in this repository
(`zircote/.github/.github/workflows/sign-and-attest.yml`). Each release digest
carries SLSA provenance, a keyless signature, a CycloneDX SBOM, and a
vulnerability report as OCI referrers. Verify from any workstation with `gh`
(authenticated) and `cosign`:

```sh
# 0. Resolve the digest for a tag
DIGEST=$(gh api 'users/zircote/packages/container/<name>/versions?per_page=100' \
  --jq '[.[] | select((.metadata.container.tags // []) | index("<tag>"))][0].name')

# 1. SLSA provenance — --repo asserts where the build ran,
#    --signer-workflow asserts the central signer (both required)
gh attestation verify "oci://ghcr.io/zircote/<repo>@${DIGEST}" \
  --repo zircote/<repo> \
  --signer-workflow zircote/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1

# 2. Keyless signature
cosign verify "ghcr.io/zircote/<repo>@${DIGEST}" \
  --certificate-identity-regexp '^https://github.com/zircote/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# 3. SBOM attestation (vuln report: same command with
#    --type "https://in-toto.io/attestation/vulns/v0.1")
cosign verify-attestation "ghcr.io/zircote/<repo>@${DIGEST}" \
  --type cyclonedx \
  --certificate-identity-regexp '^https://github.com/zircote/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# 4. Release binaries (attested by the repo's own workflow — no --signer-workflow)
gh release download <tag> --repo zircote/<repo>
gh attestation verify <binary> --repo zircote/<repo>
```

### Verifying this repo's own source release

The recommended `v0.2.0` release of **this** repository is a source bundle signed
by its own `release.yml`. It carries three predicates bound to the bundle digest:
SLSA provenance, a CycloneDX SBOM (the package's declared dependencies), and a
Grype vulnerability report. Verify from any workstation — pin `--signer-workflow`
to `release.yml` (not `sign-and-attest.yml`):

```sh
TAG=v0.2.0
SIGNER=zircote/.github/.github/workflows/release.yml
gh release download "$TAG" --repo zircote/.github

# the bundle matches its published digest
shasum -a 256 -c "zircote-github-${TAG#v}.tar.gz.sha256"   # -> OK

# verify all three predicates (omit --predicate-type to verify them together)
for pt in https://slsa.dev/provenance/v1 \
          https://cyclonedx.org/bom \
          https://in-toto.io/attestation/vulns/v0.1; do
  gh attestation verify "zircote-github-${TAG#v}.tar.gz" \
    --repo zircote/.github --signer-workflow "$SIGNER" --predicate-type "$pt"
done
```

A successful verify proves authenticity and digest binding — **not** that the
vuln scan was clean. Read the verdict from the predicate body
(`--format json | jq`) or the attached `grype.json` / `sbom.cdx.json`.

## Verifying Quality-Gate Attestations

Repositories wired to the attested **quality gates** (the `gh-attested` skill)
additionally record a signed, digest-bound attestation for each CI gate — SAST,
SCA, container/IaC/license scan, supply-chain posture, and vulnerability
disposition. Each predicate is pinned to **the workflow that actually signed
it** (SLSA L3 cert identity): the seam (`reusable-attest-scan.yml`) signs the
SARIF gates, while OpenVEX self-signs in `reusable-vex.yml` — so
`--signer-workflow` differs per predicate.

```sh
SUBJECT=oci://ghcr.io/zircote/<repo>@${DIGEST}   # or a release-artifact ref
SEAM=zircote/.github/.github/workflows/reusable-attest-scan.yml

# Seam-signed gate (SAST shown; other SARIF gates: swap the predicate-type)
gh attestation verify "$SUBJECT" --owner zircote --signer-workflow "$SEAM" \
  --predicate-type https://zircote.github.io/attestations/sast/v1

# Vulnerability disposition (OpenVEX — self-signed by reusable-vex.yml)
gh attestation verify "$SUBJECT" --owner zircote \
  --signer-workflow zircote/.github/.github/workflows/reusable-vex.yml \
  --predicate-type https://openvex.dev/ns/v0.2.0
```

A successful verification proves the attestation is authentic and bound to the
artifact — inspect the predicate body (`--format json | jq …`) to read the
gate's recorded verdict. The full per-predicate command set is in the
`gh-attested` skill's `references/verification.md`.
