---
name: review
description: Review a diff, PR, or commit for correctness and maintainability using code-style guidance. Use when asked to "review", "review this PR/diff/commit", or give a focused pass before merging. Reviews are read-only unless fixes are explicitly requested. For comment cleanup use deslop.
---

<!--
Sources:
- https://github.com/can1357/oh-my-pi (packages/coding-agent/src/prompts/agents/reviewer.md, bundled /review command)
- https://nimbalyst.com/blog/bugs-ai-writes-patterns-in-ai-generated-code/
- https://gitautoreview.com/blog/code-review-checklist-ai-generated-code
-->

# Review

Review only what the patch introduces. Read full files around each hunk. Skip lock files, generated code, snapshots, build output. 
Load [Code Style](skill://code-style) if needed and follow its applicability and precedence rules.

## Get the diff

- Uncommitted: `git diff` and `git diff --cached` (both staged and unstaged).
- Branch (PR-style): `git diff <base>...HEAD` (merge base, so base-only commits are excluded).
- Commit: `git show <sha>`.
- GitHub PR: `gh pr diff <number>`; don't assume the local checkout matches the PR.

## Large diffs: run in parallel

Review alone under ~500 changed lines. Above that, use one reviewer per ~500 lines, capped around 8; past that, suggest splitting the PR.

- Group files by locality (same module/directory, a type and its consumers) so each reviewer sees related code together.
- Give each reviewer its file list, this skill, `code-style`, and the diff command; only inline the diff when it is small (<50k chars, ≤20 files).
- Reviewers stay read-only and return findings in the output format below.
- As lead: drop duplicates and anything you can't confirm by reading the code, then merge into one ranked list.

## Report a finding only if

- Concrete: points at specific lines and a real code path; no speculation.
- Actionable: a discrete fix, not "consider improving X".
- Unintentional: not a deliberate design choice.
- Introduced by the patch: not pre-existing.
- Proportionate: demands no rigor absent elsewhere in the codebase.

## LLM failure modes

- Band-aid fix: guard/try-catch/null-check at the symptom instead of the root cause.
- Swallowed errors, silent defaults, fake fallbacks (`unwrap_or_default`, `catch {}`, `|| true`).
- Hallucinated or outdated APIs, flags, options, crate/package versions.
- Type escape hatches to silence the compiler (`any`, `as`, `@ts-ignore`, `.clone()` to dodge borrowck, needless `unsafe`).
- Speculative abstraction: traits/factories/config for a single use.
- Second convention: new helper/pattern where one already exists in the repo.
- Half-done cutover: compat shims, aliases, re-exports, dead code, stale callers left behind.
- Stubs, `TODO`, placeholder values, or partial features presented as done.
- Unrelated churn: reformatting, renames, drive-by edits outside the task.
- New variant/event/message not handled at the consumer (switch, router, match). The consumer is often outside the diff; read it.
- Mirror tests: tests asserting implementation, mocks echoing, or tautologies.

## Output

Findings ordered by priority:

- `P0` blocks merge (data loss, security, broken build) · `P1` fix now · `P2` should fix · `P3` nit
- `[P1] path:line — imperative title` + one line: problem, trigger, fix. Keep the line range small (≤10 lines) and inside the diff.

End with a one-line verdict. If nothing is worth flagging, say so; don't manufacture findings.
