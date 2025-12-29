# Presentation Generation System

Generate professional slide deck presentations from markdown with support for multiple output formats.

## Quick Start

### From GitHub Issue

1. Create a new issue using the **Presentation Request** template
2. Fill in your presentation requirements
3. Submit the issue with the `presentation` label
4. The workflow automatically generates your presentation and creates a PR

### From Command Line

```bash
# Install dependencies
pip install reportlab python-pptx Pillow jinja2 markdown pyyaml

# Generate presentation
python docs/presentations/generate.py \
  --input docs/presentations/drafts/my-presentation.md \
  --output docs/presentations/output \
  --formats pdf,html,pptx \
  --style systematic-velocity
```

## Output Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| PDF | Print-ready, static | Handouts, archival |
| HTML | Web-based Reveal.js | Interactive presentations, web hosting |
| PPTX | PowerPoint | Editing, corporate environments |
| MD | Clean markdown | Version control, editing source |

## Design Styles

### Systematic Velocity (Default)
Dark theme with coral accents. Data-focused with geometric elements.
- Background: #1A1A1A
- Accent: #DA7756
- Best for: Technical talks, data presentations

### Clean Minimal
Light theme with blue accents. Professional with generous whitespace.
- Background: #FFFFFF
- Accent: #2563EB
- Best for: Corporate presentations, training

### Technical Blueprint
Dark blue with cyan accents. Code-focused with grid elements.
- Background: #0F172A
- Accent: #06B6D4
- Best for: Architecture talks, developer presentations

### Marketing Bold
White with vibrant gradients. High-contrast with strong CTAs.
- Background: #FFFFFF
- Accent: Purple→Pink gradient
- Best for: Sales pitches, product launches

## Markdown Format

```markdown
---
title: "Presentation Title"
subtitle: "Optional Subtitle"
author: "Author Name"
date: 2025-12-29
style: systematic-velocity
format:
  - pdf
  - html
---

# Section Title

---

## Slide Title

- Bullet point 1
- Bullet point 2

::: notes
Speaker notes go here.
:::

---

## Metrics Slide

<!-- metric: value="95%" label="Success Rate" -->
<!-- metric: value="3x" label="Performance Gain" -->

---

## Code Example

```python
def hello():
    return "Hello, World!"
```

---

## Two Columns

::: columns
:::: column
### Left Side
- Point A
- Point B
::::
:::: column
### Right Side
- Point C
- Point D
::::
:::

---

# Call to Action

<!-- cta: text="Get Started" url="https://example.com" -->
```

## Directory Structure

```
docs/presentations/
├── generate.py          # Main generation script
├── README.md            # This file
├── templates/           # Style templates (future)
├── drafts/              # Source markdown files
│   └── example.md
├── output/              # Generated presentations
│   ├── example.pdf
│   ├── example.pptx
│   └── example/
│       └── index.html
└── assets/              # Shared assets
    ├── fonts/
    ├── images/
    └── brand/
```

## Workflow Integration

### Reusable Workflow

```yaml
jobs:
  generate:
    uses: zircote/.github/.github/workflows/reusable-presentation.yml@main
    with:
      source: 'docs/presentations/drafts/my-deck.md'
      formats: 'pdf,html,pptx'
      style: 'systematic-velocity'
    secrets: inherit
```

### Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `source` | Path to markdown source | Required |
| `formats` | Comma-separated formats | `pdf` |
| `style` | Design style | `systematic-velocity` |
| `output-dir` | Output directory | `docs/presentations/output` |
| `enable-research` | Enable web research | `false` |
| `repository-analysis` | Repo to analyze (owner/repo) | `''` |
| `create-pr` | Create PR with results | `true` |

### Outputs

| Output | Description |
|--------|-------------|
| `pdf-path` | Path to generated PDF |
| `html-path` | Path to generated HTML directory |
| `pptx-path` | Path to generated PowerPoint |
| `pr-url` | URL of created PR |

## Dependencies

```bash
# Required
pip install pyyaml

# For PDF generation
pip install reportlab Pillow

# For PowerPoint generation
pip install python-pptx Pillow

# For HTML generation
pip install jinja2 markdown
```

## Related

- [Presentation Skill](../.github/skills/presentation-generation/SKILL.md) - AI skill definition
- [Issue Template](../.github/ISSUE_TEMPLATE/presentation_request.yml) - GitHub issue form
