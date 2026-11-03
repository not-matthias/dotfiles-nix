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

## PR scope and related implementations

- Review the full PR diff against its current target branch, not only the latest commit. After a base rewrite, distinguish stale ancestry from intentional changes before recommending removal. Do not rewrite history without authorization.
- Identify changes that can ship independently. Propose separating unrelated bug fixes and lint/format cleanup, even when correct. Keep prerequisites only when their dependency on the requested behavior is explicit.
- Before introducing a parallel CLI or configuration model, inspect the related implementation, including active worktrees and pinned dependencies. Compare syntax, defaults, validation, and forwarding. Propose contract changes separately from behavior-preserving cleanup.

## Comments and documentation

- Remove comments that restate code, narrate the task/PR, refer to private development artifacts, or require knowledge of a diff or earlier version. Describe the current mechanism rather than comparing it to something the reader cannot see.
- Remove comments documenting absent or removed features, such as "no configuration needed anymore." Keep an explanation only when it describes a current constraint.
- Remove rationale that merely explains why a bug fix works, even when phrased as current behavior. Keep it only if it documents a non-obvious constraint or prevents a plausible future mistake.
- Judge each sentence separately: preserve useful contracts, units, and edge cases while removing fix-specific explanation.
- Remove request provenance from comments, documentation, and changelogs: customers, repositories, incidents, or reproduction stories that explain why work started rather than what readers need to know. A fact being true or public does not make it relevant.
- Keep names when they define affected scope, compatibility, or a necessary technical constraint. Preserve the technical explanation when removing attribution; flag uncertain cases rather than deleting potentially useful information. Do not use a repository-name blacklist.
- Preserve non-obvious reasons, invariants, external constraints, gotchas, units, and edge cases. Keep history only when it affects how the code should be used, with a durable ticket, PR, or permalink.
- Do not delete useful documentation or compress clear prose merely to shorten it. When unsure whether a comment matters, leave it unchanged.

### Reader-relevance examples

- Remove: "Repository X reads this register at import time." This identifies the triggering caller, not the general behavior.
- Keep: "Linux emulates these register reads, so they succeed natively." This explains a platform constraint. In a paragraph containing both this statement and the previous example, remove only the provenance.
- Keep: "The workaround is required for library X versions 2.0–2.3." The dependency and versions define compatibility scope.
- Flag if unclear: "Library X requires this fallback." Determine whether X defines a compatibility constraint or merely supplied the reproducer before removing the name.
- Remove: "so costs are per iteration whatever the marker granularity." This defends the normalization fix rather than documenting a constraint.
- Keep: "Costs are divided by the run's measured iterations" when callers need the normalization contract.

## Code structure

- Check for a simpler approach, duplicate logic, unused imports or variables, dead branches, and commented-out code. Reuse existing helpers and patterns before adding new ones.
- Remove speculative wrappers, configuration, error handling, and future-proofing only when they add no useful behavior. Keep abstractions that improve organization or maintainability.
- Prefer explicit, debuggable control flow over dense one-liners or nested ternaries. Use the cognitive-load guidance in `code-style` to judge whether a simplification actually helps.
- Flag mode-specific fields passed separately through multiple layers. Prefer payload-bearing variants when they remove invalid combinations and repeated plumbing. Do not introduce a second parser enum when the CLI can parse the complete value directly.

## Tests

- Load [Testing](skill://testing) when tests change.
- Tie each added test to a changed behavior and a plausible consumer-visible regression. Compare with the PR base; propose separating coverage of unchanged internals unless the new caller creates a distinct risk.
- Ask: would this pass if the feature were missing or misconfigured? Test the boundary that observes the change, not only downstream behavior.
- Weigh fixture and helper complexity against coverage gained. Keep relevant boundaries and transitions; remove framework-only assertions, mirror tests, and redundant cases.
- Verify constructors and trait bounds in pinned dependencies before simplifying fixtures. Do not add production abstractions or opaque test machinery just to shorten setup.
- Mock external or nondeterministic boundaries, not internal call chains.
- Flag meaningful coverage before removing it. State what is lost; one-off smoke evidence is not permanent regression coverage.

## Verification and reporting

- Before finishing, review every added or modified prose block in the task-owned diff, including changelog and release-note entries, independently of the implementation review. Keep statements explaining behavior, affected scope, usage, or necessary constraints; remove clear request provenance and flag uncertain cases.
- For cross-component CLI changes, exercise the actual caller and its pinned callee, including argument boundaries. Parsing one component alone does not prove compatibility.
- After cleanup edits, run the relevant existing tests or checks. Fix failures caused by the cleanup; report unresolved failures.
- List meaningful cuts and checks actually run. If nothing warrants a change, say so briefly; do not manufacture findings.
