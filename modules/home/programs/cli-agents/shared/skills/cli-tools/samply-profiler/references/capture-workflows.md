# Samply Capture Workflows

Use this reference when collecting a new profile rather than only analyzing an existing `profile.json.gz`.

## Capture principles

- Profile a reproducible workload, not a vague manual session.
- Prefer optimized or production-like builds unless debug-mode behavior is the subject.
- Keep debug symbols available for symbolication.
- Use `--save-only` so the capture remains a local file.
- Check `samply record --help` for the installed presymbolication spelling (`--unstable-presymbolicate` or `--presymbolicate`) and retain generated sidecars beside the profile.
- Collect enough samples to make percentages meaningful; repeat short commands or increase runtime.
- For before/after work, change one thing at a time and keep capture settings identical.

## One-shot command

```bash
samply record --save-only --unstable-presymbolicate \
  -o /tmp/profile.json.gz -- <command> <args>
```

Use the supported presymbolication option from `samply record --help` if the example's spelling is unavailable. For separate debug symbols:

```bash
samply record --save-only --unstable-presymbolicate \
  --symbol-dir ./target/release/deps -o /tmp/profile.json.gz -- \
  ./target/release/app
```

## Short commands

Repeat a command inside samply when one invocation finishes too quickly:

```bash
samply record --save-only --unstable-presymbolicate \
  --iteration-count 30 -o /tmp/profile.json.gz -- <short-command> <args>
```

Increase the count until the workload thread has useful sample coverage. Do not wrap the command in a shell loop unless shell overhead is part of the question.

## Rust integration tests

Build a release test executable without running it. Keep the release profile's debug information available:

```bash
cargo test -p <crate> --test <name> --release --no-run
```

Locate the hashed executable under `target/release/deps/` and choose the file that is not the `.d` dependency file:

```bash
ls target/release/deps/<test-name>-*
```

Profile representative slow tests, not the whole suite. `--test-threads=1` keeps one selected test's work in one thread:

```bash
samply record --save-only --unstable-presymbolicate \
  -o /tmp/test-profile.json.gz -- \
  target/release/deps/<test-name>-<hash> "<test_filter>" --test-threads=1
```

Pass multiple filters when comparing a small set of representative tests. Then inspect threads and resolve against the exact test executable:

```bash
SKILL_DIR=/path/to/samply-profiler
BINARY=target/release/deps/<test-name>-<hash>
uv run python "$SKILL_DIR/scripts/analyze_profile.py" \
  /tmp/test-profile.json.gz threads
uv run python "$SKILL_DIR/scripts/analyze_profile.py" \
  /tmp/test-profile.json.gz flat --auto --resolve --binary "$BINARY" \
  --top 30 --thread <N>
uv run python "$SKILL_DIR/scripts/analyze_profile.py" \
  /tmp/test-profile.json.gz tree --auto --resolve --binary "$BINARY" \
  --depth 20 --min-pct 1.0 --thread <N>
```

Inspect self time for leaf CPU work such as allocation, formatting, or decoding; inspect total time for containing scopes. If formatting dominates, the text dump—not the analysis—may be the cost. For a multi-threaded run, list threads first and choose the hottest workload thread.

## Rust benchmarks (Cargo, divan, or criterion)

Build the named benchmark executable without running the suite:

```bash
cargo bench --bench <name> --no-run
```

Cargo places hashed executables in `target/release/deps/`; choose the benchmark executable, not its `.d` file:

```bash
ls target/release/deps/<bench-name>-*
```

The benchmark binary must retain debug symbols (for example, through the project's release profile). Capture either the executable directly or the same Cargo benchmark command used to select a framework target:

```bash
samply record --save-only --unstable-presymbolicate \
  -o /tmp/profile.json.gz -- \
  target/release/deps/<bench-name>-<hash> <bench-filter>

samply record --save-only --unstable-presymbolicate \
  -o /tmp/profile.json.gz -- \
  nix develop .#ci -c cargo bench --bench <name> -- <filter>
```

Keep Cargo's `--bench <name>` selector for divan/criterion targets. If the framework's own help requires an explicit benchmark-mode argument when invoking the executable directly, pass that argument after `--`; do not silently replace it with a package-only command. For a heavy divan benchmark, use its configured `sample_count = 1` and `sample_size = 1` when startup/code-generation cost is the subject and a full multi-hour run is not useful.

Analyze against the exact hashed benchmark executable:

```bash
SKILL_DIR=/path/to/samply-profiler
BINARY=target/release/deps/<bench-name>-<hash>
uv run python "$SKILL_DIR/scripts/analyze_profile.py" \
  /tmp/profile.json.gz threads
uv run python "$SKILL_DIR/scripts/analyze_profile.py" \
  /tmp/profile.json.gz flat --auto --resolve --binary "$BINARY" --top 40
uv run python "$SKILL_DIR/scripts/analyze_profile.py" \
  /tmp/profile.json.gz tree --auto --resolve --binary "$BINARY" \
  --depth 25 --min-pct 2.0
```

Choose the thread named for the benchmark executable rather than `nix`, `cargo`, or a GC/helper thread. Keep fixture, sample size, and build flags identical for before/after captures, and rebuild between captures.

## Long-running processes

On Linux, attach to an existing process for a fixed duration:

```bash
samply record --save-only --unstable-presymbolicate \
  --duration 30 --pid <pid> -o /tmp/profile.json.gz
```

List threads with the analyzer before selecting a thread when the process has idle or helper threads.

## Whole-system captures

Use `--all` only when the bottleneck may be outside the target process:

```bash
samply record --save-only --unstable-presymbolicate \
  --duration 30 --all -o /tmp/system-profile.json.gz
```

Whole-system profiles are noisy; report the process/thread selection explicitly.

## Before/after captures

Use matching names and identical settings:

```bash
samply record --save-only --unstable-presymbolicate \
  --profile-name baseline -o /tmp/baseline.json.gz -- <command>
# apply one change
samply record --save-only --unstable-presymbolicate \
  --profile-name candidate -o /tmp/candidate.json.gz -- <command>
```

Report the exact command, whether the binary changed, sample counts for the selected thread, major self/total-time shifts, and unresolved symbol differences.

## Common capture problems

- **Too few samples**: increase runtime, use `--iteration-count`, or profile a larger input.
- **Runtime or harness frames dominate**: select the workload thread explicitly with `--thread N`.
- **Symbols are missing**: rebuild with debug info, retain the exact executable, use `--symbol-dir`, or pass `--binary` to the analyzer. Keep presymbolication sidecars for future offline use.
- **Capture opens the browser**: add `--save-only`.
- **Profile is huge**: lower `--rate`, reduce `--duration`, or capture the target process instead of `--all`.
