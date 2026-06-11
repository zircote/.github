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
| Attested Delivery      | Signed, SLSA-attested, verified releases   | `.github/workflows/` |

## Repository Structure

```text
.github/
├── .github/
│   ├── workflows/               # Reusable workflows
│   │   ├── reusable-ci-python.yml
│   │   ├── reusable-ci-typescript.yml
│   │   ├── reusable-ci-go.yml
│   │   ├── reusable-release.yml
│   │   ├── reusable-security.yml
│   │   ├── reusable-docs.yml
│   │   ├── reusable-presentation.yml
│   │   ├── reusable-content.yml
│   │   ├── reusable-dependabot-automerge.yml
│   │   ├── sync-labels.yml
│   │   ├── build-attest.yml         # Attested delivery (see CLAUDE.md)
│   │   ├── sign-and-attest.yml
│   │   ├── verify-attestation.yml
│   │   ├── promote.yml / promote-prod.yml
│   │   ├── sbom-and-scan.yml / pin-check.yml
│   │   └── mirror-images.yml / dora-emit.yml
│   ├── skills/                  # Copilot Skills
│   │   ├── template-creation/
│   │   ├── workflow-development/
│   │   ├── security-baseline/
│   │   ├── content-pipeline/
│   │   ├── ecosystem-migration/
│   │   ├── ai-tuning/
│   │   ├── presentation-generation/
│   │   └── attested-delivery/
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
│   ├── copilot-tuner.md
│   └── profile-maintainer.md
├── docs/                        # Platform docs (Diátaxis) + presentations
├── scripts/                     # Automation scripts
├── profile/
│   └── README.md
├── labels.yml
├── SECURITY.md
├── CONTRIBUTING.md
└── FUNDING.yml
```

---

## Reusable Workflows

All `uses:` references must be pinned to a full 40-char commit SHA (enforced by
the `pin-check` required check) — never `@main` or version tags. Dependabot's
`github-actions` ecosystem keeps pins current.

### Python CI

```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-python.yml@2192c47863886d7a867b5042fb08de414f948f49 # main
    with:
      python-version: "3.12"
      coverage-threshold: 80
```

### TypeScript CI

```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-typescript.yml@2192c47863886d7a867b5042fb08de414f948f49 # main
    with:
      node-version: "22"
      coverage-threshold: 80
```

### Go CI

```yaml
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-go.yml@2192c47863886d7a867b5042fb08de414f948f49 # main
    with:
      go-version: "1.23"
      enable-build: true
```

### Security Scanning

```yaml
jobs:
  security:
    uses: zircote/.github/.github/workflows/reusable-security.yml@2192c47863886d7a867b5042fb08de414f948f49 # main
    with:
      python-audit: true
      fail-on-vulnerabilities: true
```

### Release Automation

```yaml
jobs:
  release:
    uses: zircote/.github/.github/workflows/reusable-release.yml@2192c47863886d7a867b5042fb08de414f948f49 # main
    with:
      release-type: auto  # or patch, minor, major
      generate-notes: true
```

### Documentation Deployment

```yaml
jobs:
  docs:
    uses: zircote/.github/.github/workflows/reusable-docs.yml@2192c47863886d7a867b5042fb08de414f948f49 # main
    with:
      framework: astro  # or mkdocs, sphinx, docusaurus
      deploy-to-pages: true
```

### Attested Delivery

Containers are delivered through a single, caller-immutable
signing/verify/promote authority: a digest reaches consumers only if it is
**byte-identical** to what was validated, carries **attestations** (SLSA
provenance, keyless signature, CycloneDX SBOM, vulnerability report) that
re-verify at every hop as OCI referrers, and publication is gated on
**fail-closed verification**. Signing runs in `sign-and-attest.yml` — the
SLSA Build L3 isolation boundary the calling repo cannot modify.

| Workflow | Role |
| --- | --- |
| `build-attest.yml` | Build → push by digest → sign/attest → self-verify (single entry point) |
| `sign-and-attest.yml` | The L3 signing boundary: provenance + signature + SBOM + vuln report |
| `verify-attestation.yml` | Fail-closed verification gate before any publish or deploy |
| `promote.yml` / `promote-prod.yml` | Referrer-carrying digest promotion (+ change-record gate) |
| `sbom-and-scan.yml` | Standalone CycloneDX/SPDX SBOM + Grype scan |
| `pin-check.yml` | Full-SHA action pin enforcement (required check on this repo) |
| `dora-emit.yml` / `mirror-images.yml` | DORA deployment events / controlled upstream image ingress |

Documentation, organized by [Diátaxis](https://diataxis.fr/) in [`docs/`](docs/README.md):

| Need | Start here |
| --- | --- |
| Learn it hands-on | [Tutorial: your first attested release](docs/tutorials/first-attested-release.md) |
| Onboard a repo | [How-to: onboard a repo to attested delivery](docs/how-to/onboard-a-repo-to-attested-delivery.md) |
| Look up inputs/outputs | [Reference: attested-delivery workflows](docs/reference/workflows.md) |
| Understand the design | [Explanation: why attested delivery](docs/explanation/attested-delivery.md) |
| Verify a release | [SECURITY.md — Verifying Release Artifacts](SECURITY.md#verifying-release-artifacts) |
| Automate onboarding with an agent | [attested-delivery skill](.github/skills/attested-delivery/SKILL.md) |

---

## Composite Actions

### setup-python-uv

```yaml
- uses: zircote/.github/actions/setup-python-uv@2192c47863886d7a867b5042fb08de414f948f49 # main
  with:
    python-version: "3.12"
    install-dependencies: true
```

### setup-node-pnpm

```yaml
- uses: zircote/.github/actions/setup-node-pnpm@2192c47863886d7a867b5042fb08de414f948f49 # main
  with:
    node-version: "22"
    install-dependencies: true
```

### security-scan

```yaml
- uses: zircote/.github/actions/security-scan@2192c47863886d7a867b5042fb08de414f948f49 # main
  with:
    scan-secrets: true
    scan-dependencies: true
    language: python  # or javascript, go, rust
```

### release-notes

```yaml
- uses: zircote/.github/actions/release-notes@2192c47863886d7a867b5042fb08de414f948f49 # main
  with:
    from-tag: v1.0.0
    include-contributors: true
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

| Skill                    | Trigger                    | Purpose                                |
| ------------------------ | -------------------------- | -------------------------------------- |
| `template-creation`      | "create template for..."   | Design project templates               |
| `workflow-development`   | "create workflow for..."   | Build GitHub Actions workflows         |
| `security-baseline`      | "security check", "audit"  | Security scanning and remediation      |
| `content-pipeline`       | "write blog post"          | Content creation and publishing        |
| `ecosystem-migration`    | "migrate to ecosystem"     | Onboard projects to standards          |
| `ai-tuning`              | "tune AI instructions"     | Optimize CLAUDE.md/Copilot config      |
| `presentation-generation`| "create presentation"      | Generate slide decks from markdown     |

### Autonomous Agents

| Agent                | Capabilities                                                   |
| -------------------- | -------------------------------------------------------------- |
| `template-architect` | Analyze requirements, design and create project structures     |
| `workflow-engineer`  | Build CI/CD pipelines, optimize workflows, debug actions       |
| `security-auditor`   | Security review, vulnerability detection and remediation       |
| `content-strategist` | Content planning, SEO optimization, multi-platform publishing  |
| `ecosystem-migrator` | Project onboarding, dependency updates, standards compliance   |
| `copilot-tuner`      | Optimize AI assistant configurations for specific domains      |
| `profile-maintainer` | Automated profile README updates, GitHub activity tracking     |

---

## Related Repositories

### Project Templates

| Template                                                   | Stack                           |
| ----------------------------------------------------------- | ------------------------------- |
| `python-template` (private)                                 | Python 3.12+, uv, ruff, pyright |
| `typescript-template` (private)                             | Node 22, pnpm, ESLint 9, Vitest |
| `go-template` (private)                                     | Go 1.23+, golangci-lint         |
| [rust-template](https://github.com/zircote/rust-template)   | Stable, clippy, cargo-deny      |
| `java-template` (private)                                   | Java 21, Gradle, JUnit 5        |
| `docs-site-template` (private)                              | Astro, Starlight, MDX           |

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

## Version History

Recent updates to this organization configuration:

| Date | Change | Impact |
|------|--------|--------|
| 2026-06 | Attested delivery architecture | Signed, SLSA-attested, fail-closed-verified releases + pin-check CI gate |
| 2026-01 | Added presentation-generation skill | New slide deck generation from markdown |
| 2026-01 | Added profile-maintainer agent | Automated profile README updates |
| 2025-12 | Initial ecosystem setup | Reusable workflows, templates, AI integration |

For detailed history, see the [CHANGELOG](CHANGELOG.md) and [commit log](https://github.com/zircote/.github/commits/main).

## License

[MIT License](LICENSE).
