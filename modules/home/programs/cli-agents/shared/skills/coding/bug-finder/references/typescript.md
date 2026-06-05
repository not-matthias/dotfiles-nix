# TypeScript/JavaScript Runtime Pitfalls

## Type Coercion

```js
0 == ""         // true — loose equality coerces both to 0
[] == false     // true — [] → "" → 0
```

Flag any `==` that isn't `== null`. Use `===` everywhere else.

`if (count)` silently breaks when count is legitimately `0`. Check `count != null` or `count !== undefined` instead.

## `any`/`unknown` Casts

```ts
const data = JSON.parse(raw) as User;  // no runtime validation — crash if shape wrong
function process(x: any) { x.name.trim(); }  // type checker silent, runtime throws
```

Flag `as SomeType` without a type guard, `any` parameters on public functions.

## Async

```ts
fireAndForget();  // no await, no .catch — unhandled rejection silently swallowed

// forEach does not await — iterations fire in parallel, errors lost
items.forEach(async (item) => await save(item));

// Sequential when parallel is safe
const a = await fetchA();
const b = await fetchB();  // use Promise.all instead
```

Flag: async calls without `await`/`.catch()`, `forEach` with `async` callback, sequential `await` on independent calls.

## Null/Undefined Access

```ts
const name = user.profile.name;  // throws if profile is null/undefined
arr[0].id;                        // throws on empty array
```

Flag: property chains without `?.` on API values, array index access without bounds check, non-null assertions (`!`) without verification.

## Closure Variable Capture

```js
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);  // prints 3, 3, 3
}
```

React stale closure: `useEffect`/`useCallback` with missing dependency array entries closes over stale render values.

Flag: `var` in loops with callbacks, missing deps in React hooks.

## Array Method Gotchas

```js
[3, 10, 2].sort()       // [10, 2, 3] — lexicographic, not numeric
[NaN].indexOf(NaN)      // -1 — use .includes() instead
original.sort()          // mutates original — use .toSorted() or [...arr].sort()
```

## Object Reference Sharing

```js
const copy = { ...original };   // shallow — nested objects still shared
copy.nested.value = 1;          // mutates original.nested.value
Object.freeze(obj)              // shallow freeze — nested objects still mutable
```

Flag: spread copies passed to mutating functions, `Object.freeze` assumed to deep-freeze, direct state mutations in React (`state.items.push(x)`).

## Error Handling

```ts
try { ... } catch (e) {}                // swallowed — failure invisible
try { ... } catch (e) { log(e.message); }  // e is unknown — crashes if not Error
```

Flag: empty catch blocks, accessing `.message`/`.stack` without `instanceof Error` guard, catch that logs but doesn't rethrow when caller needs to know.

## RegExp Stateful `lastIndex`

```js
const re = /foo/g;
re.test("foo bar");  // true  — lastIndex now 3
re.test("foo bar");  // false — resumes from index 3, misses match
```

Flag: module-level `/g` regex reused across calls. Fix: create fresh regex per call or reset `re.lastIndex = 0`.
