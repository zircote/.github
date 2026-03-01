# Copilot Instructions - zircote/.github

> Repository-specific guidance for AI agents working on organization-wide GitHub infrastructure

## Repository Purpose

This is the **zircote organization template** providing shared infrastructure across all zircote/* repositories:
- Reusable GitHub Actions workflows (via `workflow_call`)
- Composite actions for consistent environment setup
- Autonomous agent definitions for multi-step AI workflows
- Copilot skills for guided AI-assisted development
- Community health files and standardized issue labels
- Profile documentation and automation scripts

## Key Architectural Patterns

### Workflow Reusability

All workflows in `.github/workflows/` use `workflow_call` to be invoked from other repositories:

```yaml
# Consumer repo calls the reusable workflow
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-python.yml@main
    with:
      python-version: '3.12'
      coverage-threshold: 80
```

**Important:** Reusable workflows must declare minimal permissions and use SHA-pinned action references.

### Composite Actions Pattern

Actions in `actions/*/` are building blocks for workflows with standardized input/output contracts:

- `setup-python-uv`: Python + uv with caching (inputs: `python-version`, `install-dependencies`, `extras`)
- `setup-node-pnpm`: Node.js + pnpm with caching (inputs: `node-version`, `frozen-lockfile`)
- `security-scan`: Gitleaks + dependency scanning
- `release-notes`: Generate changelogs from conventional commits

All actions must include `outputs` for downstream usage and `branding` for VS Code integration.

### Agent Definition Format

Agents in `agents/` use YAML frontmatter with embedded instructions:

```markdown
---
name: agent-name
description: Clear action description
tools:
  - Read
  - Write
  - Bash
model: sonnet
---

# Agent Name

System prompt and detailed instructions...
```

Agents represent autonomous workflows that consume multiple tools. Examples: `template-architect.md`, `workflow-engineer.md`, `security-auditor.md`.

### Label Synchronization

`labels.yml` defines standardized labels for all org repos. Sync with:

```bash
npx github-label-sync --access-token $GITHUB_TOKEN --labels labels.yml zircote/repo-name
```

Labels are grouped by category: priority (critical/high/medium/low), type (bug/feature/enhancement), status, and area.

## Critical Security Requirements

1. **SHA-Pinned Actions**: All GitHub Actions references must use full commit SHA with version comment:
   ```yaml
   - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
   ```

2. **Minimal Permissions**: Every workflow declares `permissions:` explicitly:
   ```yaml
   permissions:
     contents: read
     packages: write
   ```

3. **No Secrets in Templates**: Use `${{ secrets.VARIABLE }}` and document required secrets in action/workflow descriptions.

## File Organization Rules

| Directory | Purpose | Key Pattern |
|-----------|---------|-----------|
| `.github/workflows/` | Reusable workflows | Must use `workflow_call` trigger |
| `actions/*/` | Composite actions | YAML + shell scripts, include outputs |
| `agents/` | Autonomous agents | Markdown with YAML frontmatter |
| `scripts/` | Python/JS automation | Type hints required, extensive docstrings |
| `profile/` | Organization profile | Dynamically generated from org activity |
| `docs/presentations/` | Slide deck generation | Python generators with multiple output formats |

## Development Workflows

### Adding a New Composite Action

1. Create `actions/action-name/action.yml` with clear inputs/outputs
2. Include branding configuration for VS Code display
3. Add usage examples in the action description
4. Document all inputs with descriptions, defaults, and whether required

### Adding a New Reusable Workflow

1. Create `.github/workflows/reusable-*.yml` with `on: workflow_call`
2. Define `inputs:` and `outputs:` sections (no secrets in inputs)
3. Use composite actions from this repo where applicable
4. Specify minimum `permissions:` required
5. Add to the README.md table with key inputs/outputs

### Adding a New Agent

1. Create `agents/agent-name.md` with YAML frontmatter
2. Include `tools:` array (only use available tools)
3. Model should be `sonnet` (preferred) or `haiku` for lighter tasks
4. Write detailed system prompt explaining agent's role and constraints
5. Include specific examples or patterns relevant to the agent's domain

## Automation Scripts Convention

Scripts in `scripts/` use modern Python (3.12+) with:

- Type annotations on all functions
- Docstring explaining purpose and weighting/calculation logic
- Dataclass for complex data structures
- Clear error handling with informative messages
- CLI argument parsing with argparse
- Environment variable usage for GitHub API tokens

Example from `analyze-github-activity.py`:
```python
"""Analyze GitHub public activity for profile README generation."""

@dataclass
class RepoScore:
    """Repository with calculated significance score."""
    name: str
    stars: int
    # Weighting factors in docstring, not code comments
```

## When Generating New Code

1. **Match existing patterns**: Study similar files (e.g., other composite actions, workflows, agents)
2. **Include comments for "why"**: Explain design decisions, not implementation details
3. **Use consistent naming**: Follow kebab-case for GitHub Actions, snake_case for Python scripts
4. **Document outputs clearly**: If it's a reusable component, make its interface explicit
5. **Consider org-wide consumption**: Code here affects many downstream repos - test thoroughly

## Common Editing Tasks

**Adding a new reusable workflow**: Base from existing similar workflow in `.github/workflows/`, use `workflow_call` trigger, add to README.md table

**Modifying agent instructions**: Preserve YAML frontmatter, update the markdown system prompt and examples

**Updating composite actions**: Maintain backward compatibility of inputs/outputs, document breaking changes

**Syncing labels to repos**: Use `github-label-sync` CLI or GitHub Actions with the centralized `labels.yml`
