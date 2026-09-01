---
name: radius2-analysis
description: Guide to using radius2 for binary emulation, symbolic execution, and taint analysis. Use when solving crackmes, exploring paths through native binaries, constraining symbolic inputs, or generating test cases with radius2.
license: MIT
---

# Radius2 Binary Emulation

Radius2 is a command-line symbolic execution and taint analysis framework built around radare2. It is useful when ordinary disassembly shows the control flow but not which input reaches a target path.

## When to Use

- Solve a native crackme or path constraint
- Explore branches without manually reproducing every input
- Mark input, memory, or registers as symbolic
- Avoid failure addresses or strings and break at success paths
- Generate concrete test cases or machine-readable output

## Quick Start

```bash
radius2 --version
radius2 -p ./target -s stdin 96 -X "Incorrect"
```

`-p` selects the target. `-s NAME BITS` creates a symbolic value. `-X STRING` avoids code that references a string, which is often a convenient way to exclude a failure path. Use the bit width that matches the input buffer; 96 bits is 12 bytes.

## Inspect Before Emulating

Use radare2 or Rizin to identify the entry point, relevant strings, and branch addresses before choosing constraints:

```bash
r2 -AA ./target
# inside r2:
izz                 # strings
 afl                 # functions
 pdf @ main          # disassemble main
 axt @ str.Incorrect # find code referencing a failure string
```

Keep static analysis and symbolic execution separate: use the disassembler to obtain facts about the binary, then give radius2 only the addresses and constraints it needs.

## Core Options

| Option | Purpose |
| --- | --- |
| `-p, --path PATH` | Target binary |
| `-a, --address ADDR` | Starting address |
| `-s, --symbol NAME BITS` | Symbolic value |
| `-S, --set REG/ADDR VALUE BITS` | Set a register or memory value |
| `-x, --avoid ADDR` | Avoid an address |
| `-X, --avoid-strings STRING` | Avoid xrefs to a string |
| `-b, --break ADDR` | Break at an address |
| `-B, --break-strings STRING` | Break at xrefs to a string |
| `-c, --constrain SYMBOL EXPR` | Constrain a symbolic value |
| `-f, --file PATH SYMBOL` | Add a symbolic file |
| `-F, --fuzz DIR` | Write generated test cases |
| `-j, --json` | Emit JSON |
| `-v, --verbose` | Show debugging output |

## Address-Directed Workflow

When string-directed exploration is too broad, use known addresses from the disassembly:

```bash
radius2 \
  -p ./target \
  -a 0x4006fd \
  -x 0x400790 \
  -b 0x4007a1 \
  -s flag 96 \
  -S A0 0x100000 64 \
  -S 0x100000 flag 96
```

This starts at the chosen address, avoids a known bad branch, stops at the target, and places the symbolic `flag` in memory while passing its address in `A0`. Adjust the register and addresses for the target architecture and ABI.

## Constraints and Hooks

```bash
# Restrict a symbolic value, evaluate an expression, and print JSON
radius2 -p ./target -s input 64 -c input '"ABCD"' -e 'rax = 0' -j

# Run an ESIL expression after emulation or hook an address
radius2 -p ./target -H 0x401050 'rax = 1' -E 'rax == 1'
```

Treat constraints as hypotheses. Start with only the input shape and success/failure condition, then add one constraint at a time. Over-constraining the state can make a solvable path disappear.

## Troubleshooting

- **No solution:** verify the start address, input bit width, target architecture, and whether the avoided address is reachable on every valid path.
- **Too many states:** add a success breakpoint, avoid known dead paths, set `--max`, or use `--merge`/`--merge-all` deliberately.
- **Invalid instruction or memory stop:** compare radius2's start address with the binary's load address and try `--no-strict` only after confirming the target really needs it.
- **Imports block exploration:** try `--no-sims` when simulated imports are producing irrelevant states; use `--plugins` only when the target depends on r2 plugins.
- **Need to understand a failure:** rerun with `-v`, `--profile`, and `--crash` rather than silently widening the search.

## Reproducibility Checklist

Record the target hash, architecture, radius2 version, start address, symbolic input widths, avoid/break addresses, and every constraint. Prefer `-j` output for scripts, and retain the exact command that produced a solution.

<!--
Sources:
- https://github.com/radareorg/radius2/blob/main/README.md
- https://github.com/radareorg/radius2/blob/main/.github/workflows/release.yml
-->
