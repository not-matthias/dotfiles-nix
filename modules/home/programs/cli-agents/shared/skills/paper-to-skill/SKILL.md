---
name: paper-to-skill
description: >
  Converts a research paper (PDF path, uploaded PDF, or URL) into a reusable skill
  that stores distilled knowledge for future sessions. Use when a user asks to
  "turn this paper into a skill", "make this PDF reusable", "encode this research",
  or wants project-specific decisions backed by a specific paper without re-uploading it.
license: MIT
context: fork
agent: Explore
---

# Paper to Skill

Convert a paper into a reusable knowledge-source skill with a focused SKILL.md and optional references.

## When to Use

- A user provides a paper PDF and wants persistent reuse across sessions.
- A user wants a paper distilled into actionable guidance, caveats, and decision rules.
- A user wants project-specific terminology/thresholds from a paper auto-loaded when relevant.

## Inputs to Collect

1. Paper source: uploaded PDF, local file path, or URL.
2. Project context: what decisions/tasks the paper should guide.
3. Trigger language: how users naturally ask for this topic.
4. Priority sections: any must-include sections/results.

If project context is unclear, continue anyway and infer likely trigger contexts from the paper.

## Workflow

### Step 1: Extract text

Use the most reliable extraction path for the source:

- **Uploaded PDF in context**: read it directly.
- **Local PDF path**: prefer Marker for academic papers.
- **URL**: fetch content; for arXiv use `https://arxiv.org/html/<id>` when possible.

Recommended command (no install required):

```bash
# Marker (best default for academic PDFs)
uvx marker_single path/to/paper.pdf --output_dir /tmp/paper_out/
```

Fallback extraction:

```bash
uv run --with pdfplumber python - <<'PY'
import pdfplumber
from pathlib import Path

pdf_path = Path("paper.pdf")
out_path = Path("/tmp/paper.md")

with pdfplumber.open(pdf_path) as pdf:
    text = "\n\n".join(page.extract_text() or "" for page in pdf.pages)
out_path.write_text(text)
print(out_path)
PY
```

For scanned PDFs, use OCR (`uvx marker_single --force_ocr`).

### Step 2: Analyze for reusable knowledge

Extract only what improves future decisions:

- Core contribution (what is novel and why it matters)
- Paper-specific concepts/terms/notation
- Quantitative findings (exact numbers/thresholds)
- Conditions and assumptions
- Failure modes and practical caveats
- Direct "when X do Y" guidance

### Step 3: Distill (do not summarize loosely)

Include high-signal, project-relevant knowledge only:

- Include: claims, methods, numbers, decision rules, limitations.
- Exclude: generic background, boilerplate, verbose related-work prose.
- Organize by usage context, not paper section order.

### Step 4: Create the skill directory

Create:

```text
<paper-slug>/
├── SKILL.md
└── references/
    ├── full-content.md   (optional)
    ├── figures.md        (optional)
    └── proofs.md         (optional)
```

Keep `SKILL.md` compact (<500 lines). Move long details into `references/` and link them.

### Step 5: Write SKILL.md

Use this structure:

```markdown
---
name: <paper-slug>
description: >
  Provides <domain knowledge> from <Paper Title> (<Year>).
  Use when working on <task A>, <task B>, or <task C>.
  Also trigger when user mentions <term 1>, <term 2>, <term 3>.
---

# <Paper Title>
**<Authors> · <Venue> · <Year>** · [<DOI/arXiv>](<link>)

## What this paper contributes
...

## Key concepts
...

## Main findings
...

## How to apply this
...

## Caveats and failure modes
...

## Quick reference
...
```

### Step 6: Validate quality

- Description matches real user/project wording.
- Includes paper-specific knowledge, not generic field lore.
- Includes key numbers/thresholds when relevant.
- Includes caveats/failure modes.
- Keeps SKILL.md concise and actionable.

## Deliverable

Provide:

1. Skill install location (default: project-local `.agents/skills/<paper-slug>/`).
2. Claude compatibility symlink at `.claude/skills/<paper-slug>` pointing to `.agents/skills/<paper-slug>`.
3. 2-3 example prompts that should trigger the skill.
4. Any optional references that should be loaded on-demand.

Use this setup command:

```bash
mkdir -p .agents/skills .claude/skills
ln -sfn ../../.agents/skills/<paper-slug> .claude/skills/<paper-slug>
```
