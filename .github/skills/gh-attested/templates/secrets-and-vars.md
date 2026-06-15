# Secrets & variables — set these yourself

The skill **never reads, writes, commits, or logs a secret value.** It only
prints the required names and the command for you to run. Run them yourself so
the value is piped from your input, never through the agent.

> ⚠️ Do not paste secret values into the chat or a workflow file. Use the
> commands below; GitHub stores them encrypted.

## Secrets — most gates need NONE

Keyless Sigstore signing and every OSS scanner (CodeQL, OSV-Scanner, Trivy,
Scorecard, vexctl, k6, ZAP) require **no secrets** — `GITHUB_TOKEN` and OIDC
cover them. Set a secret only for the optional cases below.

| Secret | When needed | Set it yourself |
|--------|-------------|-----------------|
| `GITLEAKS_LICENSE` | only if using org-tier gitleaks in `reusable-security.yml` | `gh secret set GITLEAKS_LICENSE` |
| deploy credentials (e.g. `AWS_ROLE_ARN` via OIDC is preferred over a static key) | only if the deploy job needs them | `gh secret set <NAME> --env production` |

Prefer OIDC (`id-token: write` + a cloud trust policy) over long-lived
credentials wherever the target supports it.

## Variables — non-secret config

| Variable | Purpose | Set it yourself |
|----------|---------|-----------------|
| `ZAP_TARGET_URL` | DAST target (if not hard-coded) | `gh variable set ZAP_TARGET_URL` |
| `TRIVY_SEVERITY` | override severity threshold | `gh variable set TRIVY_SEVERITY` |

## Environment required-reviewers

Human approval on the `production` environment is a manual step in
**Settings → Environments → production → Required reviewers** — the skill cannot
choose reviewers for you.
