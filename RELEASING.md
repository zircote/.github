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
3. Attests SLSA build provenance over the bundle (`actions/attest-build-provenance`).
4. Creates the GitHub Release with auto-generated notes and attaches the bundle
   plus its `.sha256`.
5. Re-verifies the attestation fail-closed before finishing.

To re-run against an existing tag, dispatch the workflow manually
(**Actions → release → Run workflow**) and supply the tag.

Version bump convention (Conventional Commits): `fix:` → patch, `feat:` → minor,
`feat!:` / `BREAKING CHANGE:` → major.

## Verify a release artifact

Download the `.tar.gz` from the release, then — independently from a
workstation:

```bash
gh attestation verify zircote-github-<version>.tar.gz \
  --repo zircote/.github \
  --signer-workflow zircote/.github/.github/workflows/release.yml
```

`--signer-workflow` is required: under SLSA L3 the Fulcio SAN is the signing
workflow. Inspect the provenance predicate with `--format json | jq` to confirm
the source commit and build inputs. A successful verify proves the bundle is
authentic and unmodified since it was built from the tag.
