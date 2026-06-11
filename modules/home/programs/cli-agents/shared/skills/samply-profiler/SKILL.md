---
name: samply-profiler
description: Use when running samply to capture CPU profiles, profiling benchmark commands, analyzing `profile.json.gz` or `profile.json` files emitted by samply, working with Firefox Profiler captures or profiler.firefox.com URLs, finding CPU hot paths, resolving symbols, reading call trees, or comparing sampled performance profiles.
license: MIT
---

<!--
Sources:
- https://agentskills.io/llms.txt
- https://agentskills.io/skill-creation/using-scripts.md
- https://github.com/firefox-devtools/profiler
- https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/gecko-profile-format.md
- https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/processed-profile-format.md
- https://github.com/mstange/samply
-->

# Samply Profiling and Analysis

Run `samply` to capture CPU profiles for benchmark commands, then analyze the resulting Firefox Profiler JSON offline. The bundled analyzer extracts thread lists, libraries, flat hot functions, and top-down call trees from `profile.json.gz` files.

## When to Use

- The user wants to profile a benchmark, CLI command, test case, service, or existing process with `samply`.
- The user provides a `profile.json`, `profile.json.gz`, or `profiler.firefox.com/from-url/...` link.
- The user asks which functions, threads, or call chains consume CPU time.
- The user wants to compare profile captures before and after an optimization.
- The user needs offline symbolication for raw hex frames such as `0x1234abcd`.

## Prerequisites

- `samply` for recording profiles.
- `uv` for running the bundled Python analyzer.
- `addr2line`, `llvm-symbolizer`, or similar symbol tools if raw addresses need resolving.
- A reproducible benchmark command or workload when collecting new profiles.

## Workflow

### 1. Define the Workload

Profile a repeatable command. Prefer an existing benchmark or test harness over ad-hoc manual interaction.

Record these details before profiling:

- Exact command and arguments.
- Build mode and binary path.
- Input data size or scenario.
- Sampling rate, duration, and iteration count.
- Machine load and any background services that may affect measurements.

For compiled languages, profile an optimized build unless the user explicitly wants debug-mode behavior. Keep debug symbols available for symbolication.

### 2. Capture with Samply

Use `--save-only` so the agent gets a local profile file without depending on the browser UI.

```bash
samply record --save-only -o /tmp/profile.json.gz -- <benchmark-command> <args>
```

For very short commands, run repeated iterations so the profile has enough samples:

```bash
samply record --save-only -o /tmp/profile.json.gz --iteration-count 30 -- <short-command> <args>
```

For long-running services or benchmark servers on Linux, attach to the existing process for a fixed duration:

```bash
samply record --save-only -o /tmp/profile.json.gz --duration 30 --pid <pid>
```

Useful capture options:

| Option                      | Use when                                                                                              |
| --------------------------- | ----------------------------------------------------------------------------------------------------- |
| `--rate <hz>`               | Adjust sampling frequency. Default is usually enough; lower it if overhead or file size is a problem. |
| `--duration <seconds>`      | Bound captures of long-running processes.                                                             |
| `--iteration-count <n>`     | Repeat short benchmark commands to collect enough samples.                                            |
| `--profile-name <name>`     | Label captures clearly, especially before/after runs.                                                 |
| `--symbol-dir <dir>`        | Point samply at separate debug symbols.                                                               |
| `--unstable-presymbolicate` | Preserve gathered symbol data next to the profile when future symbol access may be hard.              |

For before/after comparisons, keep the command, inputs, sampling rate, duration, iteration count, build mode, and machine conditions the same.

### 3. Inspect Threads and Libraries

Resolve the analyzer path relative to this skill directory.

```bash
SKILL_DIR=/path/to/samply-profiler
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz threads
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz libs
```

Pick the hottest workload thread by sample count unless the user points to a specific thread. Verify it is not an idle thread, runtime helper, or background service thread.

### 4. Find Hot Functions

```bash
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz flat --auto --top 40
```

Use self time to identify leaf work that directly burns CPU. Use total time to identify high-level routines that contain the hot work.

### 5. Resolve Symbols

If frames are raw hex addresses, resolve them with `addr2line`:

```bash
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz flat --auto --resolve --top 40
```

If auto-detection cannot find the original binary path from `libs[]`, provide it explicitly:

```bash
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz flat --auto --resolve --binary ./target/release/my-binary
```

### 6. Extract the Call Tree

```bash
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz tree --auto --depth 12 --min-pct 1.0
```

Read the tree top-down. The percentages are inclusive sample percentages; `self=` marks leaf time spent directly in that frame.

## Interpretation Checklist

- **Thread choice**: Confirm the thread with the most samples is the workload thread, not a runtime helper or idle thread.
- **Self vs total**: Treat high self time as direct CPU work; treat high total time as a parent scope containing a bottleneck.
- **Dominant chain**: Report the hottest top-down call chain before individual leaf functions.
- **Runtime noise**: Separate allocator, panic formatting, logging, synchronization, and test harness overhead from the target workload.
- **Symbol quality**: If many frames remain unresolved, check that the binary path matches the captured executable and includes debug info.
- **Before/after comparisons**: Compare the same workload, sampling interval, binary mode, and input size.

## Firefox Profiler Data Model

- `threads[].samples.stack` indexes into `stackTable`.
- `stackTable.frame` indexes into `frameTable`; `stackTable.prefix` walks toward the root.
- `frameTable.func` indexes into `funcTable`.
- `funcTable.name` indexes into `stringArray` or `stringTable`.
- Recent processed-profile versions may store `stackTable`, `frameTable`, `funcTable`, `resourceTable`, and `stringArray` under top-level `shared`; older samply captures often store them per thread.
- `libs[]` records library and binary paths used for offline symbolication.

## Reporting Template

```markdown
## Profile Summary

- Capture: `<path>`
- Command: `<samply record ... -- command>` or `<provided profile>`
- Settings: rate `<hz>`, duration `<seconds or n/a>`, iterations `<n or n/a>`
- Thread: `[N] <name>` with `<samples>` samples
- Symbol status: `<resolved/partially resolved/unresolved>`
- Main bottleneck: `<one sentence>`

## Hottest Call Chain

1. `<root or entry>` – `<pct>%`
2. `<parent>` – `<pct>%`
3. `<leaf>` – `<pct>% self`

## Hot Functions

| Self % | Total % | Function | Note |
| -----: | ------: | -------- | ---- |
|    ... |     ... | ...      | ...  |

## Recommendations

1. `<specific optimization or next measurement>`
```

## Common Issues

- **Firefox Profiler UI blocks automation**: Fetch the raw `profile.json` URL with `curl`; do not rely on headless browser automation.
- **Auto symbolication fails**: The captured `libs[].path` may point to a path on another machine. Use `--binary`.
- **Addresses remain unresolved**: Rebuild with debug info or use the exact binary captured by samply.
- **Unexpected hottest thread**: List all threads and choose the workload thread explicitly with `--thread N`.
- **Small profiles are noisy**: Repeat the capture or increase runtime before making optimization decisions.

## Resources

- `scripts/analyze_profile.py` – main offline analyzer for threads, libraries, flat hot spots, call trees, and `addr2line` symbolication.
- `references/capture-workflows.md` – detailed `samply record` recipes for benchmark commands, short commands, services, and before/after captures.
- `references/scripts.md` – bundled script interface, rationale, and optional future scripts.
- `references/firefox-profiler-format.md` – compact reference for Firefox Profiler table relationships.
