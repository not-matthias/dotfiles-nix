---
name: deslop
description: >-
  Remove AI-generated slop from the comments and docs a change introduces (task/PR
  narration, comments restating the code, references to things the reader cannot
  see), flag low-value tests it adds, and review changed code for redundancy, dead
  code, and over-engineering. Operates on the current diff only. Use when the user
  asks to "deslop", "remove AI slop", "simplify", or clean up before a PR.
---

Remove AI Slop from the comments/docs this PR adds.

AI Coding tools love to add comments everywhere that don't belong to production code.
- comments that mentions uncommited files or private dev-specific content that the team cannot access.
- narration of the current task/PR/ticket that has nothing to do in production code. During implementation of a ticket, a "V1" can be cristal clear to the developer, but the reviewer or future reader of that code will have no clue what it means.
- comments that restate the code
- Explains by comparison to something the reader can't see ("unlike the other X", "same mechanism as Y"). Say the thing directly.
- Write each comment for a reader who sees only the current code, with no memory of how it got there. If understanding it needs the diff, the ticket, or a past version, it's slop, describe what is in front of the reader now. Rare exception: when the history genuinely changes how you'd treat the code (a non-obvious constraint, a past incident, a reverted approach), keep it but anchor it to a durable reference (ticket ID, PR, or permalink) so the reader can go get that context. If you can't point to one, the history isn't worth a comment.

Remove them, or simplify them like crazy.

Keep only non-obvious why, invariants, gotchas, units/edge cases. When unsure, delete rather than reword. Make the edits and list what you cut, one line each.

It doesn't mean you need to delete documentation. Documentation is different than comments !

It doesn't mean you should blindly shorten/compact comments. Simplifying doesn't equals to compacting. Often, compacting comments creates absolutely unreadable and very hard to understand comments for other readers. Keep comments easy to understand !

**Tests:** Flag weak tests added by this change (see the `testing` skill for criteria). When a weak test still covers behavior that matters, warn instead of silently deleting it.

For broader code-simplicity guidance, use the cognitive-load reference in the `code-style` skill.
Keep the code minimal using the minimal-diff reference in the `code-style` skill.

## Code structure

Review the changed code for structural issues and fix them in-place:

1. **Simpler approach?** Is there a more straightforward way to achieve the same result? Fewer moving parts, less indirection, fewer abstractions.
2. **Redundant code?** Are there duplicated blocks, near-identical functions, or copy-pasted logic that should be consolidated?
3. **Duplicate logic?** Did you introduce something that already exists elsewhere in the codebase? Check for existing helpers, utilities, or patterns before adding new ones.
4. **Dead code?** Are there unused imports, variables, functions, or commented-out blocks that should be removed?
5. **Over-engineering?** Did you add abstractions, configurability, error handling, or future-proofing that isn't needed for the current task? Three similar lines of code is better than a premature abstraction. Do not remove helpful abstractions that improve organization and maintainability.
6. **Clarity over brevity?** Prefer explicit, debuggable code over dense one-liners.
7. **Readable conditionals?** Avoid nested ternaries when they hurt readability; use clearer conditionals.

## Rules

- Preserve functionality: never change behavior; only simplify structure and readability.
- Only review files that were changed in this session or are staged in git.
- Fix issues directly — don't just report them.
- Only flag high-confidence issues. False positives are worse than missed nits.
- If no issues are found, briefly confirm the implementation is clean (one sentence).
- Do NOT add comments, docstrings, or type annotations that weren't there before.
- Do NOT refactor surrounding code that wasn't part of the original change.
- If the project has tests, run them after changes. Fix any failures before finishing.
