---
description: Use samply instead of perf for CPU profiling
condition: '(?:^|[;&|()\n])\s*(?:sudo(?:\s+-\S+)*\s+)?(?:[^\s;&|()]+/)?perf(?=$|[\s;&|()<>])'
scope:
  - tool:bash
interruptMode: always
---

Use `samply` instead of the `perf` CLI for CPU profiling. Read the `samply-profiler` skill for capture and analysis workflows. Use `samply record --save-only -o <profile> -- <command> <args>` to capture without opening a browser.

Do not fall back to `perf` when capture fails; diagnose the samply failure. If the task requires a perf-specific capability that samply does not provide, explain the limitation rather than silently substituting a different measurement.
