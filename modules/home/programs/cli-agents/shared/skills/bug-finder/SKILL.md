---
name: bug-finder
description: Find bugs and verify correctness in code changes. Use when
  reviewing a PR, staged diff, or specific code the user points at. Hunts
  for logic errors, security flaws, race conditions, resource leaks, and
  API misuse. Produces evidence-based findings with concrete failure
  scenarios. Does NOT flag style, formatting, or naming issues.
---

<!--
Sources:
- https://google.github.io/eng-practices/review/reviewer/looking-for.html
- https://cheatsheetseries.owasp.org/cheatsheets/Secure_Code_Review_Cheat_Sheet.html
- https://github.com/codexstar69/bug-hunter
- https://github.com/sanyuan0704/sanyuan-skills/blob/main/skills/code-review-expert/SKILL.md
- https://github.com/0xiehnnkta/nemesis-auditor (Feynman auditor technique)
- https://github.com/NoahMasterball/noahmasterball.github.io (flow-divergence analysis, false-positive anti-patterns)
- https://github.com/samzong/samzong (iron law: no trigger = not a bug)
- https://github.com/sendou-ink/sendou.ink (only flag new code)
-->

# Bug Finder

Find bugs. Verify correctness. Ignore style.

**Iron law: never report a bug without a concrete trigger, a real failure mode, and a severe consequence.**

Hard cap: **15 findings max** per review. If you find more, keep only the highest severity. Inflation erodes trust.

## When to Use

- User asks to review a PR, diff, or specific code
- User asks to check code for bugs or correctness
- Before merging or shipping a change

## What to Look For

**Hunt these (ordered by severity):**

1. **Correctness** — Logic errors, off-by-ones, wrong comparisons, unreachable code, broken invariants, incorrect state transitions
2. **Security** — Injection, auth bypass, data exposure, unsafe deserialization, missing input validation at system boundaries, secret leakage
3. **Concurrency** — Race conditions, deadlocks, missing synchronization, shared mutable state without protection
4. **Error handling** — Silent failures, swallowed exceptions, missing error propagation, unhandled edge cases that crash at runtime
5. **Resource management** — Leaks (memory, file handles, connections), missing cleanup, unbounded growth
6. **API misuse** — Wrong function for the job, violated contracts, deprecated calls with known bugs, incorrect argument ordering
7. **Performance** — Only when it causes real problems: algorithmic blowup, N+1 queries, hot-path allocations, unbounded retries

**Ignore these (they belong to linters and minimal-diff):**

- Style, formatting, whitespace
- Naming preferences
- Code structure opinions
- Missing comments or docs
- Import ordering
- "I would have done it differently" without a concrete failure scenario

## Workflow

### Step 1: Gather Context

Adapt to what the user gives you:

- **PR**: Read the full diff via `gh pr diff`. Read the PR description. Identify what the change is supposed to do.
- **Staged changes**: Run `git diff --staged` (or `git diff` for unstaged). Understand the intent from recent commits or user description.
- **Pointed code**: Read the file(s) the user indicated. Ask what the code is supposed to do if unclear.

Before hunting, identify the **critical paths** — code that handles auth, payments, data writes, user input, or concurrency. These get the most scrutiny.

**Scope rule for diff-based reviews:** only flag issues in **changed or new code**. Pre-existing issues in untouched code are out of scope unless the change makes them reachable in a new way.

### Step 2: Hunt

Walk through the code change systematically. For each issue found, record:

- Exact location (`file:line`)
- What's wrong
- A **concrete failure scenario**: specific input, state, or sequence of events that triggers the bug

The failure scenario is mandatory. If you cannot construct one, the finding is not real — drop it.

**Boundary analysis:**
- What happens at boundaries? (empty input, max values, nil/null/None, zero-length, unicode)
- What happens under concurrency? (two requests at once, interrupted operations)
- What happens on failure? (network down, disk full, permission denied, timeout)
- What assumptions does this code make? Are they guaranteed by callers?
- Does the error handling actually handle the error, or does it just log and continue?

**Feynman technique** — for each non-obvious function or block, ask:
1. **Why does this line exist?** If you can't explain it, that's where bugs hide.
2. **What if this line were removed?** Would anything break? Would the bug surface?
3. **What if this check didn't exist?** What bad state would flow through?
4. **Does this function's assumption hold across all callers?** Trace backwards.

**Flow-divergence analysis** — look for two code paths that should behave identically but don't. Check: do both paths handle errors the same way? Do both paths update the same state? If one path has a guard, should the other?

For language-specific pitfalls, consult the references:
- Rust: [references/rust.md](references/rust.md)
- TypeScript: [references/typescript.md](references/typescript.md)
- Python: [references/python.md](references/python.md)
- Nix: [references/nix.md](references/nix.md)

### Step 3: Skeptic Pass

Re-examine every finding. For each one, ask:

1. **Can I actually trigger this?** Trace the call chain. Is the bad input reachable? Is the race condition possible given the actual usage pattern?
2. **Does the surrounding code already prevent this?** Check for guards, validation, or constraints upstream that make the scenario impossible.
3. **Am I assuming something about the runtime/framework that isn't true?** (e.g., "this isn't thread-safe" when the framework guarantees single-threaded execution)
4. **Is this a real bug or a theoretical concern?** If it requires an attacker with root access or a cosmic ray to trigger, drop it.

**Common false-positive anti-patterns** — drop findings that match these:
1. "Path A does X, path B doesn't" — check if the context makes X unnecessary on path B.
2. "This isn't thread-safe" — check if the framework/runtime guarantees single-threaded execution.
3. "Missing null check" — check if the type system or upstream validation already prevents null.
4. "Resource leak" — check if an RAII guard, defer, or context manager already handles cleanup.
5. "Unbounded input" — check if the caller/transport layer enforces limits before this code runs.

Drop any finding that fails the skeptic check. False positives waste the user's time and erode trust.

### Step 4: Classify

Assign severity to surviving findings:

| Severity | Meaning | Examples |
|----------|---------|---------|
| **CRITICAL** | Will break in production. Data loss, security breach, crash. | SQL injection, use-after-free, auth bypass |
| **HIGH** | Likely to break under realistic conditions. | Race condition on shared state, missing null check on user input |
| **MEDIUM** | Breaks under edge cases or degrades correctness. | Off-by-one in pagination, resource leak on error path |
| **LOW** | Unlikely to cause user-visible issues but still wrong. | Redundant check, minor perf issue on cold path |

### Step 5: Report

Output findings sorted by severity (worst first). One line per finding:

```
file:line — [CRITICAL] Description. Breaks when: scenario.
file:line — [HIGH] Description. Breaks when: scenario.
```

End with a summary line:

```
N findings: X critical, Y high, Z medium, W low
```

If zero findings survive the skeptic pass, say so:

```
No issues found.
```

## Rules

- Every finding MUST have a concrete failure scenario. No scenario = not a real finding.
- Do not pad the report. Zero findings is a valid outcome.
- Do not suggest refactors, style changes, or "improvements" unless they fix a bug.
- Do not flag code for being "complex" unless the complexity causes an actual defect.
- When unsure if something is a bug, say so explicitly rather than presenting it as certain.
- Failure scenarios should be specific enough to turn into a test case.

## Resources

- [references/rust.md](references/rust.md) — Rust-specific pitfalls (unsafe, lifetimes, Send/Sync, unwrap)
- [references/typescript.md](references/typescript.md) — TypeScript pitfalls (any casts, null coercion, async errors)
- [references/python.md](references/python.md) — Python pitfalls (mutable defaults, GIL, exception handling)
- [references/nix.md](references/nix.md) — Nix pitfalls (lazy eval, infinite recursion, override gotchas)

## Common Issues

**Issue**: Too many findings — review feels noisy.
- Re-run the skeptic pass more aggressively. Group related findings under one root cause.

**Issue**: User disagrees with a finding.
- Accept it. Do not argue. The user has context you don't.

**Issue**: Not enough context to judge correctness.
- Ask the user what the code is supposed to do. Don't guess intent.
