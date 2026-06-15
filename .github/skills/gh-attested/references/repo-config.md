# Repo configuration — the safety contract

Phase 3 provisions the GitHub-repo configuration the gates depend on. The rule
is a hard split between what the skill **applies automatically** (idempotent,
non-secret, reversible) and what it **only guides** (anything sensitive).

## Apply automatically — but preview + confirm first

Every mutation is shown as the exact `gh`/`gh api` command and **diffed against
current state** before the first apply. Re-running must be a no-op. Nothing is
force-applied; an ambiguous or failing state stops and reports. Tightening
protection on an active branch requires an explicit confirm.

Compose with the `gpm` skills rather than reinventing:
`gpm-branch-protection`, `gpm-repo-settings`, `gpm-labels`.

1. **Ruleset / branch protection** (`templates/ruleset.json`):
   ```bash
   gh api -X POST repos/<o>/<r>/rulesets --input templates/ruleset.json
   # update an existing ruleset:
   gh api -X PUT repos/<o>/<r>/rulesets/<id> --input templates/ruleset.json
   ```
   Required status checks (in-scope gate checks + `pin-check / pin-check`),
   required reviews + CODEOWNERS, dismiss-stale, signed commits, linear history,
   block force-push.

2. **Repo settings**:
   ```bash
   gh api -X PATCH repos/<o>/<r> \
     -F allow_auto_merge=true -F delete_branch_on_merge=true \
     -F allow_squash_merge=true -F allow_merge_commit=false
   ```

3. **Native free-tier scanners** (public repos):
   ```bash
   # Code scanning default setup
   gh api -X PATCH repos/<o>/<r>/code-scanning/default-setup -F state=configured
   # Secret scanning + push protection
   gh api -X PATCH repos/<o>/<r> \
     -f 'security_and_analysis[secret_scanning][status]=enabled' \
     -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
   ```
   Report exactly what was toggled.

4. **Committed files** (`dependabot.yml`, `CODEOWNERS`) — added via a PR, never
   force-pushed.

5. **Deploy environment**:
   ```bash
   gh api -X PUT repos/<o>/<r>/environments/production \
     -F wait_timer=0 \
     -f 'deployment_branch_policy[protected_branches]=true' \
     -f 'deployment_branch_policy[custom_branch_policies]=false'
   ```

## Guide only — never written, never logged

The skill emits the required **names** and the user-run command; it never reads,
writes, commits, or prints a value.

- **Secrets** (`gh secret set NAME` / `gh secret set NAME --env production`).
  Most gates need **none** — keyless signing and all OSS scanners require no
  secrets. Common optionals only: `GITLEAKS_LICENSE` (org gitleaks) and any
  deploy credentials. See `templates/secrets-and-vars.md`.
- **Variables** (`gh variable set NAME`) — non-secret config (severity
  thresholds, ZAP target URLs). Offered as commands; applied only on explicit
  per-item confirm.
- **Environment required-reviewers** — human GitHub identities; a manual step,
  the skill cannot choose reviewers.

## The four safety rules (also in SKILL.md)

1. Every config mutation is shown as a command and diffed before apply.
2. Secrets/credentials are never read, written, committed, or logged — names and
   the user-run command only.
3. Nothing is force-applied; ambiguous/failing state stops and reports.
4. Destructive changes (tightening protection on an active branch) need an
   explicit confirm.
