# Verifying quality-gate attestations

Run these **independently from a workstation** against the published subject —
in-pipeline success is not the acceptance test. `gh attestation verify` exits
non-zero on any failure.

`--signer-workflow` is **mandatory** under SLSA L3: the Fulcio SAN is the
central signing workflow, not the source repo, so `--owner`/`--repo` alone fail.

## Prerequisites

```bash
gh --version            # gh CLI authenticated
gh attestation --help   # built in to recent gh
```

## Verify a single gate predicate

**Each predicate is verified against the workflow that actually signed it** —
the "Signed by" column in
[`docs/reference/attestation-predicates/`](../../../../docs/reference/attestation-predicates/README.md)
is the source of truth. The seam (`reusable-attest-scan.yml`) signs the SARIF
gates; **OpenVEX self-signs in `reusable-vex.yml` and k6 self-signs in
`reusable-k6.yml`** (each runs its own `actions/attest`, so under SLSA L3 its
Fulcio SAN is itself, not the seam). Pin `--signer-workflow` accordingly — one
signer per command.

```bash
SUBJECT=oci://ghcr.io/zircote/app@sha256:<digest>   # or a file path / oci ref
OWNER=zircote
SEAM=zircote/.github/.github/workflows/reusable-attest-scan.yml
VEX_SIGNER=zircote/.github/.github/workflows/reusable-vex.yml
K6_SIGNER=zircote/.github/.github/workflows/reusable-k6.yml

# Seam-signed gates (SAST, SCA, container, IaC+license, posture, DAST)
for pt in sast sca container-scan iac-license scorecard dast; do
  gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SEAM" \
    --predicate-type "https://zircote.github.io/attestations/${pt}/v1"
done

# Vulnerability disposition (OpenVEX — self-signed by reusable-vex.yml)
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$VEX_SIGNER" \
  --predicate-type https://openvex.dev/ns/v0.2.0

# Load / performance (k6 — self-signed by reusable-k6.yml)
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$K6_SIGNER" \
  --predicate-type https://zircote.github.io/attestations/k6-load/v1
```

> The seam-signed SARIF predicates verify once the gate jobs upload their
> evidence to `reusable-attest-scan.yml` (see `attestation-seam.md`); OpenVEX and
> k6 sign inline today. The `--signer-workflow` pins below are verified by
> reasoning about the SLSA L3 certificate identity, not by a live `gh
> attestation verify` run in this repo.

## Verify the build-provenance backbone (attested-delivery signer)

```bash
gh attestation verify "$SUBJECT" --owner "$OWNER" \
  --signer-workflow zircote/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1
```

## Offline / air-gapped

```bash
gh attestation trusted-root > trusted_root.jsonl
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SEAM" \
  --bundle attestation.sigstore.json --custom-trusted-root trusted_root.jsonl
```

## Read the verdict, not just the signature

A successful `verify` proves the attestation is authentic and bound to the
subject — **not** that the gate passed. Inspect the predicate body to confirm
the recorded verdict:

```bash
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SEAM" \
  --predicate-type https://zircote.github.io/attestations/sast/v1 \
  --format json | jq '.[0].verificationResult.statement.predicate'
```
