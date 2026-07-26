# Personal Rust Style

This file is self-contained. It defines the style choices used by `code-style`; it does not depend on external repositories, example projects, or a particular codebase.

## Rule labels

- **Auto-apply** — the skill may make this local change after showing its concise patch preview, unless the user asked for review only.
- **Proposal only** — the skill may identify and outline the improvement, but it must not edit without an explicit request.
- **Local convention wins** — a target project's established pattern, formatter, lint policy, or instructions override this file.

Every automatic change must still be behavior-preserving, private to the current task, and free of ownership, error, allocation, concurrency, or drop-timing changes.

## Auto-apply rules

### Make the happy path linear

Prefer guards, `?`, and `let else` over nesting when they make the successful path easier to read and preserve exactly the same behavior.

```rust
let Some(config) = load_config()? else {
    return Ok(Default::default());
};

run(config)
```

Use an explicit `match` when each state or dispatch branch has meaningful behavior. Do not flatten branches merely to make them shorter.

### Name a condition with real meaning

Extract a compound condition into a local name when it represents a domain decision rather than a disposable boolean expression.

```rust
let is_valid_range = start <= end && end <= capacity;
if !is_valid_range {
    return Err(Error::InvalidRange);
}
```

Choose names that reveal the domain state or reason for a decision. Do not introduce a name for a one-use expression that is already obvious.

### Prefer the direct local expression

Remove a touched, private, one-use wrapper or helper when inlining it leaves a clearer local expression and does not hide a stable domain concept.

Keep duplication when a generic helper would force readers to jump across files or accept vague parameters. Three clear local lines are often better than a speculative abstraction.

### Remove comments that only narrate syntax

Delete a nearby comment only when it restates obvious code and carries no invariant, external constraint, safety requirement, or explanation of a rejected alternative.

Keep comments that explain why the code exists or what would make an apparently simpler implementation wrong.

### Preserve project-owned formatting

Use the repository's formatter and checked-in configuration. Do not hand-reformat touched code to match a personal layout preference when the project specifies another one.

## Proposal-only rules

### Use precise failure types at meaningful boundaries

At a library, application, or orchestration boundary, prefer a typed error that preserves actionable failure categories over an unstructured string, boolean, or silently discarded failure.

```rust
pub enum LoadError {
    MissingConfiguration,
    InvalidConfiguration { reason: String },
}

pub fn load(path: &Path) -> Result<Config, LoadError>;
```

Do not change `Result`, `Option`, error variants, logging, retry behavior, or public error contracts automatically. A thin low-level wrapper may legitimately use `Option` or status values when that is its established local contract.

### Keep modules focused and interfaces small

Group code by a real domain concern. Keep implementation private by default and expose a small public surface. Avoid shallow `Manager`, `Handler`, `Factory`, or one-method trait layers that only move obvious code elsewhere.

```text
parser/
├── mod.rs       # public surface
├── lexer.rs     # one cohesive concern
└── error.rs     # domain error type
```

Do not automatically move modules, change visibility, introduce/remove traits, or perform cross-file renames.

### Make resource ownership visible

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

Never add, remove, or restructure cleanup automatically: destructor timing and resource ownership are observable behavior.

### Keep unsafe and FFI boundaries narrow

Put raw-pointer, FFI, and other unsafe operations in the smallest practical block behind a safe interface. Document the invariant that makes the operation sound. Model ABI layout deliberately when an actual ABI boundary requires it.

```rust
#[repr(C)]
pub struct PacketHeader {
    pub length: u32,
    pub flags: u32,
}
```

Never automatically introduce, remove, expand, or relocate `unsafe`, `repr(C)`, layout assertions, or FFI types.

### Use explicit types for meaningful state and dispatch

Prefer enums and exhaustive matches when code represents a closed set of domain states, commands, or outcomes.

```rust
match state {
    State::Ready => start(),
    State::Running => poll(),
    State::Stopped => reset(),
}
```

Do not reshape an existing API or persistence/ABI contract merely to replace a flag or string with an enum.

### Document contracts, invariants, and constraints

Add rustdoc to public APIs whose contract is not obvious from a small signature. Comments should explain a safety precondition, external constraint, invariant, or why the tempting alternative is incorrect.

```rust
/// Releases the reservation before returning.
///
/// Callers must not use addresses derived from the reservation afterwards.
pub fn release(self) -> Result<(), ReleaseError>;
```

Do not bulk-add documentation or write comments that narrate implementation details.

### Test observable behavior

Prefer a focused test that catches a plausible regression in a public behavior, boundary, error case, or state transition. Use real collaborators when practical; avoid mocks of internal call chains. Co-locate focused unit tests and use integration tests for real external contracts.

```rust
#[test]
fn rejects_a_range_past_capacity() {
    assert!(Range::new(3, 11, 10).is_err());
}
```

Do not rewrite test contracts, fixtures, or assertions automatically. A test is behavior, not style-only cleanup.

### Avoid avoidable copies in byte-oriented work

When ownership is clear and the domain genuinely transforms caller-owned bytes, prefer an explicit mutable buffer or `&mut [u8]` over needless intermediate copies.

```rust
pub fn normalize(bytes: &mut [u8]);
```

Do not change allocation, aliasing, mutation, or performance behavior automatically.

### Log context at real operation boundaries

When a project already uses structured logging, log useful context at resource, process, I/O, lifecycle, or platform boundaries. Avoid routine success logs and avoid introducing logging infrastructure for a style pass.

Logging policy is repository-owned; always propose rather than add logs automatically.

## Generic fallback

For non-Rust code, apply only the auto-apply ideas that remain idiomatic and behavior-preserving in that language:

- make a linear happy path visible;
- name a non-obvious domain condition;
- remove an obvious narrating comment;
- prefer a direct local expression over a one-use wrapper.

Do not impose Rust types, ownership, module layout, error conventions, logging, or formatting on another language.

## Explicit exclusions

The skill does not prescribe:

- a global Rustfmt profile;
- a particular error crate, logging crate, test framework, or module-file layout;
- `no_std`, async, FFI, platform, kernel, cryptography, or performance patterns;
- exact test names, assertion macros, or fixture structure;
- a preference for abstraction or duplication independent of local readability.

When a task exposes a new preference, ask the user to explicitly add it to this ledger rather than treating one code sample as a new rule.
