---
name: samply-profiler
description: Use when capturing or analyzing samply CPU profiles, Rust tests or benchmarks, Firefox Profiler JSON, JSLB format failures, profiler.firefox.com captures, hot paths, call trees, or offline symbolication.
license: MIT
---

<!--
Sources:
- https://agentskills.io/llms.txt
- https://agentskills.io/skill-creation/using-scripts.md
- https://github.com/firefox-devtools/profiler
- https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/gecko-profile-format.md
- https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/processed-profile-format.md
- https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/CHANGELOG-formats.md
- https://github.com/mstange/json-slabs
- https://github.com/mstange/samply
-->

# Samply Profiling and Analysis

Capture reproducible CPU workloads with `samply`, then inspect the resulting Firefox Profiler profile offline or in the Firefox Profiler UI. The bundled analyzer handles gzip-compressed or plain Firefox Profiler **JSON**; it does not decode binary JSLB files.

## Route by the task

- **Capture a command, service, Rust test, or benchmark**: read [capture-workflows.md](references/capture-workflows.md).
- **A `.jslb`/`.jslb.gz` file or a format error** (`Could not parse the input file as JSON`, `LinuxPerf(UnrecognizedMagicValue)`): read [jslb-format.md](references/jslb-format.md) before renaming, importing, or converting the file.
- **Profile tables, stack walking, exact binary matching, or NixOS symbolication**: read [firefox-profiler-format.md](references/firefox-profiler-format.md).
- **Offline thread, library, flat-hotspot, or call-tree analysis**: read [scripts.md](references/scripts.md) and use the existing `scripts/analyze_profile.py` entry point.

## Basic capture

Prefer an optimized, reproducible workload and keep debug symbols available. Check the installed command's help for the presymbolication spelling; use the supported `--unstable-presymbolicate` or `--presymbolicate` option and retain any sidecars.

```bash
samply record --save-only --unstable-presymbolicate \
  -o /tmp/profile.json.gz -- <command> <args>
```

For a short command, repeat it rather than profiling shell-loop overhead:

```bash
samply record --save-only --unstable-presymbolicate \
  --iteration-count 30 -o /tmp/profile.json.gz -- <short-command> <args>
```

On Linux, attach to an existing process or capture the whole system only when needed:

```bash
samply record --save-only --unstable-presymbolicate \
  --duration 30 --pid <pid> -o /tmp/profile.json.gz
samply record --save-only --unstable-presymbolicate \
  --duration 30 --all -o /tmp/system-profile.json.gz
```

Use `--symbol-dir <dir>` for separate debug symbols. For before/after captures, hold command, inputs, build mode, sampling settings, and machine conditions constant.

## Analyze JSON profiles offline

Set the path to this skill directory; do not use a machine-specific skill path:

```bash
SKILL_DIR=/path/to/samply-profiler
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz threads
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz libs
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz \
  flat --auto --resolve --binary ./target/release/my-binary --top 40
uv run python "$SKILL_DIR/scripts/analyze_profile.py" /tmp/profile.json.gz \
  tree --auto --resolve --binary ./target/release/my-binary --depth 12 --min-pct 1.0
```

The analyzer accepts `profile.json`, `profile.json.gz`, or JSON on stdin. It lists threads and libraries, computes self-time and inclusive total-time rankings, walks top-down stacks, and resolves raw hexadecimal names through `addr2line`. Select the workload thread rather than an idle, runtime, GC, or helper thread. Treat small sample-count differences as noise until repeated captures confirm them.

## Interpretation

- **Self time** identifies leaf work directly sampled on CPU; **total time** identifies parents containing that work.
- Report the hottest top-down chain before individual leaf functions.
- Separate allocator, formatting, decoding, synchronization, logging, and test-harness overhead from the target workload.
- If symbols remain raw, use the exact executable captured by samply, retain debug info, or pass `--binary` explicitly.
- For comparisons, report the command, binary/build mode, selected thread and sample count, major self/total shifts, and unresolved symbols.

## Resources

- [capture-workflows.md](references/capture-workflows.md) — command, service, Rust test, Rust benchmark, short-command, and before/after recipes.
- [jslb-format.md](references/jslb-format.md) — conditional JSLB detection, `load` versus `import`, and support probing.
- [firefox-profiler-format.md](references/firefox-profiler-format.md) — profile tables, stack relationships, and exact offline symbolication.
- [scripts.md](references/scripts.md) — bundled analyzer interface and JSON-only limitation.
- `scripts/analyze_profile.py` — offline JSON profile analyzer.
