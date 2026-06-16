---
diataxis_type: how-to
diataxis_goal: generate a slide deck (PDF/HTML/PPTX) from a markdown source
---

# How to Generate a Presentation

## Overview

This guide turns a markdown source into a slide deck in PDF, HTML (Reveal.js),
and/or PPTX. Pick the path that fits: a GitHub issue (no local setup), the CLI,
or the reusable workflow. The markdown directives, design styles, and workflow
inputs are in the
[presentation formats reference](../reference/presentation-formats.md).

## Prerequisites

- A markdown source following the
  [presentation format](../reference/presentation-formats.md#markdown-format).
  Put sources under `docs/presentations/drafts/`.
- For the CLI path only: Python with the generator dependencies
  (see [reference](../reference/presentation-formats.md#dependencies)).

## Option A — From a GitHub issue (no local setup)

1. Open a new issue using the **Presentation Request** template.
2. Fill in the requirements and apply the `presentation` label.
3. The `presentation-from-issue` workflow generates the deck and opens a PR.

## Option B — From the CLI

```bash
pip install reportlab python-pptx Pillow jinja2 markdown pyyaml

python docs/presentations/generate.py \
  --input docs/presentations/drafts/my-deck.md \
  --output docs/presentations/output \
  --formats pdf,html,pptx \
  --style systematic-velocity
```

Choose `--style` from the four
[design styles](../reference/presentation-formats.md#design-styles); omit
`--formats` to default to `pdf`.

## Option C — From the reusable workflow

```yaml
jobs:
  generate:
    uses: zircote/.github/.github/workflows/reusable-presentation.yml@<SHA>
    with:
      source: docs/presentations/drafts/my-deck.md
      formats: pdf,html,pptx
      style: systematic-velocity
    secrets: inherit
```

Pin `@<SHA>` to a full commit SHA. Full inputs and outputs are in the
[reference](../reference/presentation-formats.md#reusable-workflow).

## Verification

The run (or `generate.py`) writes to `docs/presentations/output/`:

```sh
ls docs/presentations/output/
# my-deck.pdf   my-deck.pptx   my-deck/index.html
```

Open the PDF, or serve `my-deck/index.html` for the interactive Reveal.js deck.

## Related

- [Presentation formats reference](../reference/presentation-formats.md) —
  directives, styles, workflow inputs/outputs
- [Presentation skill](../../.github/skills/presentation-generation/SKILL.md) —
  the AI skill that authors and generates decks
