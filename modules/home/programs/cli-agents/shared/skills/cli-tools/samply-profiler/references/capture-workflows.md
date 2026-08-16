# Samply Capture Workflows

Use this reference when the user asks the agent to collect a new profile instead of only analyzing an existing `profile.json.gz`.

## Capture Principles

- Profile a reproducible workload, not a vague manual session.
- Prefer optimized or production-like builds unless the user asks about debug-mode behavior.
- Keep debug symbols available for symbolication.
- Use `--save-only` so the capture is available as a file for offline analysis.
- Collect enough samples to make percentages meaningful. Repeat very short commands or increase runtime.
- For before/after work, change one thing at a time and keep capture settings identical.

## One-Shot Benchmark Command

Use this for commands that run long enough to collect useful samples:

```bash
samply record --save-only -o /tmp/profile.json.gz -- <benchmark-command> <args>
```

Examples:

```bash
samply record --save-only -o /tmp/profile.json.gz -- ./target/release/app --input data.json
samply record --save-only -o /tmp/profile.json.gz -- cargo test --release benchmark_name -- --nocapture
```

## Short Commands

If the command finishes too quickly, repeat it inside samply:

```bash
samply record --save-only -o /tmp/profile.json.gz --iteration-count 30 -- <short-command> <args>
```

Increase the iteration count until the profile contains enough samples on the workload thread. Avoid wrapping the command in shell loops unless the shell overhead is part of what the user wants to measure.

## Long-Running Processes

On Linux, attach to an existing process by PID:

```bash
samply record --save-only -o /tmp/profile.json.gz --duration 30 --pid <pid>
```

If the process has many idle/helper threads, use the analyzer's `threads` command before deciding which thread to inspect.

## Whole-System Captures

On Linux, `--all` captures all processes. Use it only when the bottleneck may be outside the target process:

```bash
samply record --save-only -o /tmp/system-profile.json.gz --duration 30 --all
```

Whole-system profiles are noisier. Report the process/thread selection explicitly.

## Symbol-Friendly Captures

Keep or provide symbols when possible:

```bash
samply record --save-only \
  --symbol-dir ./target/release/deps \
  -o /tmp/profile.json.gz \
  -- ./target/release/app
```

If the profile will be analyzed on another machine, consider preserving samply's gathered symbol information:

```bash
samply record --save-only --unstable-presymbolicate -o /tmp/profile.json.gz -- <command>
```

`--unstable-presymbolicate` may create sidecar files. Keep those files next to the profile.

## Before/After Captures

Use matching names and identical settings:

```bash
samply record --save-only --profile-name baseline -o /tmp/baseline.json.gz -- <benchmark-command>
# apply one change
samply record --save-only --profile-name candidate -o /tmp/candidate.json.gz -- <benchmark-command>
```

When reporting differences, include:

- The exact command.
- Whether the binary changed.
- The number of samples in the selected thread for each profile.
- Major shifts in self time and total time.
- Any unresolved symbol differences.

## Common Capture Problems

- **Profile has too few samples**: Increase runtime, use `--iteration-count`, or profile a larger input.
- **Mostly runtime or harness frames**: Pick the workload thread explicitly with `--thread N`, or profile a narrower command.
- **Symbols are missing**: Rebuild with debug info, keep the exact binary, use `--symbol-dir`, or pass `--binary` to the analyzer.
- **Capture opens the browser**: Add `--save-only`.
- **Huge profile files**: Lower `--rate`, reduce `--duration`, or capture only the target process instead of `--all`.
