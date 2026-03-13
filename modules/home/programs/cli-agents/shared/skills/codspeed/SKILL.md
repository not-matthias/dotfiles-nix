---
name: codspeed
description: "CodSpeed platform architecture - runner, language integrations (Rust, Go, C++), instrument-hooks, shared protocols, result formats, and development patterns. Use when working on any CodSpeed repository."
license: MIT
---

# CodSpeed Platform

Comprehensive guide for working across the CodSpeed ecosystem: the runner CLI, language integrations, and shared infrastructure.

## Resources

- **LLM Context**: https://codspeed.io/docs/llms.txt (index) / https://codspeed.io/docs/llms-full.txt (full)
- **Repos** (all under `~/Documents/work/wgit/`): `runner`, `codspeed-rust`, `codspeed-go`, `codspeed-cpp`, `instrument-hooks`
- **Notes**: `codspeed-notes` (Obsidian vault with daily logs, architecture docs, snippets)

## Architecture Overview

```
                    ┌─────────────────────┐
                    │   CodSpeed Runner    │  Rust CLI (`codspeed run/exec`)
                    │   (Orchestrator)     │
                    └────────┬────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │ Valgrind   │  │ WallTime   │  │ Memory     │
     │ Executor   │  │ Executor   │  │ Executor   │
     │(simulation)│  │(systemd+   │  │(eBPF       │
     │            │  │ perf)      │  │ memtrack)  │
     └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           │
              FIFO Protocol (named pipes)
              /tmp/runner.ctl.fifo (commands)
              /tmp/runner.ack.fifo (responses)
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌──────────┐  ┌──────────┐  ┌──────────┐
     │codspeed- │  │codspeed- │  │codspeed- │  ...
     │  rust    │  │   go     │  │  cpp     │
     └────┬─────┘  └────┬─────┘  └────┬─────┘
          │              │              │
          └──────────────┼──────────────┘
                         ▼
              ┌─────────────────────┐
              │  instrument-hooks   │  Zig→C library
              │  (shared C API)     │  FFI from all languages
              └─────────────────────┘
```

## Three Measurement Modes

| Mode | Runner env value | Executor | Runs on | Precision |
|------|-----------------|----------|---------|-----------|
| `simulation` | `instrumentation` | Valgrind (Callgrind) | ubuntu-latest | <1% variance, deterministic |
| `walltime` | `walltime` | systemd-run + optional perf | codspeed-macro | Real-world, multiple rounds |
| `memory` | `analysis` | eBPF memtrack | ubuntu-latest | Heap allocation tracking |

**Critical gotcha:** The `memory` mode maps to `analysis` in `CODSPEED_RUNNER_MODE`, NOT `memory`.

## instrument-hooks (Shared C Library)

Written in **Zig**, compiled to a single C file (`dist/core.c`) for maximum portability.

### What It Does
Bridge between benchmark code and the CodSpeed runner via IPC (named pipes). Detects which profiling backend is active and provides a unified API.

### Detection Order
1. **ValgrindInstrument** — Callgrind API calls (synchronous, no FIFO)
2. **PerfInstrument** — Linux perf (FIFO protocol v2)
3. **AnalysisInstrument** — Lightweight analysis (FIFO protocol v2)

First successful probe wins.

### FIFO Protocol (v2)
- `/tmp/runner.ctl.fifo` — client → runner commands
- `/tmp/runner.ack.fifo` — runner → client responses
- **Format:** 4-byte LE length prefix + bincode-serialized payload

**Commands:**
| Command | Direction | Purpose |
|---------|-----------|---------|
| SetVersion | C→R | Protocol version negotiation |
| StartBenchmark | C→R | Begin profiling window |
| StopBenchmark | C→R | End profiling window |
| SetIntegration | C→R | Register integration name/version |
| ExecutedBenchmark | C→R | Report completed benchmark URI |
| AddMarker | C→R | Insert timestamp marker |
| GetIntegrationMode | C→R | Query active mode |

**Marker types:** `MARKER_TYPE_SAMPLE_START` (247), `MARKER_TYPE_SAMPLE_END` (248), `MARKER_TYPE_BENCHMARK_START` (249), `MARKER_TYPE_BENCHMARK_END` (250)

### C API
```c
InstrumentHooks* instrument_hooks_init();
void instrument_hooks_deinit(InstrumentHooks*);
bool instrument_hooks_is_instrumented(InstrumentHooks*);
int instrument_hooks_start_benchmark(InstrumentHooks*);
int instrument_hooks_stop_benchmark(InstrumentHooks*);
void instrument_hooks_set_executed_benchmark(InstrumentHooks*, uint32_t pid, const uint8_t* uri);
void instrument_hooks_set_integration(InstrumentHooks*, const uint8_t* name, const uint8_t* version);
void instrument_hooks_add_marker(InstrumentHooks*, uint32_t pid, uint32_t type, uint64_t ts);
uint64_t instrument_hooks_current_timestamp();  // monotonic nanoseconds
void instrument_hooks_set_feature(uint32_t feature, bool enabled);
```

### Known Gotcha: Stale FIFO Messages
Named pipes are persistent kernel buffers. When one instrument type fails validation and closes the FIFO without draining, leftover messages corrupt the next instrument's initialization. Solution: `Reader::deinit()` drains all pending data before closing.

### Platform Support
Linux (x86_64, x86, ARM64, ARM, RISC-V, PowerPC64, s390x, MIPS64, LoongArch64 — glibc & musl), macOS (Intel & Apple Silicon), Windows (x86 & x86_64 MSVC).

## Runner (CLI Orchestrator)

Rust binary. Central engine that measures code performance.

### Key Commands
```bash
codspeed run -- <command>        # Run with existing harness (pytest, criterion, etc.)
codspeed exec -- <command>       # Run any command with exec-harness wrapper
codspeed setup                   # Pre-install tools
codspeed auth login              # Authenticate
codspeed use <mode>              # Set default instrument for session
codspeed show                    # Display current instrument
```

### Key Flags
- `--mode|-m simulation|walltime|memory` (can specify multiple for build)
- `--token` — Auth token
- `--skip-upload` / `--skip-run` — Two-phase execution
- `--enable-perf` — Enable Linux perf sampling (walltime)
- `--simulation-tool callgrind|tracegrind` — Valgrind backend

### Orchestrator Pattern
The `Orchestrator` coordinates:
1. CI environment detection (GitHub Actions, GitLab CI, Buildkite, Local)
2. Two target types:
   - **Exec targets**: Plain commands measured via exec-harness (combined into one execution per mode)
   - **Entrypoint targets**: Commands with built-in harnesses (each runs independently per mode)
3. Sequential execution across all configured modes
4. Artifact collection into profile folder
5. Archive (tar.gz) and upload to CodSpeed API

### Environment Variables Injected
| Variable | Value | Purpose |
|----------|-------|---------|
| `CODSPEED_RUNNER_MODE` | `instrumentation`/`walltime`/`memory` | Tell integration which mode |
| `CODSPEED_PROFILE_FOLDER` | Path | Where integrations write results |
| `CODSPEED_ENV` | `runner` | Identifies CodSpeed environment |
| `PYTHONHASHSEED` | `0` | Determinism (simulation/walltime) |

### Executor Details

**Valgrind:** `setarch <arch> -R valgrind --tool=callgrind --cache-sim=yes --trace-children=yes <script>`
- Disables ASLR for determinism
- Traces child processes

**WallTime:** `systemd-run --scope --slice=codspeed.slice -- bash <script>`
- Optional `perf record` for flamegraphs
- Pre/post-bench hooks support

**Memory:** Starts `codspeed-memtrack` (eBPF) with IPC server, enables/disables tracking per benchmark via FIFO signals.

## Shared Result Format (Walltime JSON)

All integrations output the same JSON schema to `$CODSPEED_PROFILE_FOLDER/results/{pid}.json`:

```json
{
  "creator": {"name": "codspeed-<lang>", "version": "x.y.z", "pid": 12345},
  "instrument": {"type": "walltime"},
  "benchmarks": [{
    "name": "BenchmarkFoo",
    "uri": "path/to/file.ext::Group::BenchmarkFoo[param]",
    "config": {
      "warmup_time_ns": null,
      "min_round_time_ns": null,
      "max_time_ns": null,
      "max_rounds": null
    },
    "stats": {
      "min_ns": 1000.0, "max_ns": 5000.0,
      "mean_ns": 2500.0, "stdev_ns": 1200.0,
      "q1_ns": 1800.0, "median_ns": 2300.0, "q3_ns": 3100.0,
      "rounds": 50, "total_time": 0.125,
      "iqr_outlier_rounds": 2, "stdev_outlier_rounds": 1,
      "iter_per_round": 1, "warmup_iters": 5
    }
  }]
}
```

**Statistics computed:** mean, stdev, quartiles (Q1/median/Q3), min/max, outlier detection (IQR: 1.5x factor, stdev: 3.0x factor).

## Benchmark URI Convention

All integrations construct URIs in the same format:
```
<git-relative-file-path>::<group1>::<group2>::<benchmark_name>[<parameter>]
```

Examples:
- Rust: `benches/lib.rs::arithmetic::add[1024]`
- Go: `example/fib_test.go::BenchmarkFibonacci20_Loop`
- C++: `benches/basic.cpp::string_ops::concat`

Git-relative paths ensure cross-machine consistency. Falls back to absolute path if not in a git repo.

## Language Integrations

### Common Patterns Across All Integrations

1. **Environment detection**: Check for `CODSPEED_ENV`/`CODSPEED_RUNNER_MODE` → enable instrumentation, else graceful fallback
2. **instrument-hooks FFI**: All link against the shared C library for profiling communication
3. **Framework wrapping**: Provide compatibility layers that intercept framework calls → redirect to CodSpeed measurement
4. **Warmup + measurement**: Fixed warmup iterations, then measured iteration(s)
5. **URI construction**: `git-relative-path::groups::name[params]`
6. **Result reporting**: JSON to `$CODSPEED_PROFILE_FOLDER/results/{pid}.json`

### codspeed-rust

**Location:** `~/Documents/work/wgit/codspeed-rust`

**Crates:**
| Crate | Purpose |
|-------|---------|
| `codspeed` | Core instrumentation (Valgrind client requests + instrument-hooks FFI) |
| `cargo-codspeed` | CLI: `cargo codspeed build` / `cargo codspeed run` |
| `codspeed-criterion-compat` | Drop-in replacement for criterion |
| `codspeed-bencher-compat` | Drop-in replacement for bencher |
| `codspeed-divan-compat` | Drop-in replacement for divan (proc macro) |

**Dual instrumentation detection:**
1. Valgrind: inline assembly client requests (`xchg rbx, rbx` on x86_64)
2. InstrumentHooks: C FFI (compiled via `build.rs`, falls back to no-op)

**Build flow:**
```bash
cargo codspeed build -p <package> [-m walltime] [-m simulation]
# → Invokes cargo build --benches with JSON output
# → Copies executables to .codspeed-target/<mode>/<package>/<name>

cargo codspeed run [--bench filter]
# → Discovers executables in .codspeed-target/
# → Runs each, sets CODSPEED_CARGO_WORKSPACE_ROOT
```

**Feature-gated wrappers:** `#[cfg(codspeed)]` enables CodSpeed measurement; `#[cfg(not(codspeed))]` uses original framework (zero overhead).

**Measurement:** `WARMUP_RUNS = 5` warmup iterations, then 1 measured iteration (simulation mode). Walltime mode uses criterion/divan fork for multiple rounds.

**Forked frameworks:** `codspeed-criterion-compat-walltime` and `codspeed-divan-compat-walltime` — forks with walltime harness support.

### codspeed-go

**Location:** `~/Documents/work/wgit/codspeed-go`

**Innovation:** Uses Go's `-overlay` flag to inject instrumentation into `$GOROOT/src/testing/` at compile time. **Zero user code changes required.**

**Three overlay files injected:**
1. `benchmark{1.24.0|1.25.0}.go` — Patched Go testing/benchmark.go (version-specific)
2. `codspeed.go` — CodSpeed measurement logic (SaveMeasurement, URI construction, result saving)
3. `instrument-hooks.go` — CGO FFI bindings to C library

**go-runner (Rust binary):**
```bash
go-runner test -bench . -benchtime 3s ./...
# 1. Detect Go version → select correct benchmark.go overlay
# 2. Download instrument-hooks C library (cached)
# 3. Generate overlay.json with template substitutions
# 4. Execute: go test -overlay overlay.json -bench ... -run=^$ ...
# 5. Collect raw_results/*.json → aggregate to results/{pid}.json
```

**Two-phase result pipeline:**
- Go writes per-benchmark raw JSON to `$CODSPEED_PROFILE_FOLDER/raw_results/{random_hex}.json`
- Rust runner aggregates (parallel via rayon) into `results/{pid}.json`, deletes raw files

**Key gotchas:**
- CGO required (`CGO_ENABLED=1`) — instrument-hooks.go uses C FFI
- Uses `$GOROOT/bin/go` directly (not PATH) to prevent runner recursion
- Custom CLI parser because Go uses single-dash multi-letter flags (`-bench`, `-benchtime`) incompatible with clap
- Timeout prevention: max 3x requested benchtime to prevent runaway
- Version-specific patches maintained as `.patch` files

**Supports:** `b.N` loop, `b.Loop()` (Go 1.25+), `b.Run()` nesting, `b.RunParallel()`

### codspeed-cpp

**Location:** `~/Documents/work/wgit/codspeed-cpp`

**Components:**
| Component | Purpose |
|-----------|---------|
| `codspeed-core` | Core measurement library (C++) |
| `codspeed-google-benchmark` | Google Benchmark compatibility layer |

**Singleton CodSpeed class** manages benchmark lifecycle:
- `push_group()` / `pop_group()` — group hierarchy
- `start_benchmark()` / `end_benchmark()` — measurement boundaries

**Measurement abstraction:** Inline functions (`ALWAYS_INLINE`) for minimal profiling overhead. Wraps instrument-hooks C API.

**Build systems:** CMake and Bazel
```cmake
set(CODSPEED_MODE "walltime")  # off, simulation, walltime, memory
```
```
--@codspeed_core//:codspeed_mode=walltime  # Bazel
```

**Preprocessor defines:** `CODSPEED_ENABLED`, `CODSPEED_SIMULATION`, `CODSPEED_WALLTIME`, `CODSPEED_MEMORY`, `CODSPEED_ROOT_DIR`

**URI generation:** `file.cpp::benchmark_name[args]` with compiler-specific lambda namespace extraction (Clang vs GCC differences).

**Downloads instrument-hooks via CMake FetchContent** during configuration.

## CI Setup (GitHub Actions)

```yaml
jobs:
  bench:
    strategy:
      matrix:
        mode: [walltime, instrumentation, memory]
    runs-on: ${{ matrix.mode == 'walltime' && 'codspeed-macro' || 'ubuntu-latest' }}
    env:
      CODSPEED_RUNNER_MODE: ${{ matrix.mode == 'memory' && 'analysis' || matrix.mode }}
    steps:
      - uses: actions/checkout@v4
      - name: Build benchmarks
        run: cargo codspeed build -p my-crate
      - name: Run benchmarks
        uses: CodSpeedHQ/action@v3
        with:
          run: cargo codspeed run
          token: ${{ secrets.CODSPEED_TOKEN }}
```

**Key:** Set `CODSPEED_RUNNER_MODE` at **job level**, not step level — build phase reads it.

## Configuration File (`codspeed.yml`)

```yaml
options:
  warmup-time: "duration"
  max-time: duration
benchmarks:
  - name: "my benchmark"
    exec: "command with args"
    options: { ... }  # Override global options
```

Searched in order: `codspeed.yml`, `codspeed.yaml`, `.codspeed.yml`, `.codspeed.yaml`

## Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| Benchmarks not detected | Wrong mode in env | Ensure `CODSPEED_RUNNER_MODE` set at job level |
| `memory` mode fails | Wrong env value | Map `memory` → `analysis` in env var |
| Cache conflicts | moonrepo cross-target cache | Disable moonrepo, use Swatinem/rust-cache |
| Divan results wrong | Missing black_box | Wrap inputs AND outputs with `std::hint::black_box` |
| Go CGO error | No C compiler | Install build-essential / Xcode CLI tools |
| Go runner recursion | go-runner in PATH | Runner uses $GOROOT/bin/go directly |
| Stale FIFO messages | Instrument detection order | Drain FIFO on deinit (fixed in instrument-hooks) |
| FFI bindings stale | Updated instrument-hooks | Run `update-bindings.sh`, check in CI |

## Development Workflow

### Adding a New Language Integration

1. Link against `instrument-hooks` C library (via FFI/CGO/etc.)
2. On init: call `instrument_hooks_init()`, check `is_instrumented()`
3. Call `set_integration(name, version)` to register
4. For each benchmark:
   - `start_benchmark()` → run benchmark → `stop_benchmark()`
   - Record timestamps via `current_timestamp()` + `add_marker()`
   - `set_executed_benchmark(pid, uri)` to report completion
5. Write walltime results JSON to `$CODSPEED_PROFILE_FOLDER/results/{pid}.json`
6. On shutdown: `instrument_hooks_deinit()`

### Testing Locally

```bash
# Rust
cargo codspeed build -p my-crate -m walltime
CODSPEED_ENV=runner cargo codspeed run

# Go
export CODSPEED_PROFILE_FOLDER=/tmp/codspeed
go-runner test -bench . -benchtime 3s ./...

# Any language via runner
codspeed run --skip-upload -- <benchmark command>
```

### Staging CI

Use custom runner branch and staging endpoints:
```yaml
env:
  CODSPEED_API_URL: https://7j3xul0pqk.execute-api.eu-west-1.amazonaws.com/dev/
  CODSPEED_UPLOAD_URL: https://ziymwhsich.execute-api.eu-west-1.amazonaws.com/upload
```
