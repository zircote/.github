# Presentation Generation System

Generate professional slide decks (PDF, HTML/Reveal.js, PPTX) from markdown.
This page is the subsystem index; the documentation follows the
[Diátaxis](https://diataxis.fr/) split used across [`docs/`](../README.md).

| You want to... | Read |
| --- | --- |
| Generate a deck (issue, CLI, or workflow) | [How to generate a presentation](../how-to/generate-a-presentation.md) |
| Look up formats, styles, markdown directives, workflow inputs | [Presentation generator reference](../reference/presentation-formats.md) |
| Have an AI author and generate a deck | [Presentation skill](../../.github/skills/presentation-generation/SKILL.md) |

## Layout

- `generate.py` — the generator (PDF/PPTX/HTML).
- `templates/` — per-style theming.
- `drafts/` — markdown sources you author (generator input).
- `output/` — generated artifacts.
- `assets/` — shared fonts, images, brand.

`drafts/` and `output/` are generator input/output, not documentation, and are
excluded from documentation review.
