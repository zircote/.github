# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |

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
DIGEST=$(gh api 'users/zircote/packages/container/<name>/versions?per_page=20' \
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
