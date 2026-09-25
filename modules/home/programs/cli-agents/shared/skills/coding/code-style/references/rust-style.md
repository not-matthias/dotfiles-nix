# Rust style

Use this reference with the generic guidance and authorization boundaries in [Code Style](../SKILL.md). Apply these Rust preferences only when the user explicitly asks; local conventions take precedence within correctness and safety constraints.

## Linear control flow

Prefer `?` and `let else` when they make the successful path easier to read. Use early returns rather than nested `if let` statements.

```rust
let Some(config) = load_config()? else {
    return Ok(Default::default());
};

run(config)
```

Use an explicit `match` when each state or dispatch branch has meaningful behavior. Do not flatten branches merely to make them shorter.

## Precise failure types

At a library, application, or orchestration boundary, prefer a typed error that preserves actionable failure categories over an unstructured string, boolean, or silently discarded failure.

## Modules and layout

Group code by a real domain concern. Keep implementation private by default and expose a small public surface. Avoid shallow `Manager`, `Handler`, `Factory`, or one-method trait layers that only move obvious code elsewhere.

```text
parser/
├── mod.rs       # submodule declarations
├── lexer.rs     # one cohesive concern
└── error.rs     # domain error type
```

Use `<name>/mod.rs` with submodules as sibling files in that directory. A flat `<name>.rs` is fine when the module is genuinely tiny. Keep each `.rs` file focused; split related types into sibling files rather than accumulating unrelated structs in one file.

Prefer methods or associated functions when behavior belongs to a type. Group `impl` blocks by concern, such as construction, trait implementations, or public API. Keep `mod.rs` focused on declaring submodules; avoid re-exporting individual items from it.

These are layout preferences, not mandates to split small cohesive modules.

## Resource ownership

A type that owns a resource should make acquisition, cleanup, and lifetime responsibilities clear. Use RAII and `Drop` where cleanup belongs to the owner rather than to an unrelated caller.

```rust
pub struct LockGuard<'a> {
    lock: &'a Lock,
}

impl Drop for LockGuard<'_> {
    fn drop(&mut self) {
        self.lock.release();
    }
}
```

## Unsafe and FFI boundaries

Put raw-pointer, FFI, and other unsafe operations in the smallest practical block behind a safe interface. Document the invariant that makes the operation sound. Model ABI layout deliberately when an actual ABI boundary requires it.

## Explicit state and dispatch

Prefer enums and exhaustive matches when code represents a closed set of domain states, commands, or outcomes.

## Rustdoc contracts

Add rustdoc to public APIs whose contract is not obvious from a small signature, especially safety preconditions and caller obligations.

```rust
/// Releases the reservation before returning.
///
/// Callers must not use addresses derived from the reservation afterwards.
pub fn release(self) -> Result<(), ReleaseError>;
```

## Crash rather than corrupt

When an invariant is violated and continuing risks data corruption, prefer crashing (`assert!`, `unreachable!`, `panic!`) or returning an error over silently continuing in an undefined state. Do not use `if`/`else` for a branch that should never occur.

```rust
// Wrong: the else branch silently ignores an impossible state
if condition {
    handle()
} else {
    // shouldn't happen
}

// Right: make the impossibility explicit
assert!(condition, "invariant violated: ...");
// or
return Err(Error::InternalError("unexpected state".into()));
// or
unreachable!("impossible state: ...");
```

Use `if`/`else` only when both branches are expected paths. Assert often; never silently swallow an edge case.

## Byte-oriented ownership

When ownership is clear and the domain genuinely transforms caller-owned bytes, prefer an explicit mutable buffer or `&mut [u8]` over needless intermediate copies.

```rust
pub fn normalize(bytes: &mut [u8]);
```

## Explicit exclusions

The skill does not prescribe:

- a global Rustfmt profile;
- a particular error crate, logging crate, or test framework;
- `no_std`, async, FFI, platform, kernel, cryptography, or performance patterns;
- exact test names, assertion macros, or fixture structure;
- a preference for abstraction or duplication independent of local readability.

