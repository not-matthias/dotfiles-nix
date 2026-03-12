---
name: codspeed-bench
description: CodSpeed benchmarking integration for Rust and Python - execution modes, CI setup, cargo-codspeed patterns, and common gotchas.
license: MIT
---

# CodSpeed Benchmarking

Guide for integrating CodSpeed into Rust and Python projects, based on working with the codspeed-rust and related repositories.

## When to Use This Skill

- Setting up CodSpeed in a new project
- Adding benchmarks to CI
- Debugging mode configuration issues
- Supporting multiple benchmark frameworks (Criterion, Divan, Bencher)

## Three Execution Modes

| Mode | Runner env value | Runs on |
|------|-----------------|---------|
| `walltime` | `walltime` | `codspeed-macro` runner |
| `instrumentation` | `instrumentation` | `ubuntu-latest` |
| `memory` | `analysis` | `ubuntu-latest` |

**Critical gotcha:** The `memory` mode maps to `analysis` in the runner env var. This trips people up constantly.

```yaml
env:
  CODSPEED_RUNNER_MODE: ${{ matrix.mode == 'memory' && 'analysis' || matrix.mode }}
```

Set `CODSPEED_RUNNER_MODE` at the **job level**, not step level — `cargo-codspeed build` reads it during the build phase.

## CI Matrix Setup

```yaml
jobs:
  bench:
    strategy:
      matrix:
        package: [my-crate, my-other-crate]
        mode: [walltime, instrumentation, memory]
    runs-on: ${{ matrix.mode == 'walltime' && 'codspeed-macro' || 'ubuntu-latest' }}
    env:
      CODSPEED_RUNNER_MODE: ${{ matrix.mode == 'memory' && 'analysis' || matrix.mode }}
    steps:
      - uses: actions/checkout@v4
      - uses: moonrepo/setup-rust@v1
        with:
          cache: false  # Disable moonrepo cache when using musl + gnu targets
      - uses: Swatinem/rust-cache@v2
        with:
          shared-key: ${{ matrix.mode }}

      - name: Build benchmarks
        run: cargo codspeed build -p ${{ matrix.package }}

      - name: Run benchmarks
        uses: CodSpeedHQ/action@v3
        with:
          run: cargo codspeed run
          token: ${{ secrets.CODSPEED_TOKEN }}
```

## Cargo Commands

```bash
# Build benchmarks (reads CODSPEED_RUNNER_MODE)
cargo codspeed build -p <package>

# Run (after build)
cargo codspeed run

# Multiple instrument modes
cargo codspeed build -p <package> -m instrument1 -m instrument2

# Distributed test partitioning
cargo nextest run --partition hash:${{ partition }}/5

# MSRV check
cargo msrv --path crates/<name> verify -- cargo check --all-features
```

## Framework Support

| Framework | Crate | Notes |
|-----------|-------|-------|
| Criterion | `codspeed-criterion-compat` | async_futures feature available |
| Divan | `codspeed-divan-compat` | Requires black_box wrapping on inputs/outputs |
| Bencher | `codspeed-bencher-compat` | Direct compatibility layer |

**Divan gotcha:** Black-box wrapping must match the reference implementation in `divan_fork/` exactly. Wrong wrapping → compiler optimizes away the benchmark.

## FFI Bindings Validation

If your project has Zig/C FFI bindings (e.g., instrument hooks), add this CI check to catch stale bindings:

```yaml
- name: Check FFI bindings are up to date
  working-directory: crates/codspeed/src/instrument_hooks
  run: |
    ./update-bindings.sh
    if ! git diff --exit-code bindings.rs; then
      echo "Error: FFI bindings are out of date. Run update-bindings.sh"
      exit 1
    fi
```

## Multi-Architecture Builds

CodSpeed supports cross-compilation. Common targets:

```
arm-unknown-linux-gnueabihf
aarch64-unknown-linux-musl
i686-unknown-linux-gnu
i686-unknown-linux-musl
x86_64-unknown-linux-gnu
x86_64-unknown-linux-musl
aarch64-apple-darwin
x86_64-apple-darwin
x86_64-pc-windows-msvc
```

**Cache gotcha:** Sharing moonrepo/setup-rust cache across `linux-gnu` and `linux-musl` targets causes build failures. Use `cache: false` + `Swatinem/rust-cache` with `shared-key: ${{ matrix.job.target }}`.

## Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| Benchmarks not detected | Wrong mode in env | Ensure `CODSPEED_RUNNER_MODE` set at job level |
| `memory` mode fails | Wrong env value | Map `memory` → `analysis` in env var |
| Cache conflicts | moonrepo cross-target cache | Disable moonrepo cache, use Swatinem/rust-cache |
| Divan results wrong | Missing black_box wrapping | Wrap inputs AND outputs with `std::hint::black_box` |
| Feature flag syntax error | YAML quoting issue | Use `${{ condition && 'value' || 'fallback' }}` syntax |
