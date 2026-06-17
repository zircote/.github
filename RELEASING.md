# Releasing zircote/.github

This repo ships an **attested** release process: each release is a deterministic
source bundle carrying a SLSA build-provenance attestation signed by the
`release.yml` workflow's OIDC identity, plus a GitHub Release with
auto-generated notes. It dogfoods the same attested-delivery doctrine this repo
provides to consumers.

> Consumers continue to pin reusable workflows and actions by full 40-char
> commit SHA (Dependabot keeps them fresh). Tags and Releases add a
> human-readable changelog and a verifiable artifact per version — they do not
> change the SHA-pinning rule.

## Cut a release

Releases are **tag-driven**. From an up-to-date `main`:

```bash
git tag v1.2.0           # semver: vMAJOR.MINOR.PATCH (or vX.Y.Z-rc.1 for a prerelease)
git push origin v1.2.0
```

The `release` workflow then:

1. Validates the tag is semver (fails closed otherwise).
2. Builds `zircote-github-<version>.tar.gz` with `git archive` (reproducible).
3. Attests three predicates to the bundle digest:
   - **SLSA build provenance** (`https://slsa.dev/provenance/v1`) — how it was built;
   - **CycloneDX SBOM** (`https://cyclonedx.org/bom`) — the package's declared
     dependencies (Syft over the source);
   - **Vulnerability report** (`https://in-toto.io/attestation/vulns/v0.1`) — a
     Grype scan of the source (evidence, not a gate — read the verdict).
4. Creates the GitHub Release with auto-generated notes and attaches the bundle,
   its `.sha256`, `sbom.cdx.json`, and `grype.json`.
5. Re-verifies all three attestations fail-closed before finishing.

To re-run against an existing tag, dispatch the workflow manually
(**Actions → release → Run workflow**) and supply the tag. A re-dispatch is
idempotent: if a Release already exists for the tag it refreshes the attached
assets (bundle + `.sha256`) rather than failing; the auto-generated notes from
the original run are kept.

Version bump convention (Conventional Commits): `fix:` → patch, `feat:` → minor,
`feat!:` / `BREAKING CHANGE:` → major.

## Verify a release artifact

Download the `.tar.gz` from the release, then — independently from a
workstation:

```bash
BUNDLE=zircote-github-<version>.tar.gz
SIGNER=zircote/.github/.github/workflows/release.yml

# Provenance — how it was built (omit --predicate-type to verify all three)
gh attestation verify "$BUNDLE" --repo zircote/.github --signer-workflow "$SIGNER" \
  --predicate-type https://slsa.dev/provenance/v1

# SBOM — the package's declared dependencies
gh attestation verify "$BUNDLE" --repo zircote/.github --signer-workflow "$SIGNER" \
  --predicate-type https://cyclonedx.org/bom

# Vulnerability report — read the verdict, don't just trust the signature
gh attestation verify "$BUNDLE" --repo zircote/.github --signer-workflow "$SIGNER" \
  --predicate-type https://in-toto.io/attestation/vulns/v0.1
```

`--signer-workflow` is required: under SLSA L3 the Fulcio SAN is the signing
workflow, not the source repo. A successful verify proves the bundle is
authentic and bound to that predicate — **not** that the vuln scan was clean;
inspect the predicate body (`--format json | jq`) to read the verdict. These
predicates describe the **package** (its provenance, dependencies, and
vulnerabilities), which is why they apply to a source release, not only to a
container image.
