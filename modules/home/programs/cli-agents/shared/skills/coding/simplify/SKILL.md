---
name: simplify
description: Review changed code for reuse, quality, and efficiency, then fix any issues found. Use after completing an implementation to catch redundancy, dead code, and over-engineering before committing.
---

# Simplify

Review your implementation before stopping. Run through each check below and fix issues in-place.

## Checklist

1. **Simpler approach?** Is there a more straightforward way to achieve the same result? Fewer moving parts, less indirection, fewer abstractions.
2. **Redundant code?** Are there duplicated blocks, near-identical functions, or copy-pasted logic that should be consolidated?
3. **Duplicate logic?** Did you introduce something that already exists elsewhere in the codebase? Check for existing helpers, utilities, or patterns before adding new ones.
4. **Dead code?** Are there unused imports, variables, functions, or commented-out blocks that should be removed?
5. **Over-engineering?** Did you add abstractions, configurability, error handling, or future-proofing that isn't needed for the current task? Three similar lines of code is better than a premature abstraction. Do not remove helpful abstractions that improve organization and maintainability.
6. **Clarity over brevity?** Prefer explicit, debuggable code over dense one-liners.
7. **Readable conditionals?** Avoid nested ternaries when they hurt readability; use clearer conditionals.
8. **Tests still pass?** If the project has tests, run them. If any fail due to your changes, fix them before finishing.

## Rules

- Preserve functionality: never change behavior; only simplify structure and readability.
- Only review files that were changed in this session or are staged in git.
- Fix issues directly — don't just report them.
- Only flag high-confidence issues. False positives are worse than missed nits.
- If no issues are found, briefly confirm the implementation is clean (one sentence).
- Do NOT add comments, docstrings, or type annotations that weren't there before.
- Do NOT refactor surrounding code that wasn't part of the original change.

<!-- References:
  - https://github.com/majiayu000/claude-skill-registry/blob/main/skills/data/nav-simplify/SKILL.md
  - https://github.com/majiayu000/claude-skill-registry/blob/main/skills/data/cleanup/SKILL.md
  - https://github.com/tursodatabase/turso/blob/main/.claude/skills/code-quality/SKILL.md
  - https://github.com/ClickHouse/ClickHouse/blob/master/.claude/skills/review/SKILL.md
  - https://github.com/HazAT/pi-config/blob/main/skills/code-simplifier/SKILL.md
-->
