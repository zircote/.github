# Verification — the complete command set

Run these **from a workstation**, not just in-pipeline: in-pipeline success
is necessary but the acceptance test is independent verification.
Prerequisites: `gh` CLI authenticated with read access; `cosign`
installed; for non-public images, a registry login:

```sh
gh auth token | docker login ghcr.io -u <username> --password-stdin
```

## 0. Resolve the digest for a tag

```sh
DIGEST=$(gh api 'orgs/<org>/packages/container/<name>/versions?per_page=100' \
  --jq '[.[] | select((.metadata.container.tags // []) | index("<tag>"))][0].name')
```

For a personal (user) account, the packages endpoints use
`users/<owner>/...` instead of `orgs/<org>/...`. Use `per_page=100` —
20 misses older tags and returns `null`, which reads as a false failure.

## 1. SLSA provenance (AT-05)

`--repo` asserts where the build ran; `--signer-workflow` asserts the SAN
(the central signer). Both are required — `--repo` alone fails under L3.

```sh
gh attestation verify "oci://ghcr.io/<org>/<repo>@${DIGEST}" \
  --repo <org>/<repo> \
  --signer-workflow <org>/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1
```

## 2. Keyless signature (AT-06a)

```sh
cosign verify "ghcr.io/<org>/<repo>@${DIGEST}" \
  --certificate-identity-regexp '^https://github.com/<org>/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## 3. SBOM attestation (AT-06b) — and the vuln report

```sh
cosign verify-attestation "ghcr.io/<org>/<repo>@${DIGEST}" \
  --type cyclonedx \
  --certificate-identity-regexp '^https://github.com/<org>/\.github/\.github/workflows/sign-and-attest\.yml@.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
# vulnerability report: same command with --type "https://in-toto.io/attestation/vulns/v0.1"
# (NOT --type vuln — that alias maps to cosign's own predicate URI and will not match)
```

## 4. Binaries and bundles

```sh
gh release download <tag> --repo <org>/<repo>
gh attestation verify <binary> --repo <org>/<repo>                  # provenance
gh attestation verify <binary> --repo <org>/<repo> \
  --predicate-type https://cyclonedx.org/bom                        # SBOM binding
shasum -a 256 -c <bin>-<version>-checksums.txt
```
(No `--signer-workflow` for artifacts attested by the repo's own workflow.)

## 5. Published crates

```sh
# static.crates.io rejects UA-less requests — always set -A
curl -fsSL -A 'release-check' \
  -O https://static.crates.io/crates/<name>/<name>-<version>.crate
gh attestation verify <name>-<version>.crate --repo <org>/<repo>
```

Check **exit codes**, not grepped output — a filtered pipe that matches
nothing looks identical to success. Silence is not success.

## Expected outcomes

- Success: `gh` prints `✓ Verification succeeded!`; cosign prints
  `Verification for … The cosign claims were validated` plus transparency
  log confirmation.
- The set MUST fail closed when: the digest's bytes differ (any
  re-build/tamper), the source repo differs (`--repo` mismatch via the
  source-repository extension), or the signer is anything but the central
  workflow (SAN mismatch). Spot-check the negative path at least once,
  e.g. verify some unrelated public digest with the same flags and confirm
  it fails.

## Inspecting a certificate when verification surprises you

```sh
gh api repos/<org>/<repo>/attestations/${DIGEST} \
  --jq '.attestations[0].bundle.verificationMaterial.certificate.rawBytes' \
  | base64 -d | openssl x509 -inform DER -noout -text \
  | grep -A1 -E '1.3.6.1.4.1.57264.1.(5|6|12)|Subject Alternative'
# SAN = signer workflow @ pin; .12 = source repository; .6 = source ref
```
