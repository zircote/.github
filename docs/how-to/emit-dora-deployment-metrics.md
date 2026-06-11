---
diataxis_type: how-to
diataxis_goal: emit DORA deployment events and metrics to Datadog from a promotion pipeline
---

# How to Emit DORA Deployment Metrics

## Overview

`dora-emit.yml` sends the pipeline-side DORA signals to Datadog: a deployment
event, a deployment-frequency count, and an optional lead-time gauge. A
deployment is defined as a production digest promotion, so call it after
`promote-prod.yml` completes — on success *and* on failure, since failed
deployments feed change-failure rate.

## Prerequisites

- `DD_API_KEY` available as a secret in the calling repo.
- The promotion jobs expose the digest and outcome.

## Steps

### 1. Emit after the production promotion

```yaml
  dora:
    needs: promote-prod
    if: always()    # failures are DORA signals too
    permissions:
      contents: read
    uses: zircote/.github/.github/workflows/dora-emit.yml@<SHA>
    with:
      environment: prod
      service: <your-service>
      status: ${{ needs.promote-prod.result == 'success' && 'success' || 'failure' }}
      git-sha: ${{ github.sha }}
      image-digest: ${{ inputs.image-digest }}
    secrets:
      DD_API_KEY: ${{ secrets.DD_API_KEY }}
```

### 2. (Optional) Add lead time

If the pipeline knows when the PR was created, pass the PR-created→deploy
duration in seconds; `0` (the default) suppresses the gauge:

```yaml
    with:
      lead-time-seconds: ${{ steps.leadtime.outputs.seconds }}
```

### 3. (Optional) Segment by authoring cohort

Tag the deployment with how the change was authored so DORA can be segmented
by AI-assistance level:

```yaml
    with:
      authoring-cohort: ai-assisted
```

## Verification

In Datadog: the event `Deployment: <service> -> prod (success)` appears in the
Events Explorer, and the `zircote.dora.deployment` count metric increments
with tags `env:prod`, `service:<your-service>`, `status:success`. This is
acceptance test AT-08 in the [rollout status](../attested-delivery/rollout-status.md).

## Related

- [Reusable workflows reference](../reference/workflows.md#dora-emityml) — full inputs and emitted metrics
- [Why attested delivery](../explanation/attested-delivery.md#why-a-deployment-is-a-production-digest-promotion) — the deployment definition
