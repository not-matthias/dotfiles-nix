# Nix/NixOS Pitfalls

## Lazy Evaluation

**Delayed error detection** — `x = 1 / 0;` doesn't error until `x` is used. The real culprit can be far from the stack trace.

**Infinite recursion in `rec {}`**
```nix
let a = 1; in rec { a = a; }  # infinite recursion — shadows outer `a`
```
Prefer `let ... in` over `rec {}` when possible.

**`if` vs `mkIf` on config**
```nix
# BUG: infinite recursion — config.services.foo.enable depends on itself
services.bar.enable = if config.services.foo.enable then true else false;
```
Use `lib.mkIf config.services.foo.enable { ... }` instead. `mkIf` defers evaluation, breaking the cycle.

## Attribute Set Merging

**`//` is shallow**
```nix
{ a = { b = 1; c = 2; }; } // { a = { b = 99; }; }
# Result: { a = { b = 99; }; }  — c is gone
```
Use `lib.recursiveUpdate` or the module system for deep merges.

## String Interpolation and Paths

**Path interpolation copies to store** — `"${./foo.txt}"` copies at evaluation time. `src = ./.;` on a large directory pollutes the store and breaks caching.

**`toString` divergence** — `toString false` is `""` (empty string), not `"false"`.

**`x:x` vs `x: x`** — `x:x` is a URI string literal. `x: x` is a lambda. Always space after colon.

## Module System

**Priority ordering:**

| Call | Priority |
|------|----------|
| `lib.mkDefault x` | 1000 (lowest) |
| plain `x` | 100 |
| `lib.mkForce x` | 50 (highest) |

`mkDefault` silently loses to plain assignments. Conflicts at same priority are hard errors.

**Conditional imports cause infinite recursion**
```nix
# BUG — config isn't resolved during import collection
imports = if config.myModule.enable then [ ./sub.nix ] else [];
```
Use `lib.mkIf` inside the module body, not to gate `imports`.

## Overlays

**`self`/`final` vs `prev`**
```nix
# BUG: infinite recursion
final: prev: { firefox = final.firefox.override { ... }; }
```
Use `prev` when overriding existing packages. Use `final` only for new attributes that need the fully-resolved set.

**Order dependence** — overlays applied later win. Two overlays overriding the same attribute produce order-dependent results.

## Flakes

**Untracked files are invisible** — files not `git add`-ed don't exist to the evaluator. No error, silent absence.

**`follows` is not transitive** — `inputs.foo.inputs.nixpkgs.follows = "nixpkgs"` only pins that one input. Other inputs inside `foo` that also use nixpkgs are unaffected.

**Impure `<nixpkgs>`** — `import <nixpkgs>` reads `$NIX_PATH`, defeats the lock file. Always thread nixpkgs from `inputs`.

## Derivations

**`nativeBuildInputs` vs `buildInputs`** — `nativeBuildInputs` = build host only (compilers, pkg-config). `buildInputs` = propagated to runtime closure. Mixing them up bloats closures or breaks linking.

**`autoPatchelfHook` misses `dlopen`** — dynamically loaded libraries must go in `runtimeDependencies` manually.

## `with` Scope

**Shadowing is invisible**
```nix
with pkgs; let curl = "my-curl"; in curl  # returns "my-curl", not pkgs.curl
```
`let` beats `with`, but the override is invisible at the call site. Prefer explicit `pkgs.somePackage`.

**Static analysis is blind** — `deadnix` and IDE completion can't see inside `with` scope.

## Silent Surprises

**Integer overflow wraps silently** — `9223372036854775807 + 1` wraps to negative with no error.

**`replaceStrings [""] ["-"] "ab"`** — empty match string matches between every char: `"-a-b-"`.
