# Test Selection and Coverage

Use these details after identifying the changed observable contract. Do not add a category merely to improve a coverage number.

## Behavior Categories

| Risk | Useful cases |
|---|---|
| Boundary | Empty input, zero, negative values, maximum values, off-by-one, one item versus many |
| Error path | Invalid input, missing required data, malformed data, permission denial, timeout |
| State transition | Before/after behavior, create/read/update/delete, idempotency |
| Equivalence class | One representative from each meaningful input partition |
| Happy path | The ordinary success case, after higher-risk behavior is covered |
| Regression | For a bug fix, the smallest observable scenario that fails without the fix |

A single test may exercise more than one category, but give it one clear reason to fail. Split a kitchen-sink test when its assertions defend independent behaviors.

## Choosing a Test Level

| Situation | Default test |
|---|---|
| Pure function with complex logic | Unit tests across meaningful inputs; property-based testing when an invariant fits |
| API endpoint or route handler | Integration test with a real test database or equivalent |
| UI component | Integration test: render, interact, assert the DOM |
| Critical user workflow | E2E test, such as signup or checkout |
| Bug fix | Regression test at the lowest level that reproduces it |
| Glue code or simple delegation | Usually no dedicated test; integration coverage is enough |

## Coverage Philosophy

Cover use cases, not lines. There is no numeric target that proves a contract is defended.

For every nontrivial public function, endpoint, or component, require at least one happy-path test, one applicable edge-case test, and one applicable error-path test. Do not invent nonexistent failure modes; a getter or simple delegation is too trivial to need three dedicated tests and is usually covered by integration tests.
