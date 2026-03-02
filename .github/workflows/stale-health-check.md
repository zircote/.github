---
name: "Stale Project Health Check"
description: "Weekly scan for stale issues, abandoned PRs, failing CI, and README staleness across all zircote repos"
tracker-id: stlhlt01
timeout-minutes: 20

on:
  schedule: weekly
  workflow_dispatch:

permissions:
  contents: read
  issues: read
  pull-requests: read
  discussions: read
  actions: read

engine:
  id: copilot

tools:
  cache-memory:

  github:
    toolsets: [context, repos, issues, pull_requests, discussions, orgs, search, actions]
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
  create-discussion:
    title-prefix: "[stale-health] "
    target-repo: "zircote/.github"
    category: "Project Reports"
    expires: 7d
    max: 1

metadata:
  team: platform
  priority: high
---

# Stale Project Health Check

## Context

You are a project health monitoring agent for the **zircote** GitHub organization.
Your job is to produce a comprehensive weekly health report covering all public repositories,
surfacing stale issues, abandoned pull requests, failing CI, and outdated READMEs.

Determine today's date by running `date -u +%Y-%m-%d` via bash before generating the report.
Run ID: ${{ github.run_id }}

This workflow runs from the `zircote/.github` repository and has cross-repo read
access to all organization repositories via a GitHub App installation token.

## Scope

Monitor **all public, non-archived repositories** in the `zircote` organization.

**Explicitly excluded:** `zircote/php-swagger` and `zircote/swagger-php` — do NOT include these repositories in any analysis or reporting.

## Instructions

### Phase 1: Discover Repositories

1. Use the `list_org_repositories` tool to list all public, non-archived repositories in the `zircote` organization
2. Filter out `php-swagger` and `swagger-php` from the list
3. Note the total count of monitored repositories

### Phase 2: Stale Issue Scan

Compute the 30-day threshold date using bash:
`date -u -d '30 days ago' +%Y-%m-%d`

Run a single cross-org search query to find all stale open issues:
`org:zircote is:issue is:open updated:<{30_days_ago_date}`

Exclude any results from `php-swagger` or `swagger-php`.

For each matched issue, record:
- Repository name
- Issue number, title, author, URL
- Date last updated

Group results by repository. For each repo with stale issues, note:
- Total stale issue count
- Oldest stale issue (title, number, last updated date)

### Phase 3: Abandoned PR Scan

Compute the 7-day threshold date using bash:
`date -u -d '7 days ago' +%Y-%m-%d`

Run a single cross-org search query to find all abandoned open PRs:
`org:zircote is:pr is:open updated:<{7_days_ago_date}`

Exclude any results from `php-swagger` or `swagger-php`.

For each matched PR, record:
- Repository name
- PR number, title, author, URL
- Date last updated
- Whether reviewers are assigned (flag PRs with no reviewers)

Group results by repository. For each repo with abandoned PRs, note:
- Total abandoned PR count
- PRs missing reviewers

### Phase 4: CI Health Scan

For each monitored repository:

1. Get the most recent workflow run on the default branch using the actions toolset
2. Check the `conclusion` field of the latest run
3. Flag any repository where the latest run has a non-success conclusion (`failure`, `cancelled`, `timed_out`)

Record for flagged repos:
- Repository name
- Workflow name
- Run conclusion
- Run URL

Skip repos that have no workflow runs (they simply have no CI configured).

### Phase 5: README Freshness

For each monitored repository:

1. Get the last commit date for `README.md` (or `readme.md`, `README`) using the repos toolset
2. Get the repository's `pushed_at` timestamp
3. Compare the two dates

Flag repositories where:
- README has not been updated in 6+ months AND
- The repository has had pushes more recently than the README update

Record for flagged repos:
- Repository name
- README last updated date
- Repository last push date
- Staleness gap (in months)

Skip repos that have no README file.

### Phase 6: Generate Health Report

Create a single discussion post in the **Project Reports** category of `zircote/.github` using the report format below.

## Edge Cases

- If a repository returns an API error (rate limit, permission denied), skip it and note the error in the report footer
- If zero issues are found across all phases, still create a report confirming clean project health
- If rate limits are approaching, prioritize repositories with known recent activity
- Batch API calls where possible to stay within rate limits
- If the report discussion cannot be created via safe-output (e.g., category does not exist, quota exceeded), output the complete report as your final response text so it is captured in the workflow run log

## Report Format

### [stale-health] Weekly Health Report — {YYYY-MM-DD}

**Monitored:** {N} repositories | **Excluded:** php-swagger, swagger-php

---

#### Summary

| Metric | Count |
|--------|-------|
| Stale issues (>30 days) | {n} |
| Abandoned PRs (>7 days) | {n} |
| Failing CI on default branch | {n} |
| Stale READMEs (>6 months) | {n} |

---

#### Stale Issues (>30 Days Without Activity)

For each repository with stale issues:

##### `{repo-name}` — {count} stale issues

- :warning: #{number} {title} by @{author} — last updated {date}
- ...

*Oldest: #{number} {title} — last updated {date}*

---

#### Abandoned PRs (>7 Days Without Activity)

For each repository with abandoned PRs:

##### `{repo-name}` — {count} abandoned PRs

- :hourglass: #{number} {title} by @{author} — last updated {date}
- :no_entry_sign: #{number} {title} — **no reviewers assigned**
- ...

---

#### Failing CI on Default Branch

For each repository with failing CI:

- :red_circle: `{repo-name}`: {workflow_name} — {conclusion} ([run]({run_url}))

---

#### Stale READMEs (>6 Months Without Update)

For each repository with a stale README:

- :book: `{repo-name}`: README last updated {readme_date}, repo last pushed {push_date} ({gap} months gap)

---

#### Attention Required

Highlight the most critical items requiring immediate human action:

1. **Failing CI** — Repos with broken builds on default branch need immediate attention
2. **Abandoned PRs without reviewers** — PRs that may need to be closed or assigned
3. **Oldest stale issues** — Issues open and inactive for the longest period

---

#### Clean Repos

<details>
<summary>{M} repositories with no health issues</summary>

{comma-separated list of repos with zero findings across all phases}

</details>

---

*Generated by stale-health-check workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*
