---
name: cognitive-load
description: Reduce cognitive load when writing, reviewing, or refactoring code. Use when code should be simpler, more local, and easier to understand while preserving behavior.
license: CC-BY-4.0
---

<!--
Adapted from:
- https://github.com/zakirullin/cognitive-load
- https://github.com/zakirullin/cognitive-load/blob/main/README.agents.md
Original author: Artem Zakirullin
License: Creative Commons Attribution 4.0 International
-->

# Cognitive Load

Write code for human working memory first.

A maintainer should not need to remember many hidden facts, jump through many layers, or understand clever tricks to verify what the code does. Preserve behavior, but prefer the version with fewer moving parts and fewer active mental chunks.

## Core Rule

Minimize extraneous cognitive load.

Intrinsic complexity belongs to the problem. Extraneous complexity comes from how the code is shaped. Remove the extraneous part.

## When to Use

Use this skill when:

- Writing new code that could become clever or over-abstracted.
- Refactoring code that works but is hard to understand.
- Reviewing generated or human-written code for maintainability.
- Simplifying conditionals, control flow, APIs, or module boundaries.
- Choosing between local duplication and a new abstraction.

## Workflow

### 1. Preserve behavior first

- Understand the current behavior before changing structure.
- Identify inputs, outputs, side effects, error paths, and invariants.
- Do not simplify by dropping edge cases.
- Add or run the narrowest meaningful behavior check before claiming equivalence.

### 2. Find the load-bearing facts

Look for facts the reader must keep in memory:

- Previous conditions that affect the current branch.
- Variable meanings that are not visible from names.
- Call order requirements.
- State transitions spread across functions.
- Boolean flags whose meaning changes by context.
- Custom mappings, sentinels, or magic values.
- Behavior hidden behind wrappers, inheritance, traits, hooks, macros, or framework conventions.

Reduce the number of facts the reader must remember at once.

### 3. Make control flow linear

Prefer:

- Guard clauses.
- Early returns.
- One visible happy path.
- Separate handling for invalid input and exceptional state.
- Local decisions close to the data they depend on.

Avoid:

- Deeply nested `if` / `else` trees.
- Long functions where the reader must remember setup from far above.
- Mixed success, error, retry, and cleanup paths in one block.
- Boolean negation stacked with nested branches.

### 4. Name complex conditions

Extract complex boolean expressions into named intermediate values.

Bad:

```text
if value > limit && (user.canEdit || user.isOwner) && !resource.locked
```

Better:

```text
isWithinLimit = value > limit
canModify = user.canEdit || user.isOwner
isUnlocked = !resource.locked

if isWithinLimit && canModify && isUnlocked
```

Names must describe intent, not repeat syntax.

### 5. Prefer deep modules over shallow modules

Prefer deep modules:

- Simple interface.
- Meaningful behavior behind the interface.
- Fewer concepts exposed to callers.

Avoid shallow modules:

- Complex name.
- Complex interface.
- Tiny implementation.
- Indirection that hides one or two obvious lines.

Do not add a helper, class, trait, interface, hook, factory, service, or module unless it removes more cognitive load than it adds.

### 6. Do not worship DRY

Some duplication is cheaper than an abstraction.

Keep duplication when:

- The repeated code is short and local.
- The shared concept is not stable yet.
- The abstraction would force readers to jump between files.
- The abstraction would need vague names or boolean parameters.

Abstract only when:

- The duplicated behavior is a real domain concept.
- The abstraction makes call sites easier to read.
- The interface is simpler than the repeated code.

### 7. Use boring language features

Prefer the smallest language subset that clearly solves the problem.

Avoid clever constructs when they require specialized knowledge or hide control flow, allocation, lifetime, error handling, or side effects.

Use advanced features only when they make the code easier to understand for maintainers of this project.

### 8. Comment only the non-obvious why

Do not write comments that restate the code.

Write comments only for:

- External constraints.
- Non-obvious invariants.
- Why the obvious alternative is wrong.
- A high-level overview when local code cannot show the whole mechanism.

If better names or structure make the comment unnecessary, change the code instead.

## Review Checklist

Before finishing, check:

- Can the main path be read top to bottom?
- Can any nested branch become an early return?
- Does any condition require remembering more than a few facts?
- Would named intermediate values make a condition self-explanatory?
- Did a new abstraction make call sites simpler, or just move code away?
- Is duplication actually worse than the abstraction replacing it?
- Are names precise enough to let the reader forget implementation details?
- Did comments explain why, not what?
- Did verification cover the behavior that could have changed?

## Anti-Patterns

Avoid these unless the project already depends on them and changing them is out of scope:

- `Manager`, `Processor`, `Handler`, or `Factory` names with unclear domain meaning.
- Boolean parameters that change a function's mode.
- Many one-line wrappers around another API.
- Inheritance or middleware stacks where behavior is assembled far from the caller.
- Generic abstractions introduced before the second real use case is understood.
- Smart one-liners that compress state changes or error handling.
- Hidden defaults that make call sites look simpler than they are.

## Finish Line

A good change has the same behavior with fewer things to remember.

If simplification and minimal diff conflict, preserve correctness first, then choose the smallest simplification that removes real cognitive load.
