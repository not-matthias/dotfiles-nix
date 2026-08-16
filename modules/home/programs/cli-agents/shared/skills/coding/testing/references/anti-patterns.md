# Test Anti-Patterns

Use this catalogue when a test passes but does not convincingly defend a user- or caller-visible contract.

| Anti-pattern | What it looks like | Repair |
|---|---|---|
| Mirror test | Read `parse("hello")`, then assert whatever the implementation returns | Decide what `parse("hello")` must return from the contract, then assert that |
| Mock fest | Mock the database, logger, config, clock, and half the module | Use a real test database or in-memory equivalent; mock only true external boundaries |
| Implementation coupling | `expect(spy).toHaveBeenCalledWith("_internalMethod")` | Assert an observable output or side effect instead |
| Happy path only | Only assert `add(2, 3) == 5` | Add only materially distinct boundaries or failures the contract requires |
| Kitchen sink | One test has 15 assertions for unrelated behavior | Give each behavior one clear reason to fail |
| Snapshot addiction | Apply `toMatchSnapshot()` to everything | Assert the specific values or behavior that matter |
| Test the framework | Assert that `useState` updates state | Test the application's behavior, not library internals |
