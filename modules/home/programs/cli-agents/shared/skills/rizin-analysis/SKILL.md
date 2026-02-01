---
name: rizin-analysis
description: Guide to using Rizin and Radare2 for binary analysis - lookup instructions, functions, basic blocks, and control flow graphs. Use when analyzing binary structure, investigating control flow graphs, disassembling code, or exploring function calls and jumps.
license: MIT
---

# Rizin/Radare2 Binary Analysis

This skill provides practical guidance for analyzing binaries using Rizin (modern, faster fork of Radare2) or Radare2. Use this when you need to inspect binary code, understand function structure, trace control flow, or extract architectural information.

## When to Use This Skill

Apply this skill when:

- Analyzing binary structure and function boundaries
- Investigating control flow graphs (CFG) for lifting or decompilation
- Disassembling and understanding specific instructions
- Exploring function calls, jumps, and indirect branches
- Collecting metadata about functions (addresses, sizes, call patterns)
- Debugging or reverse-engineering compiled code

## Quick Start: Opening a Binary

### Rizin (Recommended - faster, more modern)

```bash
rizin /path/to/binary
```

### Radare2 (Legacy)

```bash
radare2 /path/to/binary
```

Both tools drop you into an interactive shell. Type `?` for help at any time.

## Core Commands

### Analyzing Functions

| Command               | Purpose                                        |
| --------------------- | ---------------------------------------------- |
| `aaa`                 | Analyze all functions (auto-analysis)          |
| `afL`                 | List all functions                             |
| `afl`                 | List functions (compact)                       |
| `pdf @ <addr>`        | Disassemble function at address (pretty-print) |
| `af <addr>`           | Define/analyze function at address             |
| `afn <name> @ <addr>` | Rename function at address                     |

**Example:**

```
# Analyze binary
[0x00000000]> aaa

# List functions
[0x00000000]> afl

# Show function at 0x401000
[0x00000000]> pdf @ 0x401000
```

### Viewing Instructions & Disassembly

| Command              | Purpose                                    |
| -------------------- | ------------------------------------------ |
| `pd <n>`             | Disassemble next N instructions            |
| `pd <n> @ <addr>`    | Disassemble N instructions at address      |
| `pdi <n>`            | Disassemble N instructions (simple format) |
| `pi <n>`             | Print instructions (raw, one per line)     |
| `px <size> @ <addr>` | Show hex dump at address                   |

**Example:**

```
# Show next 10 instructions
[0x401000]> pd 10

# Show 5 instructions at specific address
[0x401000]> pd 5 @ 0x401050

# Hex dump 32 bytes at address
[0x401000]> px 32 @ 0x401000
```

### Control Flow & Basic Blocks

| Command        | Purpose                                  |
| -------------- | ---------------------------------------- |
| `agf`          | Show ASCII graph of current function CFG |
| `agf @ <addr>` | Show CFG for function at address         |
| `agg`          | Generate DOT graph format CFG            |
| `agd`          | Generate detailed DOT graph              |
| `afb`          | List basic blocks in function            |

**Example:**

```
# View control flow of function at 0x401000
[0x401000]> agf @ 0x401000

# Export CFG as DOT for graphviz
[0x401000]> agd @ 0x401000 > cfg.dot
$ dot -Tpng cfg.dot -o cfg.png
```

### Navigation & Seeking

| Command       | Purpose                                                 |
| ------------- | ------------------------------------------------------- |
| `s <addr>`    | Seek to address                                         |
| `s -`         | Undo seek                                               |
| `s +<offset>` | Seek relative to current                                |
| `@ <addr>`    | One-time seek (append to commands)                      |
| `pwd`         | Print current seek position (working directory analogy) |

**Example:**

```
# Jump to function
[0x401000]> s 0x401050

# Show 10 instructions at current position
[0x401000]> pd 10

# Move forward 32 bytes
[0x401000]> s +0x20

# All in one line
[0x401000]> pd 10 @ 0x401050
```

### Function References & Calls

| Command      | Purpose                                            |
| ------------ | -------------------------------------------------- |
| `axt <addr>` | Show all xrefs TO address (who calls this?)        |
| `axf <addr>` | Show all xrefs FROM address (what does this call?) |
| `aflc`       | List functions with call count                     |
| `afi <addr>` | Show function info at address                      |

**Example:**

```
# Who calls function at 0x401000?
[0x401000]> axt 0x401000

# What does function at 0x401000 call?
[0x401000]> axf 0x401000

# Details about function
[0x401000]> afi 0x401000
```

## Practical Workflows

### Workflow 1: Lift a Specific Function

1. Open binary and analyze:

   ```bash
   $ rizin binary
   [0x00000000]> aaa
   ```

2. Find function boundaries:

   ```
   [0x00000000]> afl | grep -i "main\|target"
   ```

3. Examine function disassembly:

   ```
   [0x00000000]> pdf @ 0x401000
   ```

4. Check control flow:

   ```
   [0x00000000]> agf @ 0x401000
   ```

5. Extract address boundaries for lifter tools (e.g., `remill-lift`):
   ```
   [0x00000000]> afi 0x401000  # Shows size, basic blocks
   ```

### Workflow 2: Trace Call Graph

```bash
$ rizin binary
[0x00000000]> aaa

# Find entry point
[0x00000000]> e entry0

# View main function
[0x00000000]> pdf @ main

# See what main calls
[0x00000000]> axf @ main

# Follow a specific call
[0x00000000]> pdf @ 0x401500
```

### Workflow 3: Locate Indirect Jumps & Calls

Indirect jumps complicate lifting (symbolic execution needed):

```
[0x00000000]> aaa

# Find all instructions with indirect references
[0x00000000]> /i "jmp.*r\|call.*r"    # grep-style search for register jumps
[0x00000000]> pI 4096 @ 0x401000 | grep "call.*r"

# Analyze switch tables (common with indirect jumps)
[0x00000000]> /x ff25     # Common indirect jump encoding
```

## Output Formats & Export

### Export to Text/DOT

```
# Disassembly to file
[0x401000]> pdf @ 0x401000 > disasm.txt

# CFG in DOT format
[0x401000]> agd @ 0x401000 > cfg.dot
$ dot -Tpng cfg.dot -o cfg.png

# JSON export (functions)
[0x401000]> aflj > functions.json

# LLVM IR candidates (via lifter tools)
$ remill-lift --binary binary --address 0x401000 > ir.ll
```

### Useful Flags for Analysis

```bash
rizin -A binary          # Auto-analyze on open
rizin -2 binary          # Open read-only
rizin -a x86 binary      # Force architecture
rizin -e io.cache=true   # Cache I/O (faster)
```

## Filtering & Searching

| Command            | Purpose                                     |
| ------------------ | ------------------------------------------- |
| `afl~<filter>`     | Filter function list (e.g., `afl~sym.`)     |
| `/x <hex>`         | Search for hex pattern                      |
| `/i <instruction>` | Search for instruction pattern              |
| `fs`               | List/manage flag spaces (symbol namespaces) |
| `flag`             | List all flags (symbols, functions)         |

**Example:**

```
# Functions starting with "sym."
[0x00000000]> afl~sym.

# Search for PUSH RBP (function prologue on x86-64)
[0x00000000]> /x 55           # 55 = push rbp

# All functions with "main" in name
[0x00000000]> afl~main
```

## Tips & Tricks

### Speed Up Analysis

- Use `aaa` sparingly on large binaries; use `af` for targeted functions
- Enable caching: `e io.cache=true`
- Analyze selectively: `af 0x401000` instead of `aaa` for one function

### Better Disassembly Readability

```
e asm.syntax=att          # AT&T syntax (x86)
e asm.syntax=intel        # Intel syntax (default x86-64)
e asm.comments=true       # Show comments
e asm.describe=true       # Describe operands
```

### Combine with External Tools

```bash
# Export for lifter (e.g., remill-lift)
rizin -A binary -c "pdf @ main" > main_disasm.txt

# Use jq to parse JSON exports
rizin -A binary -c "aflj" | jq '.[] | {name, size, addr}'

# Integration with IDA, Ghidra (via export formats)
rizin -A binary -c "agd @ 0x401000 > cfg.dot"
```

## Common Pitfalls

1. **Forgetting `aaa`**: Always run analysis before querying functions

   ```
   [0x00000000]> aaa     # Don't skip this
   [0x00000000]> afl     # Now functions appear
   ```

2. **Wrong syntax**: Radare2/Rizin use `;` for command chaining:

   ```
   [0x00000000]> s 0x401000; pdf 10   # Correct
   [0x00000000]> s 0x401000 && pdf 10 # Wrong
   ```

3. **Missing address in command**: Many commands need `@`:

   ```
   [0x00000000]> pdf @ 0x401000       # Correct
   [0x00000000]> pdf 0x401000         # Wrong
   ```

4. **Indirect jumps & unresolved targets**: If a function has indirect jumps, Rizin may not discover all reachable code automatically—use symbolic execution tools for CFG reconstruction.

## References

- **Rizin Docs**: https://rizin.re/
- **Radare2 Book**: https://book.rada.re/
- **Command Cheat Sheet**: Type `?` in the interactive shell
