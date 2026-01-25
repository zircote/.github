# zircote

```text
 _______               _
|__   (_)             | |
   / / _ ____ ___ ___ | |_ ___
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

## Active Projects

<!-- LAST_UPDATED_START -->
 __Last updated: 2026-01-25__
<!-- LAST_UPDATED_END -->

### Most Active Repositories

Ranked by recent contributions, community engagement, and development activity.

<!-- ACTIVE_REPOS_START -->
| Repository | Description | Tech | Activity |
|------------|-------------|------|----------|
| [swagger-php](https://github.com/zircote/swagger-php) | A php swagger annotation and parsing library | PHP | ✨ Active |
| [subcog](https://github.com/zircote/subcog) | Persistent memory system for AI coding assistants. Captures ... | Rust | ✨ Active |
| [sdlc-quality](https://github.com/zircote/sdlc-quality) | Software Development Lifecycle standards plugin for AI codin... | Shell | 📈 Growing |
| [mnemonic](https://github.com/zircote/mnemonic) | Persistent filesystem-based memory system for Claude Code. P... | Python | 📈 Growing |
| [homebrew-tap](https://github.com/zircote/homebrew-tap) | Homebrew formula for git-adr - Architecture Decision Records... | Ruby | 📈 Growing |
| [rlm-rs](https://github.com/zircote/rlm-rs) | Rust CLI implementing the Recursive Language Model (RLM) pat... | Rust | 📈 Growing |
| [sigint](https://github.com/zircote/sigint) | Market intelligence toolkit for Claude Code. Iterative resea... | Unknown | 📈 Growing |
| [rlm-rs-plugin](https://github.com/zircote/rlm-rs-plugin) | Claude Code plugin for processing documents 100x larger than... | Unknown | 📈 Growing |
<!-- ACTIVE_REPOS_END -->

### Recently Created

<!-- NEW_REPOS_START -->
- **[mnemonic](https://github.com/zircote/mnemonic)** (Python) - Persistent filesystem-based memory system for Claude Code. Pure MIF Level 3 comp...
- **[MIF](https://github.com/zircote/MIF)** (Unknown) - Open standard for portable AI memory interchange. JSON-LD + Markdown dual format...
- **[sigint](https://github.com/zircote/sigint)** (Unknown) - Market intelligence toolkit for Claude Code. Iterative research workflows, trend...
- **[auto-harness](https://github.com/zircote/auto-harness)** (Shell) - Hook-driven test framework for Claude Code plugins - automates integration testi...
- **[oolong-pairs](https://github.com/zircote/oolong-pairs)** (Python) - Benchmark harness for A/B testing Claude Code plugins against OOLONG long-contex...
<!-- NEW_REPOS_END -->

---

## Claude Code Ecosystem

I maintain a comprehensive ecosystem of Claude Code extensions for AI-assisted development:

### Plugins

- **[marketplace](https://github.com/zircote/marketplace)** - Claude Plugin Marketplace listing Claude Code plugins
- **[lsp-marketplace](https://github.com/zircote/lsp-marketplace)** - Curated marketplace of 28 LSP-enabled Claude Code plugins with strong enforcement patterns
- **[subcog](https://github.com/zircote/subcog)** - Semantic memory with vector search and RRF retrieval
- **[documentation-management](https://github.com/zircote/marketplace?tab=readme-ov-file#documentation-review---documentation-management)** - Plugin for managing architecture docs, ADRs, decision tracking
- **[adr-lifecycle-management](https://github.com/zircote/marketplace?tab=readme-ov-file#adr---adr-lifecycle-management)** - Plugin for creating, updating, and tracking ADRs

### Agent Library

The [marketplace](https://github.com/zircote/marketplace) repository contains 100+ specialized agents organized by domain:

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

```text
Languages        PHP | Python | TypeScript | Go | Rust
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
