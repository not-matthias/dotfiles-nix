---
name: minimal-diff
description: Keep code changes as small, local, and low-churn as possible while preserving correctness. Use when implementing or reviewing a change where the goal is the smallest safe git diff with no unrelated refactors.
license: MIT
---

<!--
Sources:
- https://github.com/openai/codex/blob/main/AGENTS.md
- https://google.github.io/eng-practices/review/developer/small-cls.html
- https://git-scm.com/docs/gitworkflows/2.12.5.html
-->

# Minimal Diff

Make the smallest correct change.

Prefer edits that keep behavior scoped, touch fewer lines, and avoid unrelated churn.

## When to Use

- The user wants a focused fix or feature without cleanup noise.
- You are tempted to refactor surrounding code that does not need to change.
- You want a commit that is easy to review and easy to revert.
- You are updating existing code and need to preserve local conventions.

## Workflow

### Step 1: Find the narrowest change surface

- Change the smallest existing unit that can safely solve the task.
- Prefer editing an existing function, condition, or data structure over introducing new files or abstractions.
- Reuse existing helpers before adding new ones.

### Step 2: Avoid churn

- Do not refactor between equivalent forms unless it clearly improves correctness or readability.
- Do not rename, reorder, reformat, or move code unless the task requires it.
- Do not "clean up" adjacent code in the same change.
- Keep to file-local style and patterns.

### Step 3: Prefer deletion over addition

- Remove dead branches, duplicate lines, and no-longer-needed code when they are directly caused by the change.
- Prefer fewer moving parts over new wrappers, flags, or one-off helpers.
- Three clear lines are better than a fresh abstraction used once.

### Step 4: Split behavior changes from refactors

- If a refactor is truly needed, keep it minimal and make it obvious why.
- If the task allows it, separate structural cleanup from behavior changes.
- Do not bundle speculative improvements into the same commit.

### Step 5: Review the diff before finishing

Check the final diff and ask:

1. Can any touched line stay unchanged?
2. Did I touch any file that did not need to change?
3. Did I introduce a helper, abstraction, or rename that only saves a few local lines?
4. Did I change formatting or surrounding code unrelated to the task?
5. Would a reviewer immediately understand why every changed line exists?

If the answer suggests unnecessary churn, reduce the diff.

## Rules

- Preserve correctness first. Smallest diff does not justify risky code.
- Prefer editing existing code over adding new code.
- Prefer local duplication over premature abstraction when the abstraction is single-use.
- Keep tests scoped to the behavior that changed.
- Do not expand the task on your own.
- If a larger refactor is required, say so explicitly instead of smuggling it into a small change.

## Resources

- [references/principles.md](references/principles.md) - External principles behind this skill

## Common Issues

**Issue:** The smallest change looks repetitive.
- Keep the repetitive version if the abstraction would only be used once and the local code stays readable.

**Issue:** Nearby code is messy.
- Leave it alone unless it blocks the requested change or causes a correctness issue.

**Issue:** A refactor seems necessary.
- Make the minimum refactor needed to unlock the fix, and keep the rest out of scope.
