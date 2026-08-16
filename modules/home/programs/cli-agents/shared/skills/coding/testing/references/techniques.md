# Techniques and Language Recipes

## TDD Details

Test-first work is most useful when the contract is clear: the expectation exists before implementation details can influence it.

For a bug fix, add the smallest regression test when it defends observable behavior and would have failed before the fix. If existing coverage already proves the behavior or a durable test is impractical, reproduce the failure and verify the narrowest relevant path instead.

When adding tests after implementation, inspect the code to discover boundaries and hidden failure paths, but derive expected values from the observable contract.

## Property-Based Testing

Use property-based tests for complex pure functions when a broad input space is better expressed as an invariant than a list of examples.

**Good fits:**

- Parsing or serialization round trips: `parse(serialize(x)) == x`
- Mathematical properties such as commutativity, associativity, or idempotency
- Invariants such as output length never exceeding input length
- Validators where valid input must not trigger an error

**Poor fits:**

- Specific business rules with known expected outputs
- Integration tests with external dependencies
- UI behavior

## Rust

- Use `rstest` to parameterize related boundary cases.
- Use `proptest` or `quickcheck` for suitable complex pure functions.
- Assert `Result::Err` variants explicitly instead of testing only the `Ok` path.
- Exercise trait implementations through the trait rather than concrete types.
- Share setup through helper functions, not macros.

## Python

- Use `@pytest.mark.parametrize` for related boundary cases.
- Use `hypothesis` for suitable complex pure functions.
- Use `pytest.raises(ExceptionType, match="...")` for error paths.
- Use fixtures for shared setup rather than inheritance.

## TypeScript and JavaScript

- Use Testing Library to assert DOM output rather than component internals.
- Prefer `userEvent` to `fireEvent`.
- Use MSW for API mocking instead of mocking `fetch` directly.
- Use snapshots only when their full output is the contract; `toMatchSnapshot` is otherwise rarely the right assertion.
