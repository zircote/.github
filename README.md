# Organization GitHub Configuration

This repository contains organization-wide GitHub configuration, reusable workflows, composite actions, and AI assistant integrations for the **zircote** ecosystem.

## What This Repository Provides

When you create this as `zircote/.github`, GitHub automatically applies these configurations across all repositories in the organization:

| Component | Purpose | Location |
|-----------|---------|----------|
| **Community Health Files** | Default SECURITY.md, CONTRIBUTING.md for all repos | Root directory |
| **Organization Profile** | Public profile shown on github.com/zircote | `profile/README.md` |
| **Reusable Workflows** | Callable CI/CD workflows for all repos | `.github/workflows/` |
| **Composite Actions** | Shared action building blocks | `actions/` |
| **Label Definitions** | Standardized issue/PR labels | `labels.yml` |
| **Copilot Skills** | AI-assisted development capabilities | `.github/skills/` |
| **Autonomous Agents** | Multi-step AI workflow automation | `agents/` |

## Repository Structure

```
.github/
├── .github/
│   ├── workflows/               # Reusable workflows
│   │   ├── reusable-ci-python.yml
│   │   ├── reusable-ci-typescript.yml
│   │   ├── reusable-ci-go.yml
│   │   ├── reusable-release.yml
│   │   ├── reusable-security.yml
│   │   ├── reusable-docs.yml
│   │   ├── reusable-content.yml
│   │   └── sync-labels.yml
│   ├── skills/                  # Copilot Skills (Dec 2025+)
│   │   ├── template-creation/
│   │   ├── workflow-development/
│   │   ├── security-baseline/
│   │   ├── content-pipeline/
│   │   ├── ecosystem-migration/
│   │   └── ai-tuning/
│   └── copilot-instructions.md  # Organization-wide Copilot context
├── actions/                     # Composite Actions
│   ├── setup-python-uv/
│   ├── setup-node-pnpm/
│   ├── release-notes/
│   └── security-scan/
├── agents/                      # Autonomous Agents
│   ├── template-architect.md
│   ├── workflow-engineer.md
│   ├── security-auditor.md
│   ├── content-strategist.md
│   ├── ecosystem-migrator.md
│   └── copilot-tuner.md
├── profile/
│   └── README.md                # Organization profile
├── labels.yml                   # Standard label definitions
├── SECURITY.md                  # Security policy
├── CONTRIBUTING.md              # Contribution guidelines
├── FUNDING.yml                  # Sponsorship configuration
└── README.md                    # This file
```

## Reusable Workflows

Call these workflows from any repository in the organization:

### Python CI

```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-python.yml@main
    with:
      python-version: "3.12"
      run-tests: true
      coverage-threshold: 80
```

### TypeScript CI

```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-typescript.yml@main
    with:
      node-version: "22"
      run-tests: true
```

### Go CI

```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-go.yml@main
    with:
      go-version: "1.23"
      run-race-detector: true
```

### Security Scanning

```yaml
jobs:
  security:
    uses: zircote/.github/.github/workflows/reusable-security.yml@main
    with:
      scan-secrets: true
      scan-dependencies: true
```

### Release Automation

```yaml
jobs:
  release:
    uses: zircote/.github/.github/workflows/reusable-release.yml@main
    with:
      generate-changelog: true
```

### Documentation Deployment

```yaml
jobs:
  docs:
    uses: zircote/.github/.github/workflows/reusable-docs.yml@main
    with:
      framework: astro  # or mkdocs, sphinx, docusaurus
      deploy-to-pages: true
```

## Composite Actions

Use these actions in your workflow steps:

### setup-python-uv

```yaml
- uses: zircote/.github/actions/setup-python-uv@main
  with:
    python-version: "3.12"
    cache: true
```

### setup-node-pnpm

```yaml
- uses: zircote/.github/actions/setup-node-pnpm@main
  with:
    node-version: "22"
    cache: true
```

### security-scan

```yaml
- uses: zircote/.github/actions/security-scan@main
  with:
    scan-secrets: true
    scan-dependencies: true
    language: python  # or javascript, go, rust
```

### release-notes

```yaml
- uses: zircote/.github/actions/release-notes@main
  with:
    version: ${{ github.ref_name }}
    output-file: CHANGELOG.md
```

## Label Sync

The `sync-labels.yml` workflow maintains consistent labels across repositories.

### Available Labels

| Category | Labels |
|----------|--------|
| **Priority** | `priority: critical`, `priority: high`, `priority: medium`, `priority: low` |
| **Type** | `type: bug`, `type: feature`, `type: enhancement`, `type: docs`, `type: security`, `type: performance` |
| **Status** | `status: blocked`, `status: in-progress`, `status: needs-review`, `status: ready` |
| **Area** | `area: ci-cd`, `area: testing`, `area: infrastructure`, `area: dependencies` |
| **Effort** | `effort: small`, `effort: medium`, `effort: large`, `effort: epic` |

### Manual Sync

```bash
# Sync labels to a specific repo
gh workflow run sync-labels.yml -f repo=zircote/my-repo

# Sync to all repos (requires LABELS_TOKEN secret with repo scope)
gh workflow run sync-labels.yml -f sync-all=true
```

## AI Assistant Integration

### Copilot Skills

Skills provide focused capabilities for GitHub Copilot:

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `template-creation` | "create template for..." | Design and customize project templates |
| `workflow-development` | "create workflow for..." | Build GitHub Actions workflows |
| `security-baseline` | "security check", "audit" | Security scanning and remediation |
| `content-pipeline` | "write blog post", "create content" | Content creation and publishing |
| `ecosystem-migration` | "migrate to ecosystem" | Onboard projects to standards |
| `ai-tuning` | "tune AI instructions" | Optimize CLAUDE.md and Copilot instructions |

### Autonomous Agents

Agents handle complex, multi-step workflows:

| Agent | Capabilities |
|-------|-------------|
| `template-architect` | Analyze requirements, design templates, create complete project structures |
| `workflow-engineer` | Build CI/CD pipelines, optimize workflows, debug actions |
| `security-auditor` | Comprehensive security review, vulnerability remediation |
| `content-strategist` | Content calendar planning, SEO optimization, multi-platform publishing |
| `ecosystem-migrator` | Project onboarding, dependency updates, standards compliance |
| `copilot-tuner` | Optimize AI assistant configurations for specific domains |

## Security Policy

The `SECURITY.md` file defines:
- Supported versions
- Vulnerability reporting process
- Security update timeline
- Responsible disclosure guidelines

## Contributing

See `CONTRIBUTING.md` for:
- Code of conduct
- Pull request process
- Coding standards
- Review requirements

## Setup for New Organizations

To use this configuration for your organization:

```bash
# Clone the ecosystem repository
git clone https://github.com/zircote/github.git
cd github

# Deploy to your organization
./scripts/deploy-ecosystem.sh your-org-name

# Or just the .github repo
./scripts/setup-org.sh your-org-name
```

## Customization

### Adding New Workflows

1. Create workflow in `.github/workflows/`
2. Use `workflow_call` trigger for reusability
3. Document inputs and secrets in workflow comments
4. Add usage example to this README

### Adding New Actions

1. Create directory in `actions/`
2. Add `action.yml` with inputs, outputs, and steps
3. Test in a repository before merging
4. Document in this README

### Modifying Labels

1. Edit `labels.yml`
2. Run sync workflow to apply changes
3. Labels are additive (won't delete existing labels)

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [python-template](https://github.com/zircote/python-template) | Python project template |
| [typescript-template](https://github.com/zircote/typescript-template) | TypeScript project template |
| [go-template](https://github.com/zircote/go-template) | Go project template |
| [rust-template](https://github.com/zircote/rust-template) | Rust project template |
| [java-template](https://github.com/zircote/java-template) | Java/Spring Boot template |
| [data-science-template](https://github.com/zircote/data-science-template) | Data science template |
| [docs-site-template](https://github.com/zircote/docs-site-template) | Documentation site template |
| [content-pipeline-template](https://github.com/zircote/content-pipeline-template) | Content workflow template |
| [devcontainer-template](https://github.com/zircote/devcontainer-template) | DevContainer template |
| [video-template](https://github.com/zircote/video-template) | Video production template |

## License

MIT License - See individual files for specific licensing.
