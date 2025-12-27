# zircote/.github

Organization-wide GitHub configuration, reusable workflows, and AI assistant integrations for my repositories.

## Overview

This repository provides shared infrastructure across all `zircote/*` repos:

| Component              | Purpose                                    | Location             |
| ---------------------- | ------------------------------------------ | -------------------- |
| Community Health Files | Default SECURITY.md, CONTRIBUTING.md       | Root directory       |
| Organization Profile   | Public profile at github.com/zircote       | `profile/README.md`  |
| Reusable Workflows     | CI/CD pipelines callable from any repo     | `.github/workflows/` |
| Composite Actions      | Shared action building blocks              | `actions/`           |
| Label Definitions      | Standardized issue/PR labels               | `labels.yml`         |
| Copilot Skills         | AI-assisted development capabilities       | `.github/skills/`    |
| Autonomous Agents      | Multi-step AI workflow automation          | `agents/`            |

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
│   │   └── sync-labels.yml
│   ├── skills/                  # Copilot Skills
│   │   ├── template-creation/
│   │   ├── workflow-development/
│   │   ├── security-baseline/
│   │   ├── content-pipeline/
│   │   ├── ecosystem-migration/
│   │   └── ai-tuning/
│   └── copilot-instructions.md
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
│   └── README.md
├── labels.yml
├── SECURITY.md
├── CONTRIBUTING.md
└── FUNDING.yml
```

---

## Reusable Workflows

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

---

## Composite Actions

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

---

## Label Sync

Standardized labels maintained via `sync-labels.yml`:

| Category     | Labels                                                                           |
| ------------ | -------------------------------------------------------------------------------- |
| **Priority** | `priority: critical`, `priority: high`, `priority: medium`, `priority: low`      |
| **Type**     | `type: bug`, `type: feature`, `type: enhancement`, `type: docs`, `type: security`|
| **Status**   | `status: blocked`, `status: in-progress`, `status: needs-review`, `status: ready`|
| **Area**     | `area: ci-cd`, `area: testing`, `area: infrastructure`, `area: dependencies`     |
| **Effort**   | `effort: small`, `effort: medium`, `effort: large`, `effort: epic`               |

```bash
# Sync labels to a repo
gh workflow run sync-labels.yml -f repo=zircote/my-repo
```

---

## AI Integration

### Copilot Skills

| Skill                  | Trigger                    | Purpose                                |
| ---------------------- | -------------------------- | -------------------------------------- |
| `template-creation`    | "create template for..."   | Design project templates               |
| `workflow-development` | "create workflow for..."   | Build GitHub Actions workflows         |
| `security-baseline`    | "security check", "audit"  | Security scanning and remediation      |
| `content-pipeline`     | "write blog post"          | Content creation and publishing        |
| `ecosystem-migration`  | "migrate to ecosystem"     | Onboard projects to standards          |
| `ai-tuning`            | "tune AI instructions"     | Optimize CLAUDE.md/Copilot config      |

### Autonomous Agents

| Agent                | Capabilities                                                   |
| -------------------- | -------------------------------------------------------------- |
| `template-architect` | Analyze requirements, design and create project structures     |
| `workflow-engineer`  | Build CI/CD pipelines, optimize workflows, debug actions       |
| `security-auditor`   | Security review, vulnerability detection and remediation       |
| `content-strategist` | Content planning, SEO optimization, multi-platform publishing  |
| `ecosystem-migrator` | Project onboarding, dependency updates, standards compliance   |
| `copilot-tuner`      | Optimize AI assistant configurations for specific domains      |

---

## Related Repositories

### Project Templates

| Template                                                           | Stack                           |
| ------------------------------------------------------------------ | ------------------------------- |
| [python-template](https://github.com/zircote/python-template)      | Python 3.12+, uv, ruff, pyright |
| [typescript-template](https://github.com/zircote/typescript-template) | Node 22, pnpm, ESLint 9, Vitest |
| [go-template](https://github.com/zircote/go-template)              | Go 1.23+, golangci-lint         |
| [rust-template](https://github.com/zircote/rust-template)          | Stable, clippy, cargo-deny      |
| [java-template](https://github.com/zircote/java-template)          | Java 21, Gradle, JUnit 5        |
| [docs-site-template](https://github.com/zircote/docs-site-template)| Astro, Starlight, MDX           |

### Tools & Plugins

| Repository                                                            | Purpose                                    |
| --------------------------------------------------------------------- | ------------------------------------------ |
| [swagger-php](https://github.com/zircote/swagger-php)                 | OpenAPI documentation from PHP annotations |
| [git-adr](https://github.com/zircote/git-adr)                         | Architecture Decision Records in git notes |
| [git-notes-memory](https://github.com/zircote/git-notes-memory)       | Semantic memory storage for Claude Code    |
| [claude-spec](https://github.com/zircote/claude-spec)                 | Project specification & lifecycle plugin   |
| [.claude](https://github.com/zircote/.claude)                         | Claude Code dotfiles: agents, skills, commands |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on pull requests, coding standards, and review process.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting and supported versions.

## License

MIT License - See individual files for specific licensing.
