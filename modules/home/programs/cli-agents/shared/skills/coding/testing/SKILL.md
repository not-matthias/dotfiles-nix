---
name: testing
description: |
  How to write meaningful tests that verify behavior, not implementation details.
  Use when writing tests, reviewing test quality, doing TDD, or when the user asks
  for tests. Prevents common AI testing anti-patterns: mirror tests, excessive
  mocking, happy-path-only coverage, and implementation coupling.
---

# Testing: Behavior Over Implementation

A useful test specifies an observable outcome and catches a plausible regression. Read the implementation to find setup, boundaries, and failure paths—not to derive the expected result.

## Core Contract

1. **Derive expectations from the contract.** Use the specification, types, documentation, or user requirement; do not copy incidental implementation behavior into assertions.
2. **Prefer real collaborators.** Mock only external or nondeterministic boundaries when direct use would be slow, unreliable, or unsafe. Do not mock internal call chains.
3. **Test through the public or user-facing interface.** Test an internal unit directly only when it has a meaningful isolated contract that is impractical to reach otherwise.
4. **Do not delete or weaken a failing test merely to make the suite green.** Update it only when the observable contract intentionally changed, and make that reason explicit.
5. **Add only materially distinct cases.** One test can cover a changed contract; add boundaries, errors, or state transitions only when they expose another plausible failure.
6. **Assert a meaningful outcome.** Use an explicit assertion or a framework-observed success or failure condition.

## Decide What to Cover

1. State the observable contract and who observes it.
2. Name the smallest plausible regression worth preventing.
3. Choose the lowest layer that can observe that outcome: a unit for isolated logic, an integration test for a boundary, and E2E only for a critical user journey.
4. Prioritize distinct risks in this order: boundaries, errors, state transitions, equivalence classes, then the happy path. For a bug fix, add the smallest observable regression test that would have failed before the fix.
5. Skip dedicated tests for language or framework internals, third-party correctness, and trivial getters, setters, constructors, or delegation unless local behavior changes the contract.

## Smallest Useful Workflow

1. Write the expected behavior from the contract and the test that would expose the regression.
2. If the contract is clear, write the test first, run it, and confirm a clear failure. When testing after implementation, still derive the expectation independently.
3. Make the minimum implementation change needed for the test to pass; refactor only while it remains green.
4. Run the narrowest relevant test or exercise the changed surface, then stop when the contract is defended.

## Finish Checklist

- Would removing the relevant guard, transition, or comparison make the test fail?
- Would a hardcoded answer make it pass? If so, broaden the observable scenario.
- Would an internal refactor break it? If so, remove implementation coupling.
- Does its name state the expected behavior and can its failure be explained in one sentence?
- Does every mock isolate a true external or nondeterministic boundary?

## Details When Needed

- [Test selection and coverage](references/test-design.md) — behavior categories and choosing a test level.
- [Anti-pattern catalogue](references/anti-patterns.md) — symptoms and repairs for weak tests.
- [Techniques and language recipes](references/techniques.md) — TDD caveats, property testing, Rust, Python, and TypeScript/JavaScript.
- [Worked examples](references/examples.md) — contract-first cart and parameterized executable-detection tests.
- [Background and sources](references/background.md) — rationale, research, and further reading.
