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

```bash
SUBJECT=oci://ghcr.io/zircote/app@sha256:<digest>   # or a file path / oci ref
OWNER=zircote
SIGNER=zircote/.github/.github/workflows/reusable-attest-scan.yml

# SAST
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://zircote.github.io/attestations/sast/v1

# SCA
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://zircote.github.io/attestations/sca/v1

# Container vulnerability
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://zircote.github.io/attestations/container-scan/v1

# IaC + license
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://zircote.github.io/attestations/iac-license/v1

# Supply-chain posture
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://zircote.github.io/attestations/scorecard/v1

# Vulnerability disposition (OpenVEX — standard predicate type)
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://openvex.dev/ns/v0.2.0
```

## Verify the build-provenance backbone (attested-delivery signer)

```bash
gh attestation verify "$SUBJECT" --owner "$OWNER" \
  --signer-workflow zircote/.github/.github/workflows/sign-and-attest.yml \
  --predicate-type https://slsa.dev/provenance/v1
```

## Offline / air-gapped

```bash
gh attestation trusted-root > trusted_root.jsonl
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --bundle attestation.sigstore.json --custom-trusted-root trusted_root.jsonl
```

## Read the verdict, not just the signature

A successful `verify` proves the attestation is authentic and bound to the
subject — **not** that the gate passed. Inspect the predicate body to confirm
the recorded verdict:

```bash
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://zircote.github.io/attestations/sast/v1 \
  --format json | jq '.[0].verificationResult.statement.predicate'
```
