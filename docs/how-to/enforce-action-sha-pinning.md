---
diataxis_type: how-to
diataxis_goal: fail CI when any GitHub Action reference is not pinned to a full commit SHA
---

# How to Enforce Action SHA Pinning

## Overview

Mutable action references (`@v4`, `@main`) are a supply-chain risk — a
compromised upstream tag silently changes what your workflow runs.
`pin-check.yml` fails a run on the first `uses:` reference that is not pinned
to a full 40-character commit SHA. Local reusable-workflow calls
(`uses: ./...`) and digest-pinned container actions
(`uses: docker://...@sha256:...`) are exempt.

## Prerequisites

- None. The workflow checks out and scans the calling repo itself.

## Steps

### 1. Add a pin-check job to CI

```yaml
# .github/workflows/ci.yml in an application repo
jobs:
  pin-check:
    permissions:
      contents: read
    uses: zircote/.github/.github/workflows/pin-check.yml@<SHA>
```

By default it scans `.github`; pass `scan-dir` to scan elsewhere. If your repo
keeps documentation containing example `uses:` lines under `.github` (e.g.
skill markdown), scope `scan-dir` to `.github/workflows` so illustrative
examples are not flagged — this repo's own gate
([`pin-check-ci.yml`](../../.github/workflows/pin-check-ci.yml)) does exactly
that, with a second job covering `actions/`.

### 2. Make it a required status check

In branch protection, add the check to required status checks so unpinned
references cannot merge. The context name is
`<caller job id> / <called job name>` — for the example above,
`pin-check / pin-check` — not the workflow name. Read it off an actual run
before adding it.

### 3. Fix violations it reports

Replace each flagged reference with the commit SHA of the release you intend,
keeping the version as a comment:

```yaml
# before
- uses: actions/checkout@v6
# after
- uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10  # v6.0.3
```

Actions whose ref encodes behavior (e.g. `dtolnay/rust-toolchain@stable`) need
an explicit input (`with: toolchain: stable`) once pinned, because the SHA no
longer encodes the channel.

Dependabot's `github-actions` ecosystem keeps pinned SHAs current via PRs.

## Verification

Run the workflow on a branch containing an unpinned `uses:`; the run fails
with an annotated error naming the file and line. On a clean repo it succeeds
with `All action references under .github are pinned to a 40-char SHA.`

## Related

- [Reusable workflows reference](../reference/workflows.md#pin-checkyml)
- [Why attested delivery](../explanation/attested-delivery.md) — pinning as part of the supply-chain posture
