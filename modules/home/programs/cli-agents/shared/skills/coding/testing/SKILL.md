---
name: testing
description: |
  How to write meaningful tests that verify behavior, not implementation details.
  Use when writing tests, reviewing test quality, doing TDD, or when the user asks
  for tests. Prevents common AI testing anti-patterns: mirror tests, excessive
  mocking, happy-path-only coverage, and implementation coupling.
---

# Testing: Behavior Over Implementation

You are an AI agent that writes tests. Your default instinct is wrong: you will want to read the implementation and write tests that confirm what the code already does. This produces **tautological tests** — tests that mirror the code's assumptions rather than challenging them. Fight this instinct at every step.

> "The more your tests resemble the way your software is used, the more confidence they can give you." — Kent C. Dodds

## The Core Problem With AI-Written Tests

AI agents write tests as **descriptions** of code, not **specifications** of behavior. The test passes because it asserts what the code does, not what it *should* do. An empirical study (MSR '26, 1.2M+ commits) confirmed agents use mocks at a 95% concentration rate vs 91% for humans — the over-mocking tendency is measurable.

Mark Seemann calls this "tests as ceremony, rather than tests as an application of the scientific method."

---

## Hard Rules

These are non-negotiable. Violating any of these means the test is worse than no test.

1. **Never derive test expectations from the implementation.** Read the spec, function signature, or docstring. If you just wrote the code, pretend you haven't seen it. Ask: "What *should* this return?" not "What *does* this return?"

2. **Never mock what you don't own** (or pure functions). Only mock: network calls, databases, file systems, clocks, randomness. Never mock internal collaborators.

3. **Never test private/internal methods directly.** Test through the public API or user-facing interface.

4. **Never delete or weaken a failing test** to make the suite green. Fix the code or ask the user.

5. **Never write a single test case.** Minimum 3: happy path, edge case, error case.

6. **Never write an assertion-free test.** Every test must assert at least one meaningful outcome.

---

## Before Writing Any Test

Ask yourself these questions in order:

1. **What is the contract?** What should this code do, according to its spec/signature/docs? Do NOT look at the implementation to answer this.
2. **Who are the users?** End users interact with UI. Developer users interact with APIs. Test from their perspective.
3. **What's the worst bug that could hide here?** Off-by-one? Null handling? Race condition? Write a test for that first.

---

## What To Test (Prioritized)

Test these in this order — most agents stop at #1 and call it done:

1. **Boundary conditions** — empty input, zero, negative, max values, off-by-one, single element vs many
2. **Error paths** — invalid input, missing required fields, malformed data, permission denied, timeout
3. **State transitions** — before/after, create/read/update/delete, idempotency
4. **Equivalence classes** — one representative from each meaningful input partition
5. **Happy path** — the obvious success case (yes, this goes last in priority)
6. **Regression cases** — if fixing a bug, the test must fail without the fix applied

---

## What NOT To Test

- Language features or standard library behavior
- Framework internals (don't test that React renders, that pytest collects, etc.)
- Getters, setters, constructors, trivial delegation
- Third-party library correctness

---

## Test Quality Validation

After writing each test, apply these checks:

| Check | Question |
|---|---|
| **Mutation test** | If I change `>` to `>=`, or remove a null check, does this test fail? If not, it's weak. |
| **Hardcode test** | If I replace the implementation with a hardcoded return value, does this test still pass? If yes, it's too narrow. |
| **Refactor test** | If I rename internal variables or restructure the code, does this test break? If yes, it tests implementation details. |
| **One-reason test** | Can I explain in one sentence what bug this test catches? If not, split it. |
| **Name test** | Does the test name describe the expected behavior? Good: `rejects_order_when_inventory_is_zero`. Bad: `test_process_order`. |

---

## Anti-Pattern Gallery

| Anti-Pattern | What It Looks Like | Fix |
|---|---|---|
| **Mirror test** | Read impl of `parse("hello")`, assert whatever it returns | Decide what `parse("hello")` *should* return from the spec, then assert |
| **Mock fest** | Mock the DB, logger, config, clock, and half the module | Use real test DB or in-memory equivalent; only mock true external boundaries |
| **Implementation coupling** | `expect(spy).toHaveBeenCalledWith('_internalMethod')` | Assert on observable output or side effects instead |
| **Happy path only** | Only test `add(2, 3) == 5` | Add: `add(0, 0)`, `add(-1, 1)`, `add(MAX, 1)`, invalid input |
| **Kitchen sink** | One test with 15 assertions checking everything | One behavior per test, one clear reason to fail |
| **Snapshot addiction** | `toMatchSnapshot()` on everything | Assert specific values; snapshots hide what matters |
| **Test the framework** | Assert that `useState` updates state | Test *your* code's behavior, not library internals |

---

## TDD Workflow (Preferred)

Test-first is recommended because it prevents tautological tests by design — you can't mirror an implementation that doesn't exist yet.

1. **Red**: Write the test from the spec. Run it. Confirm it fails with a clear error.
2. **Green**: Write the minimum code to pass. No extras.
3. **Refactor**: Clean up while tests stay green.

When fixing a bug: **always** write a failing test that reproduces the bug before writing the fix. This is non-negotiable even if you're not doing TDD otherwise.

When writing tests after implementation: consciously ignore the implementation. Read only the function signature, types, and documentation. Derive expected values from the specification, not from running the code in your head.

---

## Property-Based Testing

For complex pure functions (parsers, validators, serializers, math), consider property-based tests instead of (or alongside) example-based tests. They catch edge cases you wouldn't think to write by generating hundreds of random inputs.

**When to use:**
- Parsing/serialization roundtrips: `parse(serialize(x)) == x`
- Mathematical properties: commutativity, associativity, idempotency
- Invariants: "output length is always <= input length"
- Validators: "valid input never triggers an error"

**When NOT to use:**
- Testing specific business rules with known expected outputs
- Integration tests with external dependencies
- UI behavior tests

---

## When To Write Which Kind of Test

| Situation | Test Type |
|---|---|
| Pure function with complex logic | Unit tests (many inputs) + property-based if fitting |
| API endpoint / route handler | Integration test with real-ish DB |
| UI component | Integration test (render + interact + assert DOM) |
| Critical user workflow | E2E test (signup, checkout, etc.) |
| Bug fix | Regression test at lowest level that reproduces it |
| Glue code / simple delegation | Usually don't test — integration tests cover it |

---

## Coverage Philosophy

**Cover use cases, not lines.**

No numeric coverage target. Instead, for every public function/endpoint/component, require:
- At least one happy-path test
- At least one edge-case test (boundary, empty, null)
- At least one error-path test (invalid input, failure mode)

If a function is too trivial to warrant three tests (getter, simple delegation), it probably doesn't need a dedicated test — integration tests will cover it.

---

## Language-Specific Patterns

### Rust

- Use `rstest` for parameterized tests — collapse boundary cases into one test
- Use `proptest`/`quickcheck` for property-based testing on complex pure functions
- Test `Result::Err` variants explicitly — don't just test the `Ok` path
- Test trait implementations through the trait, not concrete types
- Share setup via helper functions, not macros

### Python

- Use `@pytest.mark.parametrize` to collapse boundary cases
- Use `hypothesis` for property-based testing on complex pure functions
- Use `pytest.raises(ExceptionType, match="...")` for error paths
- Use fixtures for shared setup, not inheritance

### TypeScript / JavaScript

- Use Testing Library — test DOM output, not component internals
- Prefer `userEvent` over `fireEvent`
- Use `msw` for API mocking instead of mocking fetch directly
- `toMatchSnapshot` is almost never the right choice

---

## Worked Example: Shopping Cart

The implementation is hidden — you only see the contract. This is how you should approach testing.

### The Spec

```rust
pub struct Cart { /* hidden */ }

impl Cart {
    pub fn new() -> Self;
    /// Quantity must be 1..=99
    pub fn add(&mut self, item_id: &str, price: f64, qty: u32) -> Result<()>;
    /// Errors if item not in cart
    pub fn remove(&mut self, item_id: &str) -> Result<()>;
    /// Always >= 0.0, includes discounts
    pub fn total(&self) -> f64;
    /// Single-use. Errors if invalid or already used.
    pub fn apply_discount(&mut self, code: &str) -> Result<()>;
}
```

### Bad: what an agent writes

```rust
#[test]
fn test_add() {
    let mut cart = Cart::new();
    cart.add("hat", 25.0, 1).unwrap();
    assert_eq!(cart.items.len(), 1);     // internal field!
    assert_eq!(cart.items[0].qty, 1);    // internal field!
}

#[test]
fn test_total() {
    let mut cart = Cart::new();
    cart.add("hat", 25.0, 2).unwrap();
    assert_eq!(cart.total(), 50.0);      // just mirrors 25*2
}
```

`test_add` reaches into `cart.items` — breaks if storage changes from Vec to HashMap. `test_total` only checks the obvious multiplication, derived from reading the impl. Neither test catches real bugs.

### Good: derived from spec only

```rust
fn cart_with(item_id: &str, price: f64, qty: u32) -> Cart {
    let mut c = Cart::new();
    c.add(item_id, price, qty).unwrap();
    c
}

#[rstest]
#[case(0, true)]     // below range
#[case(1, false)]    // lower bound
#[case(99, false)]   // upper bound
#[case(100, true)]   // above range
fn add_rejects_invalid_quantity(
    #[case] qty: u32,
    #[case] should_err: bool,
) {
    let result = Cart::new().add("hat", 10.0, qty);
    assert_eq!(result.is_err(), should_err);
}

#[test]
fn remove_nonexistent_item_errors() {
    assert!(Cart::new().remove("nope").is_err());
}

#[test]
fn discount_code_is_single_use() {
    let mut cart = cart_with("hat", 100.0, 1);
    cart.apply_discount("SAVE10").unwrap();
    assert!(cart.apply_discount("SAVE10").is_err());
}

#[test]
fn total_never_negative_after_large_discount() {
    let mut cart = cart_with("hat", 5.0, 1);
    let _ = cart.apply_discount("HALF_OFF");
    assert!(cart.total() >= 0.0);
}
```

4 tests. Each targets a non-obvious spec constraint: quantity boundaries (parameterized), missing-item error, single-use invariant, non-negative invariant. The happy path is covered implicitly by `cart_with` in the other tests — no dedicated test needed.

---

## Worked Example: Executable Detection

Parameterized tests shine when testing a single function against many inputs. Use two test functions (positive and negative) instead of a boolean parameter — it's more readable and the test names are self-documenting.

### Bad: one test per case

```rust
#[test]
fn basic_java_command() {
    assert!(command_has_executable("java -jar bench.jar", &["java"]));
}

#[test]
fn java_with_absolute_path() {
    assert!(command_has_executable("/usr/bin/java -jar bench.jar", &["java"]));
}

#[test]
fn java_with_env_prefix() {
    assert!(command_has_executable("FOO=bar java -jar bench.jar", &["java"]));
}

#[test]
fn gradle_chained_with_and() {
    assert!(command_has_executable("cd /app && gradle bench", &["gradle"]));
}

#[test]
fn javascript_must_not_match_java() {
    assert!(!command_has_executable("javascript-runtime run", &["java"]));
}

#[test]
fn javascript_path_must_not_match_java() {
    assert!(!command_has_executable("/home/user/javascript/run.sh", &["java"]));
}

#[test]
fn scargoship_must_not_match_cargo() {
    assert!(!command_has_executable("scargoship build", &["cargo"]));
}
```

7 tests, lots of boilerplate. Adding a new case means copy-pasting an entire function. The positive/negative intent is buried in `assert!` vs `assert!`.

### Good: parameterized with two functions

```rust
use rstest::rstest;

#[rstest]
#[case("java -jar bench.jar", &["java"])]
#[case("/usr/bin/java -jar bench.jar", &["java"])]
#[case("FOO=bar java -jar bench.jar", &["java"])]
#[case("cd /app && gradle bench", &["gradle"])]
#[case("cat file | python script.py", &["python"])]
#[case("sudo java -jar bench.jar", &["java"])]
#[case("(cd /app && java -jar bench.jar)", &["java"])]
#[case("setup.sh; java -jar bench.jar", &["java"])]
#[case("try_first || java -jar bench.jar", &["java"])]
fn matches(#[case] command: &str, #[case] names: &[&str]) {
    assert!(command_has_executable(command, names));
}

#[rstest]
#[case("javascript-runtime run", &["java"])]
#[case("/home/user/javascript/run.sh", &["java"])]
#[case("scargoship build", &["cargo"])]
#[case("node index.js", &["gradle", "java", "maven", "mvn"])]
fn does_not_match(#[case] command: &str, #[case] names: &[&str]) {
    assert!(!command_has_executable(command, names));
}
```

Same coverage, adding a case is one line. The function names (`matches` / `does_not_match`) make the intent obvious without reading the assertion.

---

## References

- [Testing Implementation Details — Kent C. Dodds](https://kentcdodds.com/blog/testing-implementation-details)
- [Write Tests. Not Too Many. Mostly Integration. — Kent C. Dodds](https://kentcdodds.com/blog/write-tests)
- [How to Know What to Test — Kent C. Dodds](https://kentcdodds.com/blog/how-to-know-what-to-test)
- [Test Desiderata — Kent Beck](https://testdesiderata.com/)
- [Mocks Aren't Stubs — Martin Fowler](https://martinfowler.com/articles/mocksArentStubs.html)
- [AI-Generated Tests as Ceremony — Mark Seemann](https://blog.ploeh.dk/2026/01/26/ai-generated-tests-as-ceremony/)
- [Over-Mocked Tests Empirical Study (MSR '26)](https://arxiv.org/html/2602.00409v1)
- [TDD with AI Agents — QA Skills](https://qaskills.sh/blog/tdd-ai-agents-best-practices)
