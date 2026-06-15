<!-- Append to the target repo's SECURITY.md. Replace __org__ with the owner. -->

## Verifying Quality-Gate Attestations

Each CI quality gate (SAST, SCA, container/IaC/license scan, supply-chain
posture, vulnerability disposition) records a signed, digest-bound attestation
via GitHub keyless signing. Verify them from any workstation with the `gh` CLI.

`--signer-workflow` is required: signing runs in a central reusable workflow, so
the certificate identity (SLSA L3) is the signer, not this repo.

```bash
SUBJECT=oci://ghcr.io/__org__/app@sha256:<digest>   # or your release artifact ref
OWNER=__org__
SIGNER=__org__/.github/.github/workflows/reusable-attest-scan.yml

# Example: verify the SAST gate attestation
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://__org__.github.io/attestations/sast/v1

# Vulnerability disposition (OpenVEX — standard predicate)
gh attestation verify "$SUBJECT" --owner "$OWNER" --signer-workflow "$SIGNER" \
  --predicate-type https://openvex.dev/ns/v0.2.0
```

A successful verification proves the attestation is authentic and bound to the
artifact — inspect the predicate body (`--format json | jq …`) to read the
gate's recorded verdict.
