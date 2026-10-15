---
name: knife
description: "Use Knife (reknife) for static PE, ELF, Mach-O, or WebAssembly triage, disassembly, cross-references, dangerous-call auditing, annotations, and binary patch exports through CLI, TUI, or MCP."
---

# Knife

Use `knife` from [bl4ckr0ss3/knife](https://github.com/bl4ckr0ss3/knife), not Chef's command of the same name. Knife reads the target without executing it. Prefer the CLI with `--json` for scripted analysis; open the TUI only for interactive work.

Validated against Knife 1.8.3 on 2026-10-16. Check `knife --version` and `knife <command> --help` before using flags from newer upstream documentation. The Nix package is pinned: update its version and hash in dotfiles, then rebuild; do not replace the store binary with a self-updater or Cargo install.

## Static investigation

1. Identify the file with `knife hashes FILE` and `knife info FILE --json`. Record the SHA-256, format, architecture, and analysis limitations. For a cheap ELF-only inspection, use `knife headers FILE` and `knife segments FILE` without function recovery.
2. Establish the attack surface with `knife sec FILE`, `knife imports FILE`, and `knife sinks FILE`. Use `knife strings FILE` or `knife iocs FILE` for embedded text and indicators. Do not treat an import or string as proof of executed behavior.
3. Recover functions with `knife funcs FILE`. Inspect a function with `knife dis FILE --func NAME` and `knife pseudo FILE --func NAME`. Use `knife dis FILE --vaddr ADDRESS --count N` for bounded instruction output, or `--off OFFSET` for a file offset. Keep static virtual addresses, RVAs, and file offsets distinct in findings.
4. Follow evidence with `knife xrefs FILE TARGET`, or `knife xrefs FILE --str TEXT` for string references. Use `knife paths FILE TARGET` for call chains and `knife graph FILE --func NAME --dot` for a function CFG.
5. Run `knife audit FILE` to identify suspicious sink arguments. Use `--reachable` when restricting findings to discovered paths from entry points or exports. Inspect the actual instructions and callers before reporting a vulnerability: heuristic findings and reachability are not exploitability proofs, and indirect calls can leave gaps.
6. Report file identity, relevant function/address, observed instructions or references, and what remains inferred. Preserve tool diagnostics rather than silently treating unsupported analysis as an empty result.

## Formats and limits

- Use `knife drv FILE` for kernel-driver surfaces and signing information.
- Use `knife info`, `sections`, `imports`, `exports`, `strings`, and `hashes` for WebAssembly data inspection. Use `knife wat FILE` for its function table or WAT-style listing; inspect `knife wat --help` for selectors. Do not assume native disassembly or pseudocode supports WebAssembly.
- Treat recovered function boundaries and pseudocode as aids, not ground truth. Cross-check important claims against disassembly and file bytes.

## Persistent work and patches

- Names and notes persist in a database keyed by the file's SHA-256. Use `knife name FILE ADDR NAME`, `knife note FILE ADDR TEXT`, and `knife db FILE` to inspect saved work. Pass `--db PATH` for an isolated investigation database.
- Stage patches only when requested: `knife patch FILE --off OFFSET --bytes HEX` (or `--vaddr ADDR`). Export with `knife patch FILE --export NEW_PATH`. Staging records changes in the database; export writes a separate binary. Do not use `--force` without permission to replace that export.
- Record original and exported hashes and verify the intended bytes before reporting a patch as complete. Never execute an untrusted target as part of verification.

## TUI and MCP

- Start `knife tui FILE` for an interactive workspace. Bare `knife` opens a file explorer. Press `?` for current keybindings; `:` enters command mode.
- Start `knife mcp --file FILE` for a stdio MCP server bound to a target. It is a long-lived protocol server, not a command that prints one analysis result. Let the MCP client launch it, inspect its advertised tools, and keep protocol stdout free of shell chatter.
- Do not add an MCP server to agent configuration unless requested. CLI analysis needs no MCP setup.
