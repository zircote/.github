# zircote

```
 _______ _             _
|__   (_) |           | |
   / / _ _ __ ___ ___ | |_ ___
  / / | | '__/ __/ _ \| __/ _ \
 / /__| | | | (_| (_) | ||  __/
/_____|_|_|  \___\___/ \__\___|
```

> Building practical open source tools that improve developer workflows

## About

**Robert Allen** is a DevOps engineer, technologist and open source maintainer based in Farmville, Virginia. By day, he drives infrastructure automation at [HMH](https://www.hmhco.com/). By evening, he builds developer tools that solve real problems in technology and agriculture. And somehow also runs a [regenerative pasture farm](https://epicpastures.com/).

Creator of **[swagger-php](https://github.com/zircote/swagger-php)** (5K+ stars), the PHP library for generating OpenAPI documentation from annotations. Much appreciation to the community of contributors and users who have made it a success over the years.

### Focus Areas

- **Open Source Tooling** - Creating and maintaining tools that developers actually use
- **AI-Assisted Development** - Building Claude Code plugins, agents, and workflows
- **DevOps & Platform Engineering** - Infrastructure automation, CI/CD, AWS architecture
- **Architecture Documentation** - ADRs, decision tracking, knowledge capture

---

## Featured Projects

| Project                                                         | Description                                         | Tech   |
| --------------------------------------------------------------- | --------------------------------------------------- | ------ |
| [swagger-php](https://github.com/zircote/swagger-php)           | OpenAPI/Swagger documentation from PHP annotations  | PHP    |
| [git-adr](https://github.com/zircote/git-adr)                   | Architecture Decision Records in git notes          | Python |
| [git-notes-memory](https://github.com/zircote/git-notes-memory) | Semantic memory storage for Claude Code             | Python |
| [claude-spec](https://github.com/zircote/claude-spec)           | Project specification & lifecycle management plugin | Python |
| [.claude](https://github.com/zircote/.claude)                   | Claude Code dotfiles: agents, skills, commands      | Python |

---

## Claude Code Ecosystem

I maintain a comprehensive ecosystem of Claude Code extensions for AI-assisted development:

### Plugins

- **[claude-spec](https://github.com/zircote/claude-spec)** - Socratic project planning with implementation tracking
- **[git-notes-memory](https://github.com/zircote/git-notes-memory)** - Git-native semantic memory with vector search

### Agent Library

The [.claude](https://github.com/zircote/.claude) repository contains 100+ specialized agents organized by domain:

| Category             | Agents                                                  |
| -------------------- | ------------------------------------------------------- |
| Core Development     | frontend, backend, fullstack, API design, microservices |
| Language Specialists | Python, TypeScript, Go, Rust, Java, PHP                 |
| Infrastructure       | DevOps, SRE, Kubernetes, Terraform, cloud architecture  |
| Quality & Security   | code review, security audit, testing, performance       |
| Data & AI            | ML engineering, data science, LLM architecture          |

---

## GitHub Ecosystem

This account uses standardized templates and automation for consistency across repositories.

### Project Templates

| Template                                                     | Stack                           |
| ------------------------------------------------------------ | ------------------------------- |
| [python](https://github.com/zircote/python-template)         | Python 3.12+, uv, ruff, pyright |
| [typescript](https://github.com/zircote/typescript-template) | Node 22, pnpm, ESLint 9, Vitest |
| [go](https://github.com/zircote/go-template)                 | Go 1.23+, golangci-lint         |
| [rust](https://github.com/zircote/rust-template)             | Stable, clippy, cargo-deny      |
| [docs-site](https://github.com/zircote/docs-site-template)   | Astro, Starlight, MDX           |

### Reusable Workflows

```yaml
# Use in any repository
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-python.yml@main
```

---

## Technology Stack

```
Languages        PHP | Python | TypeScript | Go
Infrastructure   AWS | Docker | Kubernetes | Terraform | GitHub Actions
AI Integration   Claude Code | GitHub Copilot | MCP Protocol
Platforms        Linux | macOS | AWS (Solutions Architect certified)
```

---

## Principles

1. **Developer Experience First** - Tools should reduce friction, not add it
2. **Automation Over Documentation** - Encode knowledge in code
3. **Open by Default** - Share solutions that might help others
4. **Practical Over Perfect** - Ship working software, iterate based on usage

---

## Connect

[![Blog](https://img.shields.io/badge/Blog-zircote.com-FF5722?logo=hashnode&logoColor=white)](https://zircote.github.io/)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-zircote-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/zircote/)
[![GitHub](https://img.shields.io/badge/GitHub-zircote-181717?logo=github&logoColor=white)](https://github.com/zircote)

- **GitHub Issues** - For project-specific discussions
- **Pull Requests** - The best way to propose changes

---

<sub>
Building in the open | [View Ecosystem](https://github.com/zircote/github)
</sub>
