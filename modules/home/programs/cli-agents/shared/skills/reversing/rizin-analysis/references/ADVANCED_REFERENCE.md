# Advanced Rizin/Radare2 Topics

## Scripting & Automation

### Using the Radare2 CLI in Scripts

Chain multiple commands for batch analysis:

```bash
#!/bin/bash
BINARY=$1

rizin -A "$BINARY" -c "
aaa
afl > functions.txt
aflj > functions.json
"
```

### Radare2 Script Files

Create a `.r2` script:

```r2
# analyze.r2
aaa
afl~sym.main
pdf @ main
```

Run it:

```bash
rizin -r analyze.r2 /path/to/binary
```

### Python API (r2pipe)

Programmatic analysis:

```python
import r2pipe

r2 = r2pipe.open("/path/to/binary")
r2.cmd("aaa")  # Analyze all

# Get all functions as JSON
functions = r2.cmdj("aflj")
for func in functions:
    print(f"{func['name']} @ {hex(func['offset'])}")

# Disassemble function
disasm = r2.cmd(f"pdf @ {hex(func['offset'])}")
print(disasm)

r2.quit()
```

Install: `pip install r2pipe`

## Advanced Analysis Techniques

### Identifying Indirect Jump Targets via Pointer Analysis

```
[0x00000000]> aaa

# Find instructions loading addresses into registers
[0x00000000]> pI 4096 @ 0x401000 | grep "lea\|mov.*="

# Check data section for jump tables
[0x00000000]> s 0x402000     # Seek to data section
[0x00000000]> px 256         # Hex dump to find pointer patterns

# Mark as code/data if misidentified
[0x00000000]> Cd 8 @ 0x402000   # Mark as 8-byte data
[0x00000000]> CC 1 @ 0x403000   # Mark as code
```

### Tracking Data Flow to Function Arguments

```
# Find where RDI is set (x86-64 first argument)
[0x00000000]> pI 4096 @ 0x401000 | grep "mov.*rdi\|lea.*rdi"

# Trace back to understand parameter source
[0x00000000]> axt 0x401000    # Who calls this function?
```

### Handling Stripped Binaries

When symbols are removed:

```
[0x00000000]> aaa

# Use size/structure heuristics to find functions
[0x00000000]> afl           # Auto-detected functions

# Manually mark function boundaries
[0x00000000]> af 0x401000   # Define function at address

# Rename for clarity
[0x00000000]> afn "handler_routine" @ 0x401000
```

### Creating Custom Flags (Annotations)

```
# Flag a suspicious address
[0x00000000]> f suspicious_loop=0x401234

# List flags
[0x00000000]> f

# Use in commands
[0x00000000]> pdf @ suspicious_loop
```

## Integration with Lifting Workflows

### Extracting Function Boundaries for remill-lift

```bash
$ rizin -A binary -c "aflj" | jq '.[] | {name: .name, offset: .offset, size: .size}' > funcs.json

# Use jq to prepare for lifter
$ cat funcs.json | jq '.[] | "\(.name): 0x\(.offset | tostring)\n"' > lifter_targets.txt
```

### Identifying Lifting Constraints

Before lifting, check for:

1. **Indirect calls/jumps** (symbolic execution required):

   ```
   [0x00000000]> pI 4096 @ 0x401000 | grep -E "call.*r|jmp.*r|jmp.*\[|call.*\["
   ```

2. **Unresolved addresses** (pointer lookups in data):

   ```
   [0x00000000]> s 0x402000  # Data segment
   [0x00000000]> pd 100 @ 0x402000 | grep -E "\.word|\.quad"
   ```

3. **Control flow complexity**:
   ```
   [0x00000000]> agf @ target_func  # Visualize CFG
   ```

### Batch Export for Multiple Functions

```bash
#!/bin/bash
rizin -A "$1" -c "
aaa
aflj
" | jq -r '.[] | .name' | while read func; do
  echo "=== $func ===" >> analysis.txt
  rizin -c "aaa; pdf @ $func" "$1" >> analysis.txt
done
```

## Performance Optimization

### Large Binary Analysis

For binaries >100MB, optimize:

```bash
# Minimal analysis (entry + imports only)
rizin -A -e analysis.depth=1 binary

# Selective analysis
rizin binary
[0x00000000]> af 0x401000    # Analyze specific function only
[0x00000000]> pdf @ 0x401000
```

### Caching & Pre-processing

```bash
# Cache analysis to .r2 file
$ rizin -A binary -w   # Write analysis back to binary

# Later, load with cached analysis
$ rizin -A binary      # Faster, uses cached metadata
```

## Debugging & Troubleshooting

### Verbose Output for Analysis Issues

```bash
rizin -e log.level=debug binary
```

### Check Architecture Detection

```
[0x00000000]> i        # Binary info (architecture, OS, entry)
[0x00000000]> e asm.arch   # Show detected architecture
```

### Manual CFG Reconstruction (When Auto-Analysis Fails)

```
# List discovered basic blocks manually
[0x00000000]> afb @ 0x401000

# Add missing connections
[0x00000000]> aea 0x401000 0x401050   # Add edge
```

## Comparing Rizin vs Radare2

| Feature           | Rizin                      | Radare2                  |
| ----------------- | -------------------------- | ------------------------ |
| **Speed**         | Faster (rewritten in C++)  | Slower (original)        |
| **Maintenance**   | Active development         | Legacy (some stagnation) |
| **API**           | Modern Rust/C++ bindings   | Older API                |
| **Compatibility** | Mostly backward-compatible | Original format          |
| **Use Case**      | Production/modern tools    | Historical/compatibility |

**Recommendation**: Use Rizin (`rizin` command) for faster interactive analysis. Fall back to Radare2 if needed for specific compatibility.

---

## Quick Reference

```bash
# One-liner: Extract all functions with sizes
rizin -A binary -c "aflj" | jq '.[] | "\(.name) \(.size)"'

# One-liner: Find all calls in a function
rizin -A binary -c "agf @ main" | grep "call"

# One-liner: Export CFG as image
rizin -A binary -c "agd @ main" | dot -Tpng -o cfg.png
```
