---
name: "Maintenance: Release Readiness"
description: "Checks release readiness and tracks unreleased changes across repos"
tracker-id: mntrel01
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
  create-issue:
    title-prefix: "[Release] "
    labels: [gpm/report]
    close-older-issues: true
    target-repo: "zircote/.github"

metadata:
  team: platform
  priority: high
---

# GPM Maintenance: Release Readiness

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

### Phase 1: Check Unreleased Changes

For each managed repository:

1. **Find the latest release**: Use the GitHub API to get the most recent release (or tag if no releases exist)
2. **Compare HEAD to latest release**: Use the compare API (`compare/{tag}...{default_branch}`) to determine:
   - Number of commits since last release
   - List of PRs merged since last release (parse from commit messages or use search)
3. **Record days since last release**: Calculate the number of days between the latest release date and today
4. If a repo has **never had a release**, note it separately

### Phase 2: Assess Release Readiness

For each repo with unreleased changes:

1. **Check for release blockers**: Search for open issues labeled `release-blocker` in the repo
2. **Check for pending PRs**: Search for open PRs targeting the default branch that might need to land before release
3. **Verify CI status**: Check if the latest commit on the default branch has passing CI (use the commit status/checks API)
4. Assign a readiness status:
   - **Ready**: No blockers, CI passing, unreleased changes exist
   - **Blocked**: Has release-blocker issues
   - **CI Failing**: Default branch CI is not passing
   - **Pending PRs**: Has open PRs that may need to merge first

### Phase 3: Generate Changelog Preview

For each repo with unreleased changes, group merged PRs by type based on conventional commit prefixes or PR labels:

- **Features** (`feat:`, `feature`, label: `enhancement`)
- **Bug Fixes** (`fix:`, label: `bug`)
- **Documentation** (`docs:`, label: `documentation`)
- **Chores** (`chore:`, `ci:`, `build:`, label: `chore`)
- **Breaking Changes** (`BREAKING CHANGE:`, `!:` suffix, label: `breaking-change`)

Include contributor list (unique PR authors).

### Phase 4: Generate Report

Create an issue in `zircote/.github` with the following structure:

#### Report Format

```
### [Release] Weekly Readiness Report — {YYYY-MM-DD}

**Scanned:** {N} repositories | **Run:** ${{ github.run_id }}

---

#### Summary

| Metric | Count |
|--------|-------|
| Repos scanned | {n} |
| Repos with unreleased changes | {n} |
| Repos ready to release | {n} |
| Repos blocked | {n} |
| Repos with failing CI | {n} |
| Total unreleased commits | {n} |

---

#### Release Readiness Overview

| Repository | Status | Commits | Days Since Release | Blockers | CI |
|------------|--------|---------|-------------------|----------|----|
| `{repo}` | Ready/Blocked/CI Failing | {n} | {n} | {n} | pass/fail |

---

#### Repos Ready to Release

For each repo with status "Ready":

<details>
<summary>{repo-name} — {n} commits, {n} days since last release ({tag})</summary>

**Changelog Preview:**

**Features:**
- #{pr}: {title} (by @{author})

**Bug Fixes:**
- #{pr}: {title} (by @{author})

**Documentation:**
- #{pr}: {title} (by @{author})

**Chores:**
- #{pr}: {title} (by @{author})

**Breaking Changes:**
- #{pr}: {title} (by @{author})

**Contributors:** @{author1}, @{author2}

</details>

---

#### Blocked Repos

For each repo with release blockers:

<details>
<summary>{repo-name} — {n} blockers</summary>

**Release Blockers:**
- #{number}: {title} (opened {date})

**Pending PRs:**
- #{number}: {title} (by @{author})

</details>

---

#### CI Failing on Default Branch

| Repository | Workflow | Status | Since |
|------------|----------|--------|-------|
| `{repo}` | {workflow_name} | failing | {date} |

---

#### Never Released

<details>
<summary>{M} repositories with no releases</summary>

| Repository | Total Commits | Created |
|------------|--------------|---------|
| `{repo}` | {n} | {date} |

</details>

---

#### Up to Date (No Unreleased Changes)

<details>
<summary>{M} repositories with no changes since last release</summary>

{comma-separated list with last release tag and date}

</details>

---

*Generated by maintenance-release workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*
```

## Edge Cases

- If a repository returns an API error (rate limit, permission denied), skip it and note the error in the report footer
- If no repos have unreleased changes, still create a report confirming everything is up to date
- If a repository has been archived since the last run, exclude it
- If rate limits are approaching, prioritize repos with the most unreleased commits
- Batch API calls where possible to stay within rate limits
- If a repo uses tags instead of GitHub releases, treat the latest tag as the latest release
- If a repo has no tags and no releases, classify it as "Never Released"
- If the compare API returns an error (e.g., tag deleted), note the error and skip

## Fallback

If the safe-output (issue creation) fails (e.g., label missing, quota exceeded), output the complete report as your final response text so it is captured in the workflow run log.
