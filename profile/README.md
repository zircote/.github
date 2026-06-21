<p align="center">
  <img src="https://raw.githubusercontent.com/zircote/.github/main/profile/zircote-banner.svg" alt="zircote" width="800">
</p>

<p align="center">
  <a href="https://github.com/zircote"><img src="https://img.shields.io/github/followers/zircote?style=for-the-badge&logo=github&logoColor=white&label=Followers&color=181717" alt="GitHub Followers"></a>
  <a href="https://github.com/zircote?tab=repositories"><img src="https://img.shields.io/badge/dynamic/json?style=for-the-badge&logo=github&logoColor=white&label=Public%20Repos&query=public_repos&url=https://api.github.com/users/zircote&color=238636" alt="Public Repos"></a>
  <a href="https://www.linkedin.com/in/zircote/"><img src="https://img.shields.io/badge/LinkedIn-zircote-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"></a>
  <a href="https://zircote.github.io/"><img src="https://img.shields.io/badge/Blog-zircote.com-FF5722?style=for-the-badge&logo=hashnode&logoColor=white" alt="Blog"></a>
</p>

---

## About

**Robert Allen** is a systems/platform engineer, open source maintainer, and sheep and poultry farmer in Farmville, Virginia. By day, he drives infrastructure automation for a major education technology company. By evening, he builds developer tools that solve real problems in technology and agriculture — and somehow also runs a [regenerative pasture farm](https://epicpastures.com/).

### Focus Areas

- **AI Memory Systems** — Building structured, persistent memory for AI agents: [subcog](https://github.com/zircote/subcog) and [mnemonic](https://github.com/zircote/mnemonic)
- **Open Standards for AI Tooling** — Authoring the [MIF](https://mif-spec.dev) specification to make AI memory portable and interoperable
- **Agentic Workflows** — GitHub Agentic Workflows (`gh-aw`) for autonomous, event-driven repository operations at scale
- **Supply-Chain Security** — Signed, SLSA-attested, fail-closed-verified release pipelines (cosign, SBOM, provenance) as reusable org workflows
- **AI-Assisted Development** — Claude Code plugins, agents, and multi-agent orchestration
- **DevOps & Platform Engineering** — Infrastructure automation, CI/CD, AWS architecture

---

## Open Specifications

### [Memory Interchange Format (MIF)](https://mif-spec.dev) — Portable AI Memory

The AI memory ecosystem is fragmented — Mem0, Zep, Letta, and others all use proprietary schemas with no interoperability. MIF defines a common data model with dual representations: human-readable **Markdown** (Obsidian-compatible) and machine-processable **JSON-LD**, with lossless conversion between them. Three conformance levels scale from a 4-field core to full bi-temporal provenance, decay, and embeddings, with migration guides from the major memory systems.

**Status:** v0.1.0-draft &bull; [Specification](https://mif-spec.dev/specification/overview/) &bull; [GitHub](https://github.com/zircote/MIF)

---

## Memory, Ontology & AI

The intersection of cognitive science and AI systems presents a compelling question: **how do we build AI that remembers meaningfully?** Human memory isn't a tape recorder — it's a constructive process where our mental models (ontology) shape what we encode, and our memories reshape how we understand the world.

![The Recursive Loop: How Memory and Ontology Shape Our Reality](https://raw.githubusercontent.com/zircote/.github/main/docs/_assets/memory-ontology-recursion.jpg)

MIF grew directly from this research, the product of five-plus iterations on memory systems — [subcog](https://github.com/zircote/subcog) and [mnemonic](https://github.com/zircote/mnemonic) are its public expressions. Alongside them, I'm writing an academic paper measuring memory system impact across LLM models; one early finding is how much variance exists in structured recall between models in ways general benchmarks don't predict.

---

## Featured Projects

### [subcog](https://github.com/zircote/subcog) — Persistent Memory for AI Coding Assistants

A Rust memory system that captures decisions, learnings, and context from coding sessions. Hybrid search (semantic + BM25), MCP server integration, SQLite persistence with a knowledge graph, and proactive memory surfacing. Its filesystem-native sibling, [mnemonic](https://github.com/zircote/mnemonic), is a pure MIF Level 3 implementation — no dependencies, just markdown files and git.

### [rlm-rs](https://github.com/zircote/rlm-rs) — Recursive Language Model CLI

A Rust CLI implementing the RLM pattern ([arXiv:2512.24601](https://arxiv.org/abs/2512.24601)) for Claude Code — process documents 100x larger than the context window through intelligent chunking, SQLite persistence, and recursive sub-LLM orchestration. Ships with a [companion plugin](https://github.com/zircote/rlm-rs-plugin).

### [nsip](https://github.com/zircote/nsip) — Sheep Genetic Evaluation CLI & MCP Server

A Rust CLI and MCP server for the National Sheep Improvement Program database — 400,000+ animals with EBVs, pedigrees, and performance data. Provides breeding intelligence: Wright's inbreeding coefficients, weighted trait ranking, mating recommendations, and flock summaries. [nsip-example](https://github.com/zircote/nsip-example) demonstrates **GitHub4Farms** — GitHub Issues as a farm record-keeping system with Copilot-powered genetic enrichment, accessible to farmers with no technical background.

### Attested Delivery — Supply-Chain Security as Reusable Workflows

This organization's [.github repo](https://github.com/zircote/.github) centralizes signed, SLSA Build L3-attested, fail-closed-verified container delivery: keyless cosign signatures, CycloneDX SBOMs, provenance attestations as OCI referrers, verification gates before any publish or deploy, and change-record-gated production promotion — all consumable by any repo as reusable workflows. It also runs 17 `gh-aw` agentic workflows for daily triage, standup, dependency housekeeping, and retrospectives across the org.

---

## Active Projects

<!-- LAST_UPDATED_START -->
 __Last updated: 2026-06-21__
<!-- LAST_UPDATED_END -->

### Most Active Repositories

Ranked by recent contributions, community engagement, and development activity.

<!-- ACTIVE_REPOS_START -->
| Repository | Description | Tech | Activity |
|------------|-------------|------|----------|
| [rust-template](https://github.com/zircote/rust-template) | Template for rust projects | MDX | 📈 Growing |
| [nsip](https://github.com/zircote/nsip) | Sheep genetic evaluation CLI & MCP server -- search animals,... | Rust | 📈 Growing |
| [.github](https://github.com/zircote/.github) | Organization shared workflows, policies, and community healt... | Shell | 📈 Growing |
| [MIF](https://github.com/zircote/MIF) | Open standard for portable AI memory interchange — JSON-LD +... | MDX | 📈 Growing |
| [rlm-rs](https://github.com/zircote/rlm-rs) | Rust CLI implementing the Recursive Language Model (RLM) pat... | Rust | 📈 Growing |
| [homebrew-tap](https://github.com/zircote/homebrew-tap) | Homebrew tap for various projects | Ruby | 📈 Growing |
| [human-voice](https://github.com/zircote/human-voice) | Detect and eliminate AI writing patterns in your content. Th... | Python | 📈 Growing |
| [claude-team-orchestration](https://github.com/zircote/claude-team-orchestration) | Multi-agent orchestration plugin for Claude Code. Coordinate... | MDX | 📈 Growing |
<!-- ACTIVE_REPOS_END -->

### Recently Created

<!-- NEW_REPOS_START -->
- **[copilot-review](https://github.com/zircote/copilot-review)** (JavaScript) - A Claude Code plugin that uses GitHub Copilot as the backend for code reviews an...
- **[fastmcp-lro](https://github.com/zircote/fastmcp-lro)** (Python) - Large Result Offloading for MCP servers. Writes oversized tool responses to JSON...
<!-- NEW_REPOS_END -->

---

## Technology Stack

```text
Languages        Rust | Python | TypeScript | Go
Infrastructure   AWS | Docker | Kubernetes | Terraform | GitHub Actions
AI Integration   Claude Code | GitHub Copilot | MCP Protocol
Supply Chain     cosign | SLSA | CycloneDX | OCI referrers
Specifications   MIF (mif-spec.dev)
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
