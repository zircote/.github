# The attestation seam — turning any gate verdict into a signed claim

## The primitive

An in-toto Statement binds a typed `predicate` to a subject by content
`digest`; a DSSE envelope signs it so the claim is authenticated and
tamper-evident. GitHub Artifact Attestations make this keyless: a job declaring
`id-token: write` + `attestations: write` exchanges its OIDC identity for a
short-lived Sigstore certificate — no keys, no KMS. Public repos use the
Sigstore Public Good instance and write to a public transparency log.

Three actions cover the common predicates; one covers everything else:

- `actions/attest-build-provenance` → SLSA build provenance (deferred to
  `attested-delivery`).
- `actions/attest-sbom` → SPDX/CycloneDX SBOM (deferred to `attested-delivery`
  / `sbom-and-scan.yml`).
- `actions/attest` → **the seam**: any `predicate-type` URI + a `predicate-path`
  file, bound to `subject-digest`. This is what makes a scanner's SARIF/JSON a
  first-class signed claim.

## The central seam workflow

`reusable-attest-scan.yml` wraps `actions/attest`. It downloads an evidence
artifact (uploaded by the gate job) and signs the named file as a custom
predicate bound to `subject-digest`. Because it is a *central reusable
workflow*, the Fulcio SAN is the central signer — SLSA L3 isolation — and
verifiers pin `--signer-workflow`.

```yaml
attest-sast:
  needs: [build, sast]            # build emits the subject digest; sast emits SARIF
  permissions:
    id-token: write
    attestations: write
    contents: read
  uses: zircote/.github/.github/workflows/reusable-attest-scan.yml@<sha>
  with:
    subject-name: ghcr.io/zircote/app
    subject-digest: ${{ needs.build.outputs.digest }}
    predicate-type: https://zircote.github.io/attestations/sast/v1
    predicate-artifact: codeql-sarif      # uploaded by the sast job
    predicate-filename: results.sarif
```

The gate job must `actions/upload-artifact` its evidence file under
`predicate-artifact` so the seam job can download it (reusable workflows do not
share a filesystem across caller jobs).

## Predicate-type URIs

| Gate | Predicate type |
|------|----------------|
| SAST | `https://zircote.github.io/attestations/sast/v1` |
| SCA | `https://zircote.github.io/attestations/sca/v1` |
| Container vuln | `https://zircote.github.io/attestations/container-scan/v1` |
| IaC + license | `https://zircote.github.io/attestations/iac-license/v1` |
| Posture (Scorecard) | `https://zircote.github.io/attestations/scorecard/v1` |
| Load (k6) | `https://zircote.github.io/attestations/k6-load/v1` |
| DAST (ZAP) | `https://zircote.github.io/attestations/dast/v1` |
| Vuln disposition | `https://openvex.dev/ns/v0.2.0` (standard) |
| Build provenance | `https://slsa.dev/provenance/v1` (standard, attested-delivery) |
| SBOM | SPDX / CycloneDX via `attest-sbom` (attested-delivery) |

The custom `zircote.github.io/...` URIs need not resolve to a live document —
they are stable type identifiers a verifier pins with `--predicate-type`. Each
custom type is **defined** (body format, verdict rule, JSON Schema) in the
repo at
[`docs/reference/attestation-predicates/`](../../../../docs/reference/attestation-predicates/README.md);
that tree is the source of truth and what gets published if the namespace is
ever served.

## What the subject is

For a container release the subject is the image digest (shared with
`attested-delivery`). For non-container projects, the subject is whatever
artifact the gates concern — a release tarball digest, a built binary digest, or
a logical name + a computed `sha256:` of the source snapshot. Use the **same**
subject across all of a release's gate attestations so one `verify` covers them.

## Compose, don't duplicate

- Build provenance + SBOM: call `attested-delivery` (`sign-and-attest.yml`) —
  do not re-sign these here.
- Secret scanning + language audits: already in `reusable-security.yml`.
- SBOM + Grype: already in `sbom-and-scan.yml`.

The seam adds attestations only for the gates those do not already sign.
