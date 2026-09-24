---
name: deslop
description: >-
  Remove AI-generated slop from the comments and docs a change introduces (task/PR
  narration, comments restating the code, references to things the reader cannot
  see), flag low-value tests it adds, and review changed code for redundancy, dead
  code, and over-engineering. Only touches changes attributable to the task. Use when the user
  asks to "deslop", "remove AI slop", "simplify", or clean up before a PR.
---

# Deslop

Remove redundant prose and unnecessary code without changing behavior.

## Scope and safety

- Establish ownership from the request, conversation, and diff. Review only changes attributable to the task, including its committed changes; staged or dirty content is not automatically yours.
- Load [Code Style](../code-style/SKILL.md) for simplification guidance and mutation boundaries.
- Apply local, high-confidence, behavior-preserving improvements unless the user requested review only. Leave uncertain changes unapplied and explain material uncertainty.
- Do not refactor unrelated surrounding code or add new comments, docstrings, or type annotations.

## Comments and documentation

- Remove comments that restate code, narrate the task/PR, refer to private development artifacts, or require knowledge of a diff or earlier version. Describe the current mechanism rather than comparing it to something the reader cannot see.
- Remove comments documenting absent or removed features, such as "no configuration needed anymore." Keep an explanation only when it describes a current constraint.
- Preserve non-obvious reasons, invariants, external constraints, gotchas, units, and edge cases. Keep history only when it affects how the code should be used, with a durable ticket, PR, or permalink.
- Do not delete useful documentation or compress clear prose merely to shorten it. When unsure whether a comment matters, leave it unchanged.

## Code structure

- Check for a simpler approach, duplicate logic, unused imports or variables, dead branches, and commented-out code. Reuse existing helpers and patterns before adding new ones.
- Remove speculative wrappers, configuration, error handling, and future-proofing only when they add no useful behavior. Keep abstractions that improve organization or maintainability.
- Prefer explicit, debuggable control flow over dense one-liners or nested ternaries. Use the cognitive-load guidance in `code-style` to judge whether a simplification actually helps.

## Tests

When the change adds or modifies tests, load [Testing](skill://testing). Check for implementation-coupled assertions, mirror tests, excessive internal mocking, and cases that add no distinct behavioral coverage.

Mocking external or nondeterministic boundaries is legitimate. Prefer a higher-level behavior test over mocking internal call chains; propose larger redesigns separately.

If a weak test still protects meaningful behavior, flag it rather than silently deleting or weakening it.

## Verification and reporting

- After cleanup edits, run the relevant existing tests or checks. Fix failures caused by the cleanup; report unresolved failures.
- List meaningful cuts and checks actually run. If nothing warrants a change, say so briefly; do not manufacture findings.
