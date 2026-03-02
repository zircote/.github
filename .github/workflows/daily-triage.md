---
name: "Daily Triage"
description: >
  Catch-all safety net that finds untriaged issues and
  PRs — both those labeled needs-triage and those that
  slipped through without any labels or assignees.
tracker-id: dlytri01
timeout-minutes: 20

on:
  schedule: daily on weekdays
  workflow_dispatch:

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: copilot

tools:
  cache-memory:

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
  add-labels:
    max: 10
  remove-labels:
  add-comment:
    hide-older-comments: true
  create-issue:
    title-prefix: "[Triage] "
    labels: [gpm/report]
    close-older-issues: true
    target-repo: "zircote/.github"

metadata:
  team: platform
  priority: high
---

# GPM Daily Triage

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

Load label taxonomy and CODEOWNERS data from each repository where available.

## How This Fits the Triage Pipeline

```
New issue/PR opened
  │
  ▼
gpm-auto-label workflow (on: issues.opened,
  pull_request.opened) applies "needs-triage"
  │
  ▼
gpm-triage agent (batch mode) processes items
  labeled "needs-triage", applies type/priority/area,
  removes "needs-triage"
  │
  ▼
THIS WORKFLOW runs daily as a catch-all net,
  finding anything that slipped through:
  - Items without any labels (auto-label missed)
  - Items without assignees (triage agent skipped)
  - Items still labeled needs-triage (agent failed)
  - PRs without reviewers
```

## Instructions

### Pass 1 — Find needs-triage Stragglers

Items that have `needs-triage` but were not processed by the triage agent (e.g., agent was offline, rate-limited, or errored).

For each managed repository, search for:
- Open issues with the `needs-triage` label
- Open PRs with the `needs-triage` label

Use org-wide search: `org:zircote is:open label:needs-triage`

### Pass 2 — Find Unlabeled Items

Items that never got `needs-triage` applied (created before auto-label was enabled, or via API/import without triggering the workflow).

For each managed repository:
- Find open issues with zero labels
- Find open PRs with zero labels

Use org-wide search: `org:zircote is:open no:label`

### Pass 3 — Find Unassigned Items

Items that were labeled but never assigned:

For each managed repository:
- Find open issues with labels but no assignee
- Find open PRs with no reviewers requested

### Deduplicate

Merge results from all three passes, deduplicate by repo + number. An item found in multiple passes should only appear once in the final list, but note which passes it was found in.

### Auto-Label

For each untriaged item:
- Analyze issue/PR title and body content
- Match against common label taxonomy keywords:
  - `type/bug` — error, fix, broken, crash, regression
  - `type/feature` — add, new, request, enhancement
  - `type/docs` — documentation, readme, typo
  - `type/chore` — dependency, update, maintenance
  - `priority/high` — security, CVE, critical, urgent
  - `priority/medium` — default for most items
  - `priority/low` — cosmetic, minor, nice-to-have
- Apply suggested labels using `add-labels` safe-output (max 10 per item)
- Apply area labels based on files changed (for PRs) where CODEOWNERS data is available
- Remove `needs-triage` label if present after applying proper labels

### Suggest Assignees

- Check CODEOWNERS for relevant file paths (for PRs)
- Consider past activity on similar issues in the repository
- Suggest assignees in the triage report but do not force-assign

### Report

Generate a triage report with counts of:
- Items auto-labeled (by pass: needs-triage, unlabeled, unassigned)
- Items needing manual triage (too ambiguous to auto-label)
- Suggested assignments

## Output

Post triage summary as an issue using the `create-issue` safe-output:

```markdown
## [Triage] Daily Triage Report — {YYYY-MM-DD}

**Repos scanned**: {N}

| Pass | Items Found | Auto-Triaged | Manual |
|------|-------------|--------------|--------|
| needs-triage label | {n} | {n} | {n} |
| Unlabeled | {n} | {n} | {n} |
| Unassigned | {n} | {n} | {n} |

### Actions Taken

- Labels applied: {n} items across {m} repos
- Labels removed: {n} `needs-triage` labels
- Suggested assignments: {n}

### Items Needing Human Attention

| # | Repo | Title | Reason |
|---|------|-------|--------|
| {number} | {owner/repo} | {title} | {reason} |

<details>
<summary>Per-Repo Breakdown</summary>

#### `{repo-name}`
- Pass 1 (needs-triage): {n} items
- Pass 2 (unlabeled): {n} items
- Pass 3 (unassigned): {n} items
- Auto-labeled: {n} | Manual: {n}

</details>
```

## Fallback

If the safe-output (issue creation) fails (e.g., label missing, quota exceeded), output the complete report as your final response text so it is captured in the workflow run log.

---
*Generated by daily-triage workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*
