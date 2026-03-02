---
name: "Housekeeping: Dependency Updates"
description: "Checks for pending dependency update PRs across managed repos"
tracker-id: hkdeps01
timeout-minutes: 30

on:
  schedule: weekly on monday
  workflow_dispatch:

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: copilot

tools:
  github:
    toolsets: [context, repos, issues, pull_requests, orgs, search]
    app:
      app-id: ${{ vars.GH_APP_ID }}
      private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
      owner: "zircote"
      repositories: ["*"]

  bash:
    - "echo"
    - "date"
    - "jq"
    - "sort"
    - "uniq"
    - "wc"
    - "head"
    - "tail"

safe-outputs:
  add-comment:
    hide-older-comments: true
  add-labels:
    max: 5
  create-issue:
    title-prefix: "[Dependencies] "
    labels: [gpm/report]
    close-older-issues: true
    target-repo: "zircote/.github"

metadata:
  team: platform
  priority: high
---

# GPM Housekeeping: Dependencies

## Context

You are a GPM automation agent for the **zircote** GitHub organization.

Determine today's date by running `date -u +%Y-%m-%d` via bash before starting.
Run ID: ${{ github.run_id }}

This workflow runs from the `zircote/.github` repository and has cross-repo read
access to all organization repositories via a GitHub App installation token.

## Configuration

Read the repository's `.github/gpm-config.yml` using the GitHub MCP `get_file_contents` tool:
- owner: `zircote`, repo: `.github`, path: `.github/gpm-config.yml`
- Decode the base64 content and parse the YAML
- Use the `repos` list as the managed repositories
- Use `excluded_repos` to skip excluded repositories
- Use `project.number` (1) and `project.org` (zircote) for project board operations

## Instructions

### Phase 1: Find Dependency PRs

Use the search toolset to find open dependency update PRs across managed repos:

1. Search for open PRs authored by `dependabot[bot]` across the organization:
   `org:zircote is:pr is:open author:app/dependabot`
2. Search for open PRs authored by `renovate[bot]`:
   `org:zircote is:pr is:open author:app/renovate`
3. Filter results to only include PRs in managed repos from the config
4. For each PR, collect:
   - Repository name
   - PR number, title, and URL
   - Dependency name, current version, and target version (parse from PR title)
   - PR creation date
   - CI status (passing, failing, pending)

### Phase 2: Categorize by Severity

Group all dependency updates into severity categories:

1. **Critical / Security**: PRs with "security" in the title, or Dependabot security advisories
2. **Major**: Major version bumps (e.g., v2.x to v3.x)
3. **Minor**: Minor version bumps (e.g., v2.1 to v2.2)
4. **Patch**: Patch version bumps (e.g., v2.1.0 to v2.1.1)

Additional flags:
- Flag PRs open longer than 7 days as "aging"
- Flag PRs with failing CI as "needs attention"
- Prioritize security updates at the top of every section

### Phase 3: Identify Stale Dependency PRs

Compute the aging threshold using bash:
`date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ`

Flag any dependency PR created before this threshold that is still open.

### Phase 4: Generate Report

Create an issue in `zircote/.github` with the following structure:

#### Report Format

```
### [Dependencies] Weekly Report — {YYYY-MM-DD}

**Scanned:** {N} repositories | **Run:** ${{ github.run_id }}

---

#### Summary

| Metric | Count |
|--------|-------|
| Repos scanned | {n} |
| Total pending dependency PRs | {n} |
| Security / Critical | {n} |
| Major updates | {n} |
| Minor updates | {n} |
| Patch updates | {n} |
| PRs with failing CI | {n} |
| Aging PRs (> 7 days) | {n} |

---

#### Security Updates (Action Required)

| Repo | PR | Dependency | From | To | Age | CI |
|------|----|------------|------|----|-----|----|
| `{repo}` | #{number} | {dep} | {from} | {to} | {days}d | pass/fail |

---

#### Major Updates

<details>
<summary>{count} major version updates</summary>

| Repo | PR | Dependency | From | To | Age | CI |
|------|----|------------|------|----|-----|----|
| `{repo}` | #{number} | {dep} | {from} | {to} | {days}d | pass/fail |

</details>

---

#### Minor Updates

<details>
<summary>{count} minor version updates</summary>

| Repo | PR | Dependency | From | To | Age | CI |
|------|----|------------|------|----|-----|----|
| `{repo}` | #{number} | {dep} | {from} | {to} | {days}d | pass/fail |

</details>

---

#### Patch Updates

<details>
<summary>{count} patch version updates</summary>

| Repo | PR | Dependency | From | To | Age | CI |
|------|----|------------|------|----|-----|----|
| `{repo}` | #{number} | {dep} | {from} | {to} | {days}d | pass/fail |

</details>

---

#### Attention Required

**Failing CI:**
- `{repo}` #{number}: {title} — CI failing since {date}

**Aging PRs (> 7 days):**
- `{repo}` #{number}: {title} — open for {days} days

---

#### Clean Repositories

<details>
<summary>{M} repositories with no pending dependency updates</summary>

{comma-separated list}

</details>

---

*Generated by housekeeping-deps workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*
```

## Edge Cases

- If a repository returns an API error (rate limit, permission denied), skip it and note the error in the report footer
- If there are no pending dependency PRs across all repos, still create a report confirming everything is up to date
- If a repository has been archived since the last run, exclude it
- If rate limits are approaching, prioritize repositories with security-related PRs
- Batch API calls where possible to stay within rate limits
- If a PR title cannot be parsed for version info, include it with "unknown" version fields

## Fallback

If the safe-output (issue creation) fails (e.g., label missing, quota exceeded), output the complete report as your final response text so it is captured in the workflow run log.
