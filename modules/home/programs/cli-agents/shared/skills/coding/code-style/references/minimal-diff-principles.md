# Minimal Diff Principles

## Core idea

A good change is narrow, obvious, and easy to review.

## Distilled guidance

### OpenAI Codex AGENTS.md

- Avoid churn.
- Do not refactor between equivalent forms without a clear readability or functional gain.
- Do not create small helpers that are only referenced once.
- Prefer small, readable code over unnecessary indirection.

Source: https://github.com/openai/codex/blob/main/AGENTS.md

### Google Engineering Practices

- Keep changes small.
- Separate refactors from behavior changes when possible.
- Small changes are reviewed faster and with better feedback.

Source: https://google.github.io/eng-practices/review/developer/small-cls.html

### gitworkflows(7)

- Split work into small logical steps.
- Clean up commit structure before publishing.

Source: https://git-scm.com/docs/gitworkflows/2.12.5.html

## How to apply this skill

1. Start with the smallest safe in-place edit.
2. Add code only when an existing structure cannot carry the change.
3. Avoid touching unrelated files.
4. Avoid bundled cleanup.
5. Re-read the diff and delete anything that is not pulling its weight.
