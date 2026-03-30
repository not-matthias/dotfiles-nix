# Rust Runtime Bug Reference

## unsafe Pitfalls

**Transmuting `&T` to `&mut T`** — UB immediately. Compiler assumes `&T` is never mutably aliased.

**Unbound lifetime from raw pointer**
```rust
fn get<'a>(p: *const u32) -> &'a u32 { unsafe { &*p } }
```
Caller chooses `'a` arbitrarily — can outlive the allocation.

**Missing `UnsafeCell` for interior mutability** — writing through a shared reference without `UnsafeCell` is UB. Compiler may constant-fold reads past your writes.

**FFI handle as `Send`** — raw primitive handles wrapping non-thread-safe C state get auto-derived `Send`. Verify the C library is thread-safe before implementing `Send`/`Sync`.

## unwrap/expect

**`unwrap()` on external data**
```rust
let val = map.get("key").unwrap();  // panics when key absent
```
In request handlers or background tasks, this crashes the whole task. Use `ok_or(...)` + `?`.

**`expect()` in `Drop`** — panicking in `Drop` while already panicking causes abort with no useful backtrace. Use `let _ =` and log instead.

## Send/Sync

**Auto-derived `Sync` on raw pointer wrapper** — `*const T` is `Sync`, so your wrapper gets it for free even when it shouldn't. Add `PhantomData<*mut ()>` to suppress.

**Wrong `PhantomData` variance** — missing `PhantomData<T>` on a type with `*mut u8` lets the compiler infer wrong variance, enabling unsound lifetime substitutions.

## Lifetime/Borrow Issues

**Elision ties output to wrong input** — with multiple reference inputs, elision picks the first. Be explicit when the returned reference comes from a different input.

## Integer Overflow

```rust
let total = price * quantity;  // u32
```
Debug: panics. Release: wraps silently. Use `checked_mul()` or `saturating_mul()`.

**`as` casts truncate silently**
```rust
let y = 300i64 as u8;  // y == 44, no error
```
Use `TryFrom`/`TryInto` for fallible narrowing.

## Iterator Invalidation

Borrow checker prevents modifying a `Vec` while iterating, but raw index loops are not protected:
```rust
for i in 0..v.len() {
    if v[i] == 2 { v.push(99); }  // loop bound stale
}
```
Use `retain`, `drain_filter`, or collect indices first.

## Drop Order

Fields drop in **declaration order** (not reverse). Matters for RAII resources:
```rust
struct Ctx {
    conn: Connection,   // dropped first
    guard: LockGuard,   // dropped second — but conn needs guard alive
}
```
Reorder fields or use `ManuallyDrop`.

**Mutex guard in `if let`** — temporary guard lives to end of enclosing statement, not just the condition. Can hold locks longer than expected.

## Async Pitfalls

**`std::sync::Mutex` across `.await`**
```rust
let guard = mutex.lock().unwrap();
some_async_fn().await;  // guard held across suspend point — deadlock
```
Use `tokio::sync::Mutex` or drop guard before `.await`.

**Cancellation safety** — code after `.await` may never run if the future is dropped (timeout, `select!` branch). Use RAII guards for cleanup, not post-await statements.

**`select!` recreating futures**
```rust
loop { select! { _ = expensive_future() => { } } }  // restarted each iteration
```
Hoist with `pin_mut!` + `fuse()` outside the loop.

## Error Handling

**`?` in closures** — propagates from the closure, not the enclosing function. Use `.collect::<Result<Vec<_>, _>>()?` instead.

**`let _ = critical_write(&mut file);`** — silently discards errors. Only appropriate for intentional non-critical discard.

**`unwrap_or_default()` hiding absence**
```rust
let name = user.name().unwrap_or_default();  // empty string looks valid to caller
```
Use `ok_or(Error::MissingField)?` to surface missing data.
