<p align="center">
  <img src="https://raw.githubusercontent.com/zircote/.github/main/profile/zircote-banner.svg" alt="zircote" width="800">
</p>

<p align="center">
  <a href="https://github.com/zircote"><img src="https://img.shields.io/github/followers/zircote?style=for-the-badge&logo=github&logoColor=white&label=Followers&color=181717" alt="GitHub Followers"></a>
  <a href="https://github.com/zircote?tab=repositories"><img src="https://img.shields.io/badge/dynamic/json?style=for-the-badge&logo=github&logoColor=white&label=Public%20Repos&query=public_repos&url=https://api.github.com/users/zircote&color=238636" alt="Public Repos"></a>
  <a href="https://github.com/zircote/swagger-php"><img src="https://img.shields.io/github/stars/zircote/swagger-php?style=for-the-badge&logo=github&logoColor=white&label=swagger-php&color=e3b341" alt="swagger-php Stars"></a>
</p>

<p align="center">
  <a href="https://www.linkedin.com/in/zircote/"><img src="https://img.shields.io/badge/LinkedIn-zircote-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"></a>
  <a href="https://zircote.github.io/"><img src="https://img.shields.io/badge/Blog-zircote.com-FF5722?style=for-the-badge&logo=hashnode&logoColor=white" alt="Blog"></a>

</p>

---

## About

**Robert Allen** is a Systems/Platform engineer, technologist, open source maintainer and sheep and poultry farmer based in Farmville, Virginia. By day, he drives infrastructure automation at [HMH](https://www.hmhco.com/). By evening, he builds developer tools that solve real problems in technology and agriculture. And somehow also runs a [regenerative pasture farm](https://epicpastures.com/).

Creator of **[swagger-php](https://github.com/zircote/swagger-php)**, the PHP library for generating OpenAPI documentation from annotations. Much appreciation to the community of contributors and users who have made it a success over the years.

### Focus Areas

- **Open Standards for AI Tooling** - Authoring specifications that make AI development portable and interoperable
- **AI-Assisted Development** - Building Claude Code plugins, agents, and workflows
- **DevOps & Platform Engineering** - Infrastructure automation, CI/CD, AWS architecture
- **Open Source Tooling** - Creating and maintaining tools that developers actually use

---

## Open Specifications

Two open specifications currently occupy the center of my development attention — both aimed at solving fragmentation in the AI coding assistant ecosystem.

### [Memory Interchange Format (MIF)](https://mif-spec.dev) — Portable AI Memory

<a href="https://mif-spec.dev"><img src="https://img.shields.io/badge/spec-mif--spec.dev-blue?style=for-the-badge" alt="mif-spec.dev"></a>

The AI memory ecosystem is fragmented — Mem0, Zep, Letta, LangMem, and others all use proprietary schemas with no interoperability. MIF defines a common data model with dual representations: human-readable **Markdown** files (Obsidian-compatible) and machine-processable **JSON-LD** documents.

MIF solves vendor lock-in, data ownership, and future-proofing for AI memory. Key features:

- **Dual format** — Lossless conversion between `.memory.md` and `.memory.json`
- **Three conformance levels** — Core (4 fields), Standard (+ namespaces, entities, relationships), Full (+ bi-temporal, decay, provenance, embeddings, citations)
- **Ontology system** — Semantic/episodic/procedural memory types with domain-extensible entity discovery
- **W3C PROV provenance** and **JSON Schema validation**
- **Migration guides** from Mem0, Zep, Letta, Subcog, and Basic Memory

**Status:** v0.1.0-draft &bull; [Specification](https://mif-spec.dev/SPECIFICATION) &bull; [GitHub](https://github.com/zircote/MIF)

### [ccpkg](https://ccpkg.dev) — Portable Packaging for AI Coding Extensions

<a href="https://ccpkg.dev"><img src="https://img.shields.io/badge/spec-ccpkg.dev-blue?style=for-the-badge" alt="ccpkg.dev"></a>

AI coding assistants are increasingly extensible, but sharing extensions is fragmented and fragile — Git-based installs break silently, startup latency scales with plugin count, and there are no trust signals or version pinning. ccpkg defines a self-contained archive format (`.ccpkg`) for packaging and distributing skills, agents, commands, hooks, MCP servers, and LSP servers as a single portable unit.

One file, one install, zero post-install steps. Key features:

- **Cross-tool portability** — Works across Claude Code, Gemini CLI, Codex, Copilot, and other compatible tools
- **Self-contained archives** — All dependencies vendored, no runtime network fetches
- **Lazy loading** — Only metadata loaded at startup; twenty packages have the same startup time as zero
- **Deterministic lockfiles** — `ccpkg-lock.json` pins exact versions with checksums for reproducible team environments
- **Decentralized registries** — JSON files hostable on GitHub Pages, S3, or any static server
- **Built on open standards** — Agent Skills, MCP, LSP, SemVer, JSON Schema

**Status:** Draft (2026-02-14) &bull; [Specification](https://ccpkg.dev/spec/specification.html) &bull; [GitHub](https://github.com/zircote/plugin-packaging)

---

## Memory, Ontology & AI

The intersection of cognitive science and AI systems presents a compelling question: **how do we build AI that remembers meaningfully?**

Human memory isn't a tape recorder—it's a constructive process where our mental models (ontology) shape what we encode, and our memories reshape how we understand the world. This recursive loop is central to how we learn, adapt, and make sense of novel situations.

![The Recursive Loop: How Memory and Ontology Shape Our Reality](https://raw.githubusercontent.com/zircote/.github/main/docs/_assets/memory-ontology-recursion.jpg)

The goal: AI assistants that don't just respond—they accumulate knowledge, recognize patterns, and evolve their understanding of your codebase and preferences. MIF grew directly from this research — encoding these cognitive principles into an interoperable specification.

---

## Featured Projects

### [mnemonic](https://github.com/zircote/mnemonic) — Persistent Memory for Claude Code

A pure filesystem-based memory system that gives Claude Code long-term memory across sessions. Memories are stored as markdown files with YAML frontmatter in a git-versioned directory, organized by cognitive type:

- **Semantic memory** — decisions, knowledge, entities
- **Episodic memory** — incidents, sessions, debugging journeys
- **Procedural memory** — runbooks, patterns, workflows

[MIF Level 3](https://github.com/zircote/MIF) compliant with ontology-driven entity discovery, bi-temporal tracking, memory decay, and relationship graphs. Research-validated on the Letta LoCoMo benchmark (74.0% accuracy vs 68.5% for graph-based approaches) — proving that LLMs work best with the filesystem operations they were pre-trained on.

Ships as a Claude Code plugin with 13 commands, 4 autonomous agents, and event-driven hooks that enable proactive recall and silent capture.

### [claude-team-orchestration](https://github.com/zircote/claude-team-orchestration) — Multi-Agent Orchestration & RLM

A production-grade framework for coordinating teams of Claude Code agents. Built on Claude Code's agent teams API, it provides team management, shared task lists, inter-agent messaging, and seven proven orchestration patterns — from parallel specialists to self-organizing swarms.

The standout capability is its **content-aware RLM (Recursive Language Model)** implementation based on [arXiv:2512.24601](https://arxiv.org/abs/2512.24601), which processes files and directories that exceed context limits:

- **Automatic content-type detection** — source code, CSV/TSV, JSON/JSONL, logs, prose
- **Semantic chunking** — respects function boundaries, preserves CSV headers, maintains valid JSON per partition
- **Specialized analyst agents** — code-aware, data-aware, JSON-aware, and general-purpose analyzers run on Haiku for cost efficiency
- **Multi-file directory analysis** — routes mixed content types to the right analysts, synthesizes findings across file types in two phases
- **Context protection** — findings written to task descriptions (pass-by-reference), keeping the leader's context under 2K characters even with 30 active analysts

Ships as a Claude Code plugin with 8 modular skills and 5 custom agent definitions.

### [nsip](https://github.com/zircote/nsip) — Sheep Genetic Evaluation CLI & MCP Server

A Rust CLI and Model Context Protocol server for the National Sheep Improvement Program database — 400,000+ animals with Estimated Breeding Values (EBVs), pedigrees, and performance data.

Beyond basic search and lookup, nsip provides breeding intelligence:

- **Inbreeding analysis** — Wright's coefficient of inbreeding with traffic-light risk classification
- **Weighted trait ranking** — custom breeding objective scoring with accuracy weighting
- **Mating recommendations** — optimal sire pairings ranked by trait complementarity and inbreeding risk
- **Flock summary** — aggregate genetics across a flock

The MCP server exposes 13 tools, 5 resources, 4 resource templates, and 7 guided prompts — enabling AI assistants to provide expert breeding advice through natural conversation. Published as a Docker image at `ghcr.io/zircote/nsip`.

### [nsip-example](https://github.com/zircote/nsip-example) — GitHub as a Farm Management System

A working demonstration of **GitHub4Farms** — using GitHub Issues as the record-keeping interface for a sheep operation, with automated genetic enrichment powered by the nsip MCP server and GitHub Copilot.

Farmers create issues for breeding events (mating, lambing, health, weaning, sales) using structured templates. A Copilot agent automatically enriches each record with genetic data: inbreeding risk assessment, EBV comparisons, predicted offspring traits, and breeding recommendations. Flock-wide analyses — ranking, mating optimization, inbreeding matrices — are generated as markdown reports via issue-triggered workflows.

Seven issue templates, eleven runbooks, and comprehensive user documentation make it accessible to farmers with no technical background.

---

## Active Projects

<!-- LAST_UPDATED_START -->
 __Last updated: 2026-03-01__
<!-- LAST_UPDATED_END -->

### Most Active Repositories

Ranked by recent contributions, community engagement, and development activity.

<!-- ACTIVE_REPOS_START -->
| Repository | Description | Tech | Activity |
|------------|-------------|------|----------|
| [swagger-php](https://github.com/zircote/swagger-php) | A php swagger annotation and parsing library | PHP | ✨ Active |
| [maker-rs](https://github.com/zircote/maker-rs) | Zero-error LLM execution via SPRT voting. Rust library and M... | Rust | 📈 Growing |
| [github4farms-training](https://github.com/zircote/github4farms-training) |  | Unknown | 📈 Growing |
| [github4farms](https://github.com/zircote/github4farms) | 12-session hands-on GitHub training curriculum for farmers —... | HTML | 📈 Growing |
| [.github](https://github.com/zircote/.github) | Organization shared workflows, policies, and community healt... | Python | 📈 Growing |
| [lsp-tools](https://github.com/zircote/lsp-tools) | LSP-first code intelligence for Claude Code with strong enfo... | Shell | 📈 Growing |
| [cpp-lsp](https://github.com/zircote/cpp-lsp) | Claude Code plugin for C/C++ development with clangd LSP, cl... | C++ | 📈 Growing |
| [csharp-lsp](https://github.com/zircote/csharp-lsp) | Claude Code plugin for C# development with OmniSharp LSP and... | C# | 📈 Growing |
<!-- ACTIVE_REPOS_END -->

### Recently Created

<!-- NEW_REPOS_START -->
- **[refactor](https://github.com/zircote/refactor)** (Unknown) - Swarm-orchestrated code refactoring plugin for Claude Code. Four AI agents itera...
- **[tone-police](https://github.com/zircote/tone-police)** (Python) - Your diplomatic bodyguard for the AI age. Claude Code plugin that silently filte...
- **[farm-notebook-examples](https://github.com/zircote/farm-notebook-examples)** (Jupyter Notebook) - Beginner-friendly Jupyter notebooks for farmers, ranchers & agronomists — soil h...
- **[github-agentic-workflows](https://github.com/zircote/github-agentic-workflows)** (Unknown) - Claude Code plugin for authoring, validating (via gh aw compile), and improving ...
- **[ccpkg](https://github.com/zircote/ccpkg)** (MDX) - Open packaging format for AI coding assistant extensions -- one archive installs...
<!-- NEW_REPOS_END -->


---

## Technology Stack

```text
Languages        Rust | Python | TypeScript | Go
Infrastructure   AWS | Docker | Kubernetes | Terraform | GitHub Actions
AI Integration   Claude Code | GitHub Copilot | MCP Protocol
Specifications   MIF (mif-spec.dev) | ccpkg (ccpkg.dev)
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

- **GitHub Issues** - For project-specific discussions
- **Pull Requests** - The best way to propose changes
- **LinkedIn** - Professional networking and collaboration

---
