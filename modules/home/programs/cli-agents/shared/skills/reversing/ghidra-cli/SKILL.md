---
name: ghidra-cli
description: Guide to using ghidra-cli for headless Ghidra automation. Use when analyzing binaries, decompiling functions, searching for patterns, tracing cross-references, patching bytes, or running automated reverse engineering workflows.
license: MIT
---

# ghidra-cli

Rust CLI that drives Ghidra headlessly via a persistent Java bridge process. Sub-second queries because Ghidra stays loaded in memory between commands.

## Architecture

```
ghidra-cli  ──TCP──▶  GhidraCliBridge.java (Ghidra JVM, auto-started)
```

One bridge per project, keyed by `~/.local/share/ghidra-cli/bridge-{md5}.port`. Commands auto-start the bridge if it isn't running.

## First-Time Setup

```bash
# Verify everything is found
ghidra-cli doctor
```

On NixOS, `GHIDRA_INSTALL_DIR` and `java` in PATH are injected automatically by the Nix wrapper — no manual config needed. `doctor` should show all green out of the box.

## Typical Workflow

```bash
# 1. Import binary and run analysis (bridge auto-starts)
ghidra-cli import ./target --project myproject --program target
ghidra-cli analyze --project myproject --program target

# 2. Explore
ghidra-cli stats
ghidra-cli function list
ghidra-cli find interesting

# 3. Drill into a function
ghidra-cli decompile main
ghidra-cli disasm 0x401000 --instructions 30

# 4. Trace references
ghidra-cli x-ref to 0x401000
ghidra-cli graph callers main --depth 2

# 5. Patch and export
ghidra-cli patch nop 0x401234 --count 3
ghidra-cli patch export -o patched.bin
```

## Commands

### Project & Program

```bash
ghidra-cli project create <name>
ghidra-cli project list
ghidra-cli import <binary> --project <p> --program <name>
ghidra-cli analyze --project <p>
```

### Function Analysis

```bash
ghidra-cli function list
ghidra-cli function list --filter "size > 100"
ghidra-cli decompile <name-or-addr>        # pseudocode
ghidra-cli disasm <addr> --instructions 20 # raw disassembly
```

### Symbols & Types

```bash
ghidra-cli symbol list
ghidra-cli symbol create <addr> <name>
ghidra-cli symbol rename <old> <new>
ghidra-cli type list
ghidra-cli type get <name>
```

### Cross-References

```bash
ghidra-cli x-ref to <addr>     # what calls/references this address
ghidra-cli x-ref from <addr>   # what this address calls/references
```

### Search

```bash
ghidra-cli find string "password"
ghidra-cli find bytes "90 90 90"
ghidra-cli find function "*crypt*"
ghidra-cli find crypto           # known crypto constants
ghidra-cli find interesting      # suspicious patterns (good starting point)
```

### Call Graphs

```bash
ghidra-cli graph callers <func> --depth 3   # who calls this?
ghidra-cli graph callees <func> --depth 3   # what does this call?
ghidra-cli graph export dot                 # export full graph as DOT
```

### Patching

```bash
ghidra-cli patch bytes <addr> "90 90"
ghidra-cli patch nop <addr> --count 5
ghidra-cli patch export -o patched.bin
```

### Comments

```bash
ghidra-cli comment get <addr>
ghidra-cli comment set <addr> "note" --comment-type EOL
ghidra-cli comment list
```

### Scripts

```bash
ghidra-cli script list
ghidra-cli script run myscript.py
ghidra-cli script python "print(currentProgram)"
```

### Bridge Control

```bash
ghidra-cli start --project <p> --program <name>   # explicit start
ghidra-cli status --project <p>
ghidra-cli stop --project <p>
ghidra-cli restart --project <p> --program <name>
```

### Misc

```bash
ghidra-cli stats                   # function/string/symbol counts
ghidra-cli summary                 # program metadata
ghidra-cli batch commands.txt      # run commands from file
```

## Filtering

Append `--filter "<expr>"` to list commands:

```bash
ghidra-cli function list --filter "size > 100"
ghidra-cli function list --filter "name contains 'main'"
ghidra-cli strings list --filter "length > 20"
```

## Output Formats

- TTY (default): compact human-readable
- Pipe (default): compact JSON
- `--json`: force compact JSON
- `--pretty`: force indented JSON
- `--fields "name,address,size"`: select specific fields

```bash
ghidra-cli function list --pretty
ghidra-cli function list --json | jq '.[] | select(.size > 500)'
```

## Multi-Project Concurrent Analysis

Each project runs its own bridge, so you can analyze multiple binaries in parallel:

```bash
ghidra-cli import ./a --project projA && ghidra-cli analyze --project projA &
ghidra-cli import ./b --project projB && ghidra-cli analyze --project projB &
wait
ghidra-cli function list --project projA
ghidra-cli function list --project projB
```

## AI-Assisted RE Workflow

Effective pattern for agent-driven analysis:

1. `ghidra-cli find interesting` — get a quick map of suspicious areas
2. `ghidra-cli decompile <func>` — read pseudocode of suspicious functions
3. `ghidra-cli x-ref to <addr>` — trace who reaches interesting code
4. `ghidra-cli graph callers <func> --depth 3` — understand call context
5. `ghidra-cli comment set <addr> "..."` — annotate findings inline
6. `ghidra-cli patch nop <addr>` + `patch export` — apply fixes

## Common Pitfalls

- **Binary not imported yet**: run `import` + `analyze` before querying. The bridge auto-starts but won't auto-import.
- **`--project` flag**: most commands accept `--project` to target a specific project; omit it only when there's a single active one.
- **`patch nop --count`**: parsed by CLI but bridge currently applies single-address NOP — patch each address explicitly if needed.
- **`--comment-type`**: only `EOL` is reliably supported; other types fall back silently.
- **Missing Java**: Ghidra needs JDK 17+, not just a JRE. On NixOS the `ghidra` package bundles its own JDK.
