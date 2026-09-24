---
name: code-style
description: "Keep code simple, local, and low-churn when writing, reviewing, or refactoring. Use for general code work that benefits from lower cognitive load or a minimal diff. Apply Not Matthias's personal Rust preferences only when the user explicitly asks for their code style or a style pass."
---

# Code Style

## Read the applicable guidance

- For all code work, read [Cognitive load](references/cognitive-load.md) and [Minimal diff](references/minimal-diff.md).
- Only when explicitly asked to apply or review personal Rust style, also read [Rust preferences](references/rust-style.md). Do not impose them on other languages.
- For Nix, also read [Nix style](references/nix.md).
- When writing or reviewing tests, use [Testing](skill://testing).

## Scope and precedence

Correctness, safety, ownership, and required verification constrain every change. Within those constraints, follow the user's task scope and repository instructions, formatter/lint configuration, and nearby conventions before personal preferences. Do not copy an incorrect pattern merely for consistency.

Inspect the named or changed code and enough adjacent code to understand its conventions. Keep changes within the requested scope and leave formatting to the project formatter.

## Unsolicited style changes

These boundaries govern additional style cleanup, not changes needed to implement an explicitly requested feature, fix, or migration.

Auto-apply only local, private, behavior-preserving simplifications. Propose rather than apply additional cleanup that affects:

- public APIs, visibility, module moves, cross-file contracts, or broad renames;
- errors, logging, retries, test contracts, or observable behavior;
- ownership, lifetimes, drop timing, allocation, concurrency, or performance;
- unsafe code, FFI/ABI layout, or platform and safety invariants.

If equivalence is uncertain, leave the cleanup unapplied and explain why. A request for review, proposals, or no edits does not authorize mutations.

## Workflow

1. Establish the local convention and affected behavior.
2. Apply the relevant guidance within the task's authorization. For an explicit style pass, first show a concise ranked patch preview with the reason for each change.
3. Exercise the changed path using the narrowest relevant verification.
4. Report meaningful changes, checks actually run, and recommendations left unapplied. If no material change is warranted, say so.

## Maintaining preferences

Change personal Rust preferences only when explicitly asked. Keep each preference self-contained, with rationale and exceptions where needed. Do not infer a new rule from one code sample.
