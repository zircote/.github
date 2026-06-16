---
diataxis_type: reference
diataxis_describes: the presentation generator's output formats, design styles, markdown directives, and workflow interface
---

# Presentation Generator Reference

Technical reference for the slide-deck generator (`docs/presentations/generate.py`
and `reusable-presentation.yml`). For the task steps, see
[How to generate a presentation](../how-to/generate-a-presentation.md).

## Output formats

| Format | Output | Description |
|--------|--------|-------------|
| PDF | `output/<deck>.pdf` | Fixed-layout slides with embedded fonts; print/archival |
| HTML | `output/<deck>/index.html` | Reveal.js deck; keyboard nav, presenter mode |
| PPTX | `output/<deck>.pptx` | Editable PowerPoint with speaker notes |
| MD | source | Clean markdown; version control, editing source |

## Design styles

| Style (`--style`) | Theme | Background | Accent | Best for |
|-------------------|-------|-----------|--------|----------|
| `systematic-velocity` (default) | Dark, coral | `#1A1A1A` | `#DA7756` | Technical / data talks |
| `clean-minimal` | Light, blue | `#FFFFFF` | `#2563EB` | Corporate, training |
| `technical-blueprint` | Dark blue, cyan | `#0F172A` | `#06B6D4` | Architecture / dev talks |
| `marketing-bold` | White, gradient | `#FFFFFF` | Purple→Pink | Sales pitches, launches |

## Markdown format

A source is YAML frontmatter plus slides separated by `---`.

```markdown
---
title: "Presentation Title"
subtitle: "Optional Subtitle"
author: "Author Name"
date: 2026-01-01
style: systematic-velocity
format:
  - pdf
  - html
---

# Section Title

---

## Slide Title

- Bullet one
- Bullet two

::: notes
Speaker notes go here.
:::
```

### Frontmatter keys

| Key | Description |
|-----|-------------|
| `title` | Deck title (title slide) |
| `subtitle` | Optional subtitle |
| `author` | Author name |
| `date` | Deck date |
| `style` | One of the [design styles](#design-styles) |
| `format` | List of output formats to produce |

### Slide directives

| Directive | Purpose |
|-----------|---------|
| `---` (on its own line) | Slide separator |
| `::: notes … :::` | Speaker notes (HTML/PPTX presenter view) |
| `<!-- metric: value="95%" label="Success Rate" -->` | Metric callout |
| `<!-- cta: text="Get Started" url="https://…" -->` | Call-to-action button |
| `::: columns / :::: column … :::: / :::` | Two-column layout |
| Triple-backtick code fence with a language | Syntax-highlighted code block |

## Reusable workflow

`reusable-presentation.yml` — generate decks in CI.

### Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `source` | Path to markdown source | Required |
| `formats` | Comma-separated formats | `pdf` |
| `style` | Design style | `systematic-velocity` |
| `output-dir` | Output directory | `docs/presentations/output` |
| `enable-research` | Enable web research | `false` |
| `repository-analysis` | Repo to analyze (`owner/repo`) | `''` |
| `create-pr` | Open a PR with results | `true` |

### Outputs

| Output | Description |
|--------|-------------|
| `pdf-path` | Path to generated PDF |
| `html-path` | Path to generated HTML directory |
| `pptx-path` | Path to generated PowerPoint |
| `pr-url` | URL of created PR |

## Directory structure

```text
docs/presentations/
├── generate.py     # generation script (PDF/PPTX/HTML)
├── README.md       # subsystem index
├── templates/      # per-style theming
├── drafts/         # markdown sources (generator input; excluded from doc review)
├── output/         # generated artifacts (excluded from doc review)
└── assets/         # shared fonts, images, brand
```

## Dependencies

```bash
pip install pyyaml                 # required
pip install reportlab Pillow       # PDF
pip install python-pptx Pillow     # PPTX
pip install jinja2 markdown        # HTML
```

## See also

- [How to generate a presentation](../how-to/generate-a-presentation.md)
- [Presentation skill](../../.github/skills/presentation-generation/SKILL.md)
