---
name: template-creation
description: Create new project templates or customize existing ones with CI/CD, tooling, and AI integration. USE THIS SKILL when user says "create template", "new template for", "customize template", "add template", or wants to build a new language/framework template.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Template Creation Skill

## Purpose

Create new project templates or customize existing ones with CI/CD, tooling, and AI integration for the Personal GitHub Ecosystem.

## Triggers

- "create a new template for [framework]"
- "customize the python template"
- "add a FastAPI template"
- "new template with [features]"
- "template for [use case]"

## Usage

Use this skill to create new project templates from scratch or customize existing ones. Start with the closest existing template and modify it for your specific framework or use case.

## Template Structure

Every template MUST include:

```text
templates/[name]-template/
├── README.md                  # Project documentation
├── CLAUDE.md                  # Claude Code instructions
├── CODEOWNERS                 # Code ownership
├── .gitignore                 # Language-appropriate ignores
├── .github/
│   ├── workflows/ci.yml       # CI pipeline (SHA-pinned)
│   ├── copilot-instructions.md
│   ├── dependabot.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── .vscode/
│   └── mcp.json               # MCP server config
└── [language-specific files]
```

## Placeholder Conventions

Use these placeholders (replaced by new-project.sh):

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{{project_name}}` | Kebab-case name | `my-api` |
| `{{package_name}}` | Underscore name | `my_api` |
| `{{ProjectName}}` | PascalCase name | `MyApi` |

## Var-Driven Workflows (release automation has NO placeholders)

Placeholders are for docs and source files. Release/publish/packaging
workflows must instead resolve ALL project specificity at runtime so they
are correct the moment the template is instantiated — nothing to rename,
nothing that can be missed:

- crate/package/binary name, version, description, license → from the
  language manifest at runtime (e.g. `cargo metadata --no-deps`,
  `node -p "require('./package.json').name"`)
- owner/repo → `${{ github.repository }}` / `${{ github.repository_owner }}`
- anything not derivable → a repository variable with a sane default
  (e.g. `${{ vars.HOMEBREW_TAP_REPO || 'homebrew-tap' }}`)

Reference implementation: `zircote/rust-template`
(`release.yml`, `publish.yml`, `package-homebrew.yml`).

## Publication Channels: created but disabled

Template repos publish nothing, but must ship working publication
workflows. Gate them on a single deterministic switch in the manifest the
user already edits — for Rust, `publish = false` in Cargo.toml:

- each publication job reads the flag via the manifest AT THE PACKAGED REF
  and skips (GitHub Release creation, registry publish, Homebrew/tap)
- the build → attest → verify chain still runs as CI validation
- the language tooling enforces it too (`cargo publish` refuses while set)
- instantiation deletes the one line to arm every channel — wire this into
  the template's init flow

## Workflow Standards

All CI workflows must:
1. Use SHA-pinned actions (not tags)
2. Declare minimal `permissions:`
3. Include lint, test, and build jobs
4. Support coverage thresholds

```yaml
# Example CI workflow header
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

## Creating a New Template

### Step 1: Start from Closest Existing

```bash
# Copy the most similar template
cp -r templates/python-template templates/fastapi-template
```

### Step 2: Update Core Files

1. **pyproject.toml** / **package.json** / **go.mod**: Add framework deps
2. **README.md**: Update description and quick start
3. **CLAUDE.md**: Add framework-specific commands and patterns
4. **.github/copilot-instructions.md**: Add framework conventions

### Step 3: Add Framework Boilerplate

Create the minimal working structure:
- Entry point file
- Configuration
- Example endpoint/function
- Basic tests

### Step 4: Update CI Workflow

```yaml
# Add framework-specific steps
- name: Run database migrations
  run: uv run alembic upgrade head

- name: Start test server
  run: uv run uvicorn app:app --host 0.0.0.0 --port 8000 &
```

### Step 5: Validate

```bash
# Check SHA pinning
./scripts/validate-sha-pinning.sh templates/new-template/.github/workflows/

# Verify required files exist
for f in README.md CLAUDE.md CODEOWNERS .gitignore; do
  [ -f "templates/new-template/$f" ] || echo "Missing: $f"
done

# Test placeholder replacement
./scripts/new-project.sh new-template test-project /tmp
cd /tmp/test-project
# Run CI locally if possible
```

## Language-Specific Requirements

### Python Templates
- Python 3.12+ with `uv`
- `ruff` (lint + format), `pyright` (types), `pytest` (tests)
- Google-style docstrings
- 80%+ coverage target

### TypeScript Templates
- Node.js 22+ with `pnpm`
- ESLint 9+ flat config, Prettier
- Vitest for testing
- Strict TypeScript

### Go Templates
- Go 1.23+ with modules
- `golangci-lint`
- Standard layout: cmd/, internal/, pkg/
- Table-driven tests

### Rust Templates
- Latest stable Rust
- `clippy` (pedantic), `cargo-deny`
- Documentation tests
- Attested releases per the attested-delivery skill (recipe D); var-driven
  release workflows; `publish = false` channel gate (see
  `zircote/rust-template`)

### Java Templates
- Java 21 LTS, Spring Boot 3.3+
- Gradle Kotlin DSL
- Checkstyle, SpotBugs, JUnit 5

## AI Integration Checklist

- [ ] CLAUDE.md with project overview, commands, patterns
- [ ] copilot-instructions.md with language conventions
- [ ] mcp.json with context7 and filesystem servers
- [ ] Example code patterns in AI instruction files
