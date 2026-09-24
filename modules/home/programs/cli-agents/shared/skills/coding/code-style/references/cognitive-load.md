<!--
Adapted from:
- https://github.com/zakirullin/cognitive-load
- https://github.com/zakirullin/cognitive-load/blob/main/README.agents.md
Original author: Artem Zakirullin
License: Creative Commons Attribution 4.0 International
-->

# Cognitive Load

Reduce the facts a maintainer must remember to understand the code. Remove complexity introduced by structure, not complexity inherent in the problem.

Understand inputs, outputs, side effects, error paths, and invariants before simplifying. Preserve edge cases and verify behavior before claiming equivalence. Correctness comes first; choose the smallest simplification that removes real cognitive load.

## Keep relevant facts local

Keep decisions near the data they depend on. Avoid scattering state transitions and call-order requirements across files or hiding behavior behind wrappers, inheritance, middleware, or macros.

Use precise names for domain state, conditions, mappings, sentinels, and non-obvious values. Avoid context-dependent flags and hidden defaults that merely make call sites look simpler.

## Make control flow easy to follow

- Prefer guards, early returns, and one visible happy path. Separate invalid input and exceptional states from normal work.
- Keep nesting to 2-3 levels; avoid 4+ levels, stacked negations, and long functions that require remembering distant setup.
- Keep success, error, retry, and cleanup paths understandable rather than interleaving them in one block.
- Make failures obvious. Handle cases that can occur; do not silently ignore errors or invent speculative error handling.
- Prefer the smallest language subset that clearly solves the problem. Use advanced features when they help the project's maintainers, not when they hide control flow, allocation, lifetime, error handling, or side effects.

## Name meaningful conditions

Name complex conditions by their intent, not just their syntax:

```text
if value > limit && (user.canEdit || user.isOwner) && !resource.locked
```

becomes:

```text
exceedsLimit = value > limit
canModify = user.canEdit || user.isOwner
isUnlocked = !resource.locked

if exceedsLimit && canModify && isUnlocked
```

## Prefer interfaces that hide real complexity

A deep module provides meaningful behavior through a simple interface with few concepts exposed to callers. A shallow wrapper adds navigation without hiding complexity.

Add a helper, class, trait, interface, or module only when it removes more cognitive load than it adds. Avoid vague `Manager`, `Processor`, `Handler`, or `Factory` layers, one-line wrappers, and boolean parameters that change a function's mode. Do not migrate established patterns that are outside the task's scope.

Prefer explicit, debuggable code over clever one-liners that compress state changes or error handling.

## Accept duplication when abstraction adds indirection

Keep short, local duplication when the shared concept is not stable or a helper would require cross-file navigation, vague names, or boolean parameters.

Abstract when the repeated behavior is a real domain concept, the interface is simpler, and call sites become easier to read. Do not introduce generic machinery before a second real use case is understood.

## Explain constraints and invariants in comments

Keep comments about external constraints, non-obvious invariants, why a tempting alternative is wrong, or an overview the local code cannot convey. Prefer clearer names or structure when they make a comment unnecessary.

Do not narrate syntax or the feature, caller, or task that prompted a change. Match the surrounding comment density. Use an ASCII diagram when it clarifies a mechanism.

Add struct field doc comments only on complex types, not trivial fields.

Plan enough to remove material uncertainty, then execute the minimum sufficient solution.
