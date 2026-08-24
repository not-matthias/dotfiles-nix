---
name: rust-tests-release-mode
description: "Always run Rust tests in release mode with --release"
condition: "cargo(?:\\s+\\+\\S+)?\\s+(?:test|insta\\s+test|nextest\\s+run)(?![^\\n]*--release)"
scope: "tool:bash"
---

Always run Rust tests in release mode. Add `--release` to every `cargo test` / `cargo nextest run` / `cargo insta test` invocation (e.g. `cargo test --release -p memtrack-parser`). Debug-mode test runs are not acceptable here — release builds catch optimization-dependent behavior and match how the suite is expected to run.
