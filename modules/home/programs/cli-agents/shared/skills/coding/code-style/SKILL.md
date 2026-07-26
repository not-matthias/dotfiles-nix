---
name: code-style
description: "Apply Not Matthias's Rust-first personal coding style. Use whenever the user explicitly asks to apply or review their code style, make Rust match their preferences, perform a style pass, or simplify/refactor according to their conventions. Inspect only task-touched code, honor local project conventions first, and make only safe opt-out style edits."
---

# Code Style

Use this skill only for an explicit request to apply, review, or refactor toward the user's code style. Rust is the primary language. For another language, use only the generic fallback below and follow that language's project conventions.

Read `references/rust-style.md` before judging a Rust change. It is a standalone personal rule ledger: it contains the rules, rationale, examples, confidence, and application boundaries needed for this skill. Do not depend on or mention outside repositories when using it.

## Working contract

### Precedence

Resolve conflicts in this order:

1. The user's stated behavior and task scope.
2. Repository instructions, local formatter/lint configuration, and established nearby code.
3. Correctness, safety, ownership, and required verification.
4. The personal Rust reference.
5. Generic fallback preferences.

A local convention wins. Do not call it a violation or migrate it toward the reference. Mention it only when the distinction explains why no patch is appropriate.

### Scope

- Inspect the request's changed or named code and enough adjacent code to understand local convention.
- Patch only the code required by the current task. Do not turn a style request into a repository-wide cleanup.
- Leave formatting to the target project's formatter and checked-in configuration.
- Use existing `cognitive-load`, `minimal-diff`, and `testing` guidance when it applies. This skill selects personal preferences; it does not replace those workflows.

## Review and apply workflow

1. Establish the target's local conventions and the affected public/behavioral boundary.
2. Compare the touched code with the reference. Ignore rules that are inapplicable, project-local, or contradicted by nearby code.
3. Classify each finding:
   - **Auto-apply:** explicitly marked as such in the reference and safe in this context.
   - **Proposal only:** useful improvement that needs confirmation or carries semantic risk.
   - **Project-local:** do not promote or act on it.
4. Before changing files, state a concise ranked patch preview under `Applying` or `Recommended`:
   - rule area;
   - why it improves the code;
   - the smallest intended change.
5. Unless the user asks for `review-only`, `no edits`, `show the patch`, or equivalent, apply eligible auto-apply changes in the same task.
6. Run the narrowest relevant verification and report only what actually ran.

## Mutation boundary

Apply a rule only when the change is local, behavior-preserving, non-public, and does not change drop timing, ownership, error behavior, allocation behavior, or concurrency.

Always propose instead of automatically editing when a change affects:

- public APIs, exported names, visibility, or cross-file contracts;
- `Result`/`Option` semantics, error variants, retry behavior, or logging policy;
- ownership, lifetimes, `Drop`, allocation, concurrency, or performance-sensitive behavior;
- `unsafe`, FFI/ABI layout, platform behavior, or safety invariants;
- test contracts, fixtures, or observable behavior;
- module moves, broad renames, or anything needing a project-wide migration.

If the evidence or semantic equivalence is uncertain, leave the code unchanged and explain the smallest safe next step.

## Rust priorities

Use the reference to favor:

- linear control flow with guards, `?`, `let else`, and explicit `match` where state or dispatch matters;
- precise domain errors at meaningful boundaries without erasing existing error semantics;
- focused private modules and simple public surfaces instead of shallow abstractions;
- visible resource ownership, narrow unsafe boundaries, and documented invariants;
- names that expose domain state and non-obvious conditions;
- comments and rustdoc that explain constraints or invariants rather than narrate syntax;
- behavior-oriented tests and project-native Rustfmt/Cargo verification.

These are preferences, not license to introduce systems, FFI, or performance ceremony into ordinary Rust.

## Generic fallback

Outside Rust, apply only universal, low-risk improvements when local conventions support them:

- make a linear happy path visible with an equivalent guard or early return;
- name a complex condition whose meaning is otherwise hidden;
- remove a nearby comment that merely restates obvious code;
- avoid a one-use wrapper or abstraction when a local direct expression is clearer.

Do not impose Rust module structure, error types, ownership patterns, logging, or formatting on another language. Treat cross-file renames, API changes, and any behavioral uncertainty as proposals.

## Output

Use this structure when it adds value:

```text
Applying
1. [area] smallest change — why

Recommended, not applied
1. [risk · area] change — why it needs confirmation

Kept local convention
1. local pattern — why it overrides the reference

Check
- command or scenario actually run
```

If no material style change is warranted, say so plainly. Do not manufacture findings to make a style pass look productive.

## Maintaining the reference

Update `references/rust-style.md` only when the user explicitly asks to evolve their style. Keep it self-contained: add the rule, rationale, a generic example when useful, confidence/application boundary, and exceptions. Do not silently learn rules from one task or rely on external project sources.
