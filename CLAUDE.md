# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is the **zircote/.github** organization-wide repository providing shared GitHub infrastructure:
- Community health files (SECURITY.md, CONTRIBUTING.md)
- Reusable GitHub Actions workflows
- Composite actions for CI/CD
- Copilot skills and autonomous agents
- Label definitions and templates

## Repository Structure

```
.github/
├── .github/
│   ├── workflows/           # Reusable workflows (workflow_call)
│   ├── skills/              # Copilot skills (SKILL.md format)
│   ├── prompts/             # GitHub Copilot prompts
│   └── ISSUE_TEMPLATE/      # Issue templates
├── actions/                 # Composite actions
│   ├── setup-python-uv/     # Python + uv setup
│   ├── setup-node-pnpm/     # Node.js + pnpm setup
│   ├── security-scan/       # Security scanning
│   └── release-notes/       # Changelog generation
├── agents/                  # Autonomous agent definitions (markdown)
├── scripts/                 # Automation scripts
├── profile/                 # Organization profile (github.com/zircote)
└── labels.yml               # Standardized issue/PR labels
```

## Key Patterns

### Workflow Security Requirements

All GitHub Actions **must** use SHA-pinned actions:

```yaml
# CORRECT - SHA pinned with version comment
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

# WRONG - Never use tag references
- uses: actions/checkout@v4
```

All workflows must declare minimal permissions:

```yaml
permissions:
  contents: read  # Minimum required
```

### Reusable Workflow Pattern

Caller workflow (in consuming repository):
```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-python.yml@main
    with:
      python-version: '3.12'
      coverage-threshold: 80
    secrets: inherit
```

### Agent Definition Format

Agents use YAML frontmatter in markdown files:

```markdown
---
name: agent-name
description: Brief description
tools:
  - Read
  - Write
  - Edit
  - Bash
model: sonnet
---

# Agent Name

System prompt and instructions follow...
```

### Skill Definition Format

Skills in `.github/skills/*/SKILL.md` use:

```markdown
---
name: skill-name
description: USE THIS SKILL when user says "trigger phrase"
allowed-tools:
  - Bash
  - Read
  - Write
---

# Skill Name

Instructions and patterns...
```

## Available Reusable Workflows

| Workflow | Purpose | Key Inputs |
|----------|---------|------------|
| `reusable-ci-python.yml` | Python CI (uv, ruff, pyright, pytest) | `python-version`, `coverage-threshold` |
| `reusable-ci-typescript.yml` | TypeScript CI (pnpm, ESLint, Vitest) | `node-version` |
| `reusable-ci-go.yml` | Go CI (golangci-lint) | `go-version` |
| `reusable-release.yml` | Semantic release | `release-type`, `dry-run` |
| `reusable-security.yml` | Security scanning | `scan-secrets`, `scan-dependencies` |
| `reusable-docs.yml` | Documentation deployment | `framework`, `deploy-to-pages` |

## Available Composite Actions

| Action | Purpose |
|--------|---------|
| `actions/setup-python-uv` | Install Python + uv with caching |
| `actions/setup-node-pnpm` | Install Node.js + pnpm with caching |
| `actions/security-scan` | Run gitleaks + dependency scanning |
| `actions/release-notes` | Generate changelog from commits |

## Label Synchronization

Sync standardized labels to a repository:
```bash
gh workflow run sync-labels.yml -f repo=zircote/my-repo
```

Or use github-label-sync directly:
```bash
npx github-label-sync --access-token $GITHUB_TOKEN --labels labels.yml zircote/repo-name
```

## gh-aw Agentic Workflows

The `org-monitor.md` workflow uses GitHub Agentic Workflows (gh-aw). Key conventions:

### Compiling

gh-aw workflows are markdown files that compile to `.lock.yml` via `gh aw compile`. The lock file is auto-generated — do not edit it directly.

```bash
# Compile all gh-aw workflows
gh aw compile

# Compile specific workflow
gh aw compile org-monitor
```

**Known issue:** Repos named `.github` trigger a runtime-import path bug ([github/gh-aw#18711](https://github.com/github/gh-aw/issues/18711)). Use the patching script instead:

```bash
# Compile + patch for .github repo runtime-import bug
bash scripts/compile-org-monitor.sh
```

### gh-aw Frontmatter Rules

- `permissions:` block is **read-only** — write operations go through `safe-outputs:`
- Event triggers (`issues`, `pull_request`, `issue_comment`) require `reaction: eyes`
- Schedule triggers (`schedule: daily`) do NOT need `reaction: eyes`
- `add-comment` safe-output defaults to `discussions:write` — add `discussions: false` unless needed
- `tools.github.app` requests ALL workflow-level permissions for the App token — the GitHub App must have every permission in the `permissions:` block
- Validate with `gh aw compile` before committing — it catches trigger errors, permission mismatches, and safe-output violations

### GitHub App (zircote-org-monitor)

Cross-repo MCP access uses a GitHub App. Required App permissions must match the workflow's `permissions:` block exactly. Credentials:
- `GH_APP_ID` — repository variable
- `GH_APP_PRIVATE_KEY` — repository secret
- `COPILOT_GITHUB_TOKEN` — fine-grained PAT with Copilot Requests: Read (account permission, not repo)

## Git Conventions

- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `perf:`, `test:`, `ci:`
- Keep commits atomic and focused
- Reference issues in commit messages when applicable

## Language Standards (for Templates)

| Language | Version | Package Manager | Linter/Formatter | Type Checker |
|----------|---------|-----------------|------------------|--------------|
| Python | 3.12+ | uv | ruff | pyright |
| TypeScript | Node 22+ | pnpm | ESLint 9+ | strict tsc |
| Go | 1.23+ | modules | golangci-lint | built-in |
| Rust | stable | cargo | clippy | built-in |
| Java | 21 LTS | Gradle | Checkstyle | - |
