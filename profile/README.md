<!--
  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║                     GITHUB PROFILE README TEMPLATE                        ║
  ╠═══════════════════════════════════════════════════════════════════════════╣
  ║  This template creates your public profile at github.com/zircote     ║
  ║                                                                           ║
  ║  HOW TO PERSONALIZE:                                                      ║
  ║  1. Replace all {{placeholders}} with your actual content                 ║
  ║  2. Remove or customize sections that don't apply                         ║
  ║  3. Delete the HTML comment blocks (like this one) when done              ║
  ║  4. Add your own ASCII art, badges, or branding                           ║
  ║                                                                           ║
  ║  PLACEHOLDERS TO REPLACE:                                                 ║
  ║  - zircote → Your GitHub username/org name                           ║
  ║  - {{tagline}} → Your personal tagline                                    ║
  ║  - {{description}} → About you/your organization                          ║
  ║  - {{focus_area_N}} → Your areas of expertise                             ║
  ║  - {{project_N}} → Your featured projects                                 ║
  ╚═══════════════════════════════════════════════════════════════════════════╝
-->

# zircote

<!--
  OPTIONAL: Add ASCII art, logo, or banner here
  Tools: https://patorjk.com/software/taag/ for ASCII text
  Or use an image: ![Banner](https://your-image-url)
-->

> {{tagline}}
<!-- Example taglines:
  - "Building tools for developers, by developers"
  - "Open source enthusiast | DevOps practitioner | Coffee lover"
  - "Making software development more enjoyable"
-->

## About

<!-- Write 2-3 sentences about yourself or your organization -->
{{description}}

<!-- Example:
**zircote** is a software engineer focused on building practical open source
tools that improve developer workflows. Projects emphasize automation, developer
experience, and solving real problems.
-->

### Focus Areas

<!-- List 3-5 areas you specialize in or are passionate about -->
- **{{focus_area_1}}** - Brief description
- **{{focus_area_2}}** - Brief description
- **{{focus_area_3}}** - Brief description
- **{{focus_area_4}}** - Brief description

<!-- Examples:
- **Open Source Development** - Creating and maintaining tools that solve real problems
- **DevOps & Platform Engineering** - Infrastructure automation and CI/CD pipelines
- **AI-Assisted Workflows** - Integrating AI capabilities into development processes
- **Backend Systems** - Scalable APIs and distributed systems
-->

---

## Featured Projects

<!-- Highlight your best/most popular repositories -->

| Project | Description | Tech |
|---------|-------------|------|
| [{{project_1_name}}](https://github.com/zircote/{{project_1_name}}) | {{project_1_description}} | {{project_1_tech}} |
| [{{project_2_name}}](https://github.com/zircote/{{project_2_name}}) | {{project_2_description}} | {{project_2_tech}} |
| [{{project_3_name}}](https://github.com/zircote/{{project_3_name}}) | {{project_3_description}} | {{project_3_tech}} |

<!-- Example:
| [swagger-php](https://github.com/zircote/swagger-php) | OpenAPI documentation from PHP annotations | PHP |
| [git-adr](https://github.com/zircote/git-adr) | Architecture Decision Records with Git | Python |
-->

---

## GitHub Ecosystem

<!--
  This section documents the template/automation ecosystem.
  Keep this section if you deployed the ecosystem templates.
  Remove if not applicable.
-->

This account uses a comprehensive template and automation ecosystem for consistency across all repositories.

### Project Templates

Create new projects instantly with production-ready configuration:

| Template | Description | Stack |
|----------|-------------|-------|
| **python** | Python library/CLI starter | Python 3.12+, uv, ruff, pyright |
| **typescript** | TypeScript package starter | Node 22, pnpm, ESLint 9, Vitest |
| **go** | Go application starter | Go 1.23+, golangci-lint |
| **rust** | Rust project starter | Stable, clippy, cargo-deny |
| **java** | Spring Boot application | Java 21, Gradle, JUnit 5 |
| **data-science** | Data science environment | Jupyter, pandas, sklearn |
| **docs-site** | Documentation website | Astro, Starlight, MDX |
| **content-pipeline** | Content creation workflow | Markdown, YAML validation |
| **devcontainer** | Development container | Multi-language, VS Code |
| **video** | Video production workflow | Scripts, shot lists, captions |

### What's Included

Every template provides:
- GitHub Actions CI/CD with SHA-pinned actions
- AI assistant configuration (CLAUDE.md, Copilot instructions)
- MCP server configuration for enhanced AI capabilities
- Dependabot for automated dependency updates
- Issue/PR templates and CODEOWNERS
- Security policy and contributing guide

### Quick Start

```bash
# Clone the ecosystem repository
git clone https://github.com/zircote/github.git
cd github

# Create a new project
./scripts/new-project.sh python my-api
./scripts/new-project.sh typescript my-app
```

---

## Reusable Workflows

<!-- Keep this section if you're using the reusable workflows -->

Standardized CI/CD workflows callable from any repository:

```yaml
# Example: Use Python CI workflow
jobs:
  ci:
    uses: zircote/.github/.github/workflows/reusable-ci-python.yml@main
    with:
      python-version: '3.12'
      coverage-threshold: 80
```

Available workflows:
- `reusable-ci-python.yml` - Python with uv, ruff, pyright, pytest
- `reusable-ci-typescript.yml` - TypeScript with ESLint, Vitest
- `reusable-ci-go.yml` - Go with golangci-lint
- `reusable-release.yml` - Semantic versioning with changelog
- `reusable-security.yml` - Secret and dependency scanning
- `reusable-docs.yml` - Documentation build and deploy

---

## Technology Stack

<!-- Customize with your preferred technologies -->

```
Languages        Python | TypeScript | Go | Rust
Infrastructure   Docker | Kubernetes | Terraform | GitHub Actions
AI Integration   Claude Code | GitHub Copilot | MCP Protocol
Platforms        AWS | GCP | Linux | macOS
```

---

## Security

<!-- Keep if using the security features from the ecosystem -->

This ecosystem is built with security as a first-class concern:

- **SHA-Pinned Actions** - All GitHub Actions pinned to specific commit SHAs
- **OIDC Authentication** - No static secrets for cloud providers
- **Secret Scanning** - Pre-commit hooks and CI with gitleaks
- **Dependency Scanning** - Automated vulnerability detection
- **Minimal Permissions** - Principle of least privilege

---

## Principles

<!-- Customize with your personal/org values -->

1. **Developer Experience First** - Tools should reduce friction
2. **Automation Over Documentation** - Encode knowledge in code
3. **Open by Default** - Share solutions that might help others
4. **Practical Over Perfect** - Ship working software, iterate based on usage
5. **Security by Design** - Build security in from the start

---

## Connect

<!-- Add your social links and contact methods -->

<!-- Examples (uncomment and customize):
[![Twitter](https://img.shields.io/badge/Twitter-@{{username}}-1DA1F2?logo=twitter&logoColor=white)](https://twitter.com/{{username}})
[![LinkedIn](https://img.shields.io/badge/LinkedIn-{{name}}-0A66C2?logo=linkedin&logoColor=white)](https://linkedin.com/in/{{username}})
[![Blog](https://img.shields.io/badge/Blog-{{domain}}-FF5722?logo=hashnode&logoColor=white)](https://{{domain}})
[![Email](https://img.shields.io/badge/Email-{{email}}-D14836?logo=gmail&logoColor=white)](mailto:{{email}})
-->

- **GitHub Issues** - For project-specific discussions
- **Pull Requests** - The best way to propose changes

---

## Stats

<!-- Optional: Add GitHub stats widgets -->
<!--
![GitHub Stats](https://github-readme-stats.vercel.app/api?username=zircote&show_icons=true&theme=dark)
![Top Languages](https://github-readme-stats.vercel.app/api/top-langs/?username=zircote&layout=compact&theme=dark)
![Streak](https://github-readme-streak-stats.herokuapp.com/?user=zircote&theme=dark)
-->

---

<sub>
<!-- Customize your footer -->
Building in the open | [View Ecosystem](https://github.com/zircote/github)
</sub>
