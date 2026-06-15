# Phase 0 — Assessment procedure

Read-only. Produce a coverage matrix before proposing any change. Replace
`<o>/<r>` with owner/repo.

## Repo shape

```bash
# Visibility (public ⇒ free GitHub-proprietary scanners) and default branch
gh api repos/<o>/<r> --jq '{visibility, default_branch, language}'

# Languages present (drives CodeQL languages + SCA ecosystems)
gh api repos/<o>/<r>/languages

# Is there a container image / Dockerfile? A running app / load script?
gh api repos/<o>/<r>/contents --jq '.[].name' | grep -iE 'dockerfile|compose' || true
```

## Native free-tier scanners (public repos)

```bash
# Code scanning (CodeQL) default-setup state
gh api repos/<o>/<r>/code-scanning/default-setup --jq '{state, languages}' 2>/dev/null \
  || echo "default setup not configured"

# Secret scanning + push protection + dependency review (security_and_analysis)
gh api repos/<o>/<r> --jq '.security_and_analysis'

# Open code-scanning alerts (any tool) — counts as "gate present but findings open"
gh api 'repos/<o>/<r>/code-scanning/alerts?state=open&per_page=1' --jq 'length' 2>/dev/null || true
```

## Supply-chain config

```bash
# Dependabot config present?
gh api repos/<o>/<r>/contents/.github/dependabot.yml --jq '.path' 2>/dev/null || echo "no dependabot.yml"

# Dependabot alerts enabled?
gh api repos/<o>/<r>/vulnerability-alerts -i 2>/dev/null | head -1   # 204 = enabled, 404 = not
```

## Existing workflows + pinning posture

```bash
# Inventory workflows
gh api repos/<o>/<r>/contents/.github/workflows --jq '.[].name' 2>/dev/null || echo "no workflows"

# Count tag-pinned (unsafe) uses: — should be zero after Phase 2
gh api repos/<o>/<r>/contents/.github/workflows --jq '.[].path' 2>/dev/null \
  | while read -r p; do gh api "repos/<o>/<r>/contents/$p" --jq '.content' \
  | base64 -d | grep -nE 'uses:.*@(v[0-9]|main|master)' || true; done
```

## Enforcement state

```bash
# Rulesets / branch protection on the default branch
gh api repos/<o>/<r>/rulesets --jq '.[].name' 2>/dev/null || true
gh api repos/<o>/<r>/branches/<default>/protection --jq \
  '{checks: .required_status_checks.contexts, reviews: .required_pull_request_reviews}' 2>/dev/null \
  || echo "no branch protection"

# Environments (deploy gates)
gh api repos/<o>/<r>/environments --jq '.environments[].name' 2>/dev/null || echo "none"
```

## Coverage matrix template

Fill one row per gate. `Present` = a workflow/config exists; `Attested` = its
verdict is a signed attestation; `Merge`/`Deploy` = it gates that decision.

| Gate | Present | Attested | Merge gate | Deploy gate | Gap / action |
|------|:---:|:---:|:---:|:---:|------|
| SAST (CodeQL) | | | | | |
| SCA (OSV + dep-review + Dependabot) | | | | | |
| Secret detection | | | | | |
| Container vuln (Trivy) | | | | | |
| IaC + license (Trivy) | | | | | |
| SBOM | | | | | |
| Vuln disposition (VEX) | | | | | |
| Build provenance | | | | | |
| Supply-chain posture (Scorecard) | | | | | |
| Peer review (rulesets/CODEOWNERS) | | | | | |
| Load / perf (k6) | | | | | |
| DAST (ZAP) | | | | | |

Exit Phase 0 with this matrix and a list of in-scope gates (mark k6/ZAP
out-of-scope unless a running target exists).
