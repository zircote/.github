---
name: "Housekeeping: Stale Issues & PRs"
description: "Marks and closes stale issues and PRs after configurable inactivity periods"
tracker-id: hkstale1
timeout-minutes: 30

on:
  schedule: weekly on sunday
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
  close-issue:
  close-pull-request:
  create-issue:
    title-prefix: "[Housekeeping] "
    labels: [gpm/report]
    close-older-issues: true
    target-repo: "zircote/.github"

metadata:
  team: platform
  priority: high
---

# GPM Housekeeping: Stale Issues & PRs

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

### Stale Thresholds
- **Stale warning after:** 30 days of no activity
- **Close after stale:** 60 days of no activity (30 days after stale label applied)
- **Exempt labels:** `pinned`, `security`, `critical`
- **Exempt items:** Issues/PRs with milestones assigned

## Instructions

### Phase 1: Identify Stale Items

Compute threshold timestamps using bash:
```
STALE_THRESHOLD=$(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
CLOSE_THRESHOLD=$(date -u -d '60 days ago' +%Y-%m-%dT%H:%M:%SZ)
```

For each managed repository:

1. **Find newly stale issues**: Open issues with no activity since `STALE_THRESHOLD`
   - Use search: `repo:zircote/{repo} is:issue is:open updated:<{STALE_THRESHOLD}`
   - Exclude issues with exempt labels (`pinned`, `security`, `critical`)
   - Exclude issues with milestones assigned
   - Exclude issues already labeled `stale`
   - Exclude pinned issues

2. **Find newly stale PRs**: Open PRs with no activity since `STALE_THRESHOLD`
   - Use search: `repo:zircote/{repo} is:pr is:open updated:<{STALE_THRESHOLD}`
   - Exclude PRs with exempt labels
   - Exclude PRs with milestones assigned
   - Exclude PRs already labeled `stale`
   - Exclude PRs from `dependabot[bot]` and `renovate[bot]` (handled by deps workflow)

3. **Find items ready to close**: Items labeled `stale` with no activity since the stale label was applied and total inactivity exceeding `CLOSE_THRESHOLD`
   - Use search: `repo:zircote/{repo} is:open label:stale updated:<{CLOSE_THRESHOLD}`

### Phase 2: Apply Stale Warning

For each newly stale item (not already labeled `stale`):

1. Add the `stale` label using the `add-labels` safe-output
2. Add a comment using `add-comment` safe-output:
   ```
   This issue has been automatically marked as **stale** because it has not had
   activity in the last 30 days. It will be closed in 30 days if no further
   activity occurs.

   To keep this open:
   - Add a comment with an update or explanation
   - Remove the `stale` label
   - Add a milestone or exempt label (`pinned`, `security`, `critical`)
   ```

### Phase 3: Close Stale Items

For items that have been stale past the close threshold:

1. Add a closing comment using `add-comment`:
   ```
   This issue has been automatically closed after 60 days of inactivity.
   If this is still relevant, please reopen it with additional context.
   ```
2. Close the issue using `close-issue` or `close-pull-request` safe-output

### Phase 4: Detect Unstaled Items

Check for items that had the `stale` label but received activity (comments, commits, label changes) since being marked stale. These were "unstaled" by human activity and should be noted in the report.

### Phase 5: Generate Report

Create an issue in `zircote/.github` with the following structure:

#### Report Format

```
### [Housekeeping] Stale Items Report — {YYYY-MM-DD}

**Scanned:** {N} repositories | **Run:** ${{ github.run_id }}

---

#### Summary

| Metric | Count |
|--------|-------|
| Repos scanned | {n} |
| Newly marked stale (issues) | {n} |
| Newly marked stale (PRs) | {n} |
| Auto-closed (issues) | {n} |
| Auto-closed (PRs) | {n} |
| Unstaled (activity resumed) | {n} |
| Exempt items skipped | {n} |

---

#### Newly Stale Items

For each repo with newly stale items:

<details>
<summary>{repo-name} — {count} items marked stale</summary>

**Issues:**
- #{number}: {title} — last activity {date} (by @{author})

**Pull Requests:**
- #{number}: {title} — last activity {date} (by @{author})

</details>

---

#### Auto-Closed Items

For each repo with auto-closed items:

<details>
<summary>{repo-name} — {count} items closed</summary>

**Issues:**
- #{number}: {title} — inactive since {date}

**Pull Requests:**
- #{number}: {title} — inactive since {date}

</details>

---

#### Unstaled Items (Activity Resumed)

Items that were previously stale but received new activity:
- `{repo}` #{number}: {title} — activity on {date}

---

#### Exempt Items Skipped

<details>
<summary>{count} items skipped due to exemptions</summary>

| Repo | # | Type | Exemption Reason |
|------|---|------|------------------|
| `{repo}` | #{number} | issue/PR | {label/milestone} |

</details>

---

#### Clean Repositories

<details>
<summary>{M} repositories with no stale items</summary>

{comma-separated list}

</details>

---

*Generated by housekeeping-stale workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*
```

## Edge Cases

- If a repository returns an API error (rate limit, permission denied), skip it and note the error in the report footer
- If there are no stale items across all repos, still create a report confirming a clean state
- If a repository has been archived since the last run, exclude it
- If rate limits are approaching, prioritize close operations over stale-marking
- Batch API calls where possible to stay within rate limits
- If an item was recently commented on by a bot (CI, Dependabot), do not count that as human activity for unstaling purposes
- Never close items with exempt labels, even if they exceed the close threshold

## Fallback

If the safe-output (issue creation) fails (e.g., label missing, quota exceeded), output the complete report as your final response text so it is captured in the workflow run log.
