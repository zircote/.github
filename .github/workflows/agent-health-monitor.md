---
name: "Agent Health Monitor"
description: "Daily meta-monitoring of all gh-aw workflows for failures, missed schedules, and timeouts"
tracker-id: agenthm01
timeout-minutes: 10

on:
  schedule: daily
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
    title-prefix: "[agent-health] "
    target-repo: "zircote/.github"
    category: "Project Reports"
    expires: 3d
    max: 2

metadata:
  team: platform
  priority: high
---

# Agent Health Monitor

## Context

You are a meta-monitoring agent for the **zircote/.github** repository.
Your job is to watch all gh-aw agentic workflows and detect consecutive failures,
missed schedules, and timeouts before they become blind spots.

Determine today's date by running `date -u +%Y-%m-%d` via bash before generating the report.
Run ID: ${{ github.run_id }}

This workflow runs from the `zircote/.github` repository and has read access to
Actions workflow runs via a GitHub App installation token.

You may create up to 2 discussions: one summary report (always), and one ALERT
discussion if critical issues are found.

## Instructions

### Phase 1: Fetch Recent Workflow Runs

1. Use the Actions API to list all workflow runs for the `zircote/.github` repository from the last 48 hours
2. Compute the 48-hour threshold timestamp using bash:
   `date -u -d '48 hours ago' +%Y-%m-%dT%H:%M:%SZ`
3. Filter to only gh-aw workflows — these are identified by a `.lock.yml` suffix in the workflow file name (e.g., `org-monitor.lock.yml`, `agent-health-monitor.lock.yml`)
4. For each matching workflow run, collect:
   - Workflow name
   - Run ID
   - Status (`completed`, `in_progress`, `queued`)
   - Conclusion (`success`, `failure`, `timed_out`, `cancelled`)
   - `started_at` timestamp
   - `completed_at` timestamp
   - `run_attempt` number
5. Group runs by workflow name and sort by `started_at` descending within each group

### Phase 2: Failure Analysis

For each gh-aw workflow discovered in Phase 1, evaluate the following conditions:

#### Consecutive Failures
- Check for 2 or more sequential runs (by `started_at`) with conclusion `failure`
- This is the primary CRITICAL signal — it means a workflow is broken, not flaky

#### Timeouts
- Flag any run with conclusion `timed_out`
- Timeouts often indicate hung prompts or API issues

#### Cancellations
- Note runs with conclusion `cancelled`
- These may indicate manual intervention or upstream issues

#### Missed Schedules
- Compare each workflow's expected schedule against its actual last successful run:
  - **Daily workflows:** flag if no successful run in the last 36 hours
  - **Weekly workflows:** flag if no successful run in the last 10 days
- Use the workflow file name and any available metadata to infer the expected cadence
- If the schedule cannot be determined, note it as "unknown cadence"

#### Success Rate
- Calculate the success rate per workflow over the 48-hour window:
  `success_rate = successful_runs / total_completed_runs * 100`

### Phase 3: Self-Assessment (Paradox Check)

This workflow monitors itself. Acknowledge the recursive nature explicitly:

1. Check if `agent-health-monitor.lock.yml` appears in the collected runs
2. If previous runs of this workflow show failures, flag it prominently and note the irony — the monitoring system itself is unhealthy
3. If this is the first run (no prior runs found), note it as a baseline run with no historical data to compare
4. Always include a brief self-assessment line in the report regardless of status

### Phase 4: Generate Report

#### Summary Discussion (always created)

Create a discussion in the **Project Reports** category with the report format below.

#### Alert Discussion (only if critical)

If any workflow has 2 or more consecutive failures, create a second discussion using
the alert format below. This ensures critical issues are visible as separate items.

## Edge Cases

- If the Actions API returns errors, report what was accessible and note the error in the report footer
- If no gh-aw workflows exist yet (no `.lock.yml` runs found), report "no gh-aw workflows found" and exit cleanly with a summary discussion confirming this
- If this is the first run with no prior runs to compare, note it as a baseline run
- If discussion creation fails (e.g., category does not exist, quota exceeded), output the complete report as your final response text so it is captured in the workflow run log
- Rate limits are unlikely since this workflow monitors a single repository; if they occur, note the limitation in the report footer

## Report Format — Summary

### [agent-health] Agent Status — {YYYY-MM-DD}

**Overall Status:** {ALL GREEN | DEGRADED | CRITICAL}

- **ALL GREEN** — every gh-aw workflow has a successful most-recent run and no missed schedules
- **DEGRADED** — at least one workflow has a single failure, timeout, or cancellation (but no consecutive failures)
- **CRITICAL** — at least one workflow has 2+ consecutive failures or a missed schedule

---

#### Workflow Health

| Workflow | Last Run | Conclusion | Success Rate (48h) | Streak |
|----------|----------|------------|-------------------|--------|
| {name} | {timestamp} | {conclusion} | {n}% ({pass}/{total}) | {n} consecutive {pass/fail} |

---

#### Schedule Compliance

| Workflow | Expected Cadence | Last Success | Status |
|----------|-----------------|--------------|--------|
| {name} | {daily/weekly/unknown} | {timestamp} | {ON TIME / OVERDUE / UNKNOWN} |

---

#### Self-Assessment

> **agent-health-monitor:** {status message — e.g., "All previous runs successful", "First run — no history", "WARNING: own previous run failed"}

---

#### Details

For each workflow with non-success conclusions in the 48-hour window:

##### `{workflow-name}`

- **Failures:** {count} in last 48h
- **Timeouts:** {count}
- **Cancellations:** {count}
- **Last successful run:** {timestamp or "none in window"}
- **Run IDs:** {comma-separated list of failed run IDs with links}

---

<details>
<summary>Healthy workflows with no issues</summary>

{comma-separated list of workflows with 100% success rate}

</details>

---

*Generated by agent-health-monitor workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*

## Report Format — Alert

Only create this discussion if CRITICAL status is determined (2+ consecutive failures for any workflow).

### [agent-health] ALERT — {workflow-name} — {YYYY-MM-DD}

**Workflow:** `{workflow-name}`
**Consecutive Failures:** {count}
**Last Successful Run:** {timestamp or "never"}

---

#### Recent Failure Details

| Run ID | Started | Conclusion | Attempt |
|--------|---------|------------|---------|
| [{run_id}]({run_url}) | {started_at} | {conclusion} | {run_attempt} |

---

#### Error Context

{If available from run logs or annotations, include the error message or failure reason from the most recent failed run. If not accessible, note "error details not available from API."}

---

#### Suggested Actions

1. **Re-run manually** — trigger the workflow via `workflow_dispatch` to check if the failure is transient
2. **Check compiler changes** — run `gh aw compile` locally to verify the workflow lock file is valid
3. **Review recent commits** — check if recent changes to the `.md` source or `.lock.yml` introduced regressions
4. **Check upstream dependencies** — verify GitHub API availability and App token permissions

---

*Generated by agent-health-monitor workflow — ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}*
