---
name: ida-domain-api
description: Analyze binaries with IDA Pro's Domain API. Use when examining functions, instructions, control flow, strings, cross-references, names, types, segments, or bytes in an IDA database.
license: MIT
---

<!-- Source: https://github.com/HexRaysSA/claude-marketplace/tree/main/plugins/ida-plugin-development/skills/ida-domain-api -->

# Domain API for IDA Pro

Prefer the Python Domain API over the legacy low-level IDAPython SDK. Read the installed API reference before guessing names or signatures:

- Overview: <https://ida-domain.docs.hex-rays.com/llms.txt>
- Getting started: <https://ida-domain.docs.hex-rays.com/getting_started/index.md>
- Reference: <https://ida-domain.docs.hex-rays.com/ref/{module}/index.md>

Useful modules include `database`, `functions`, `instructions`, `flowchart`, `strings`, `xrefs`, `names`, `types`, `bytes`, and `segments`.

## Open a database

Open an existing `.i64` or `.idb` without re-analysis:

```python
from ida_domain import Database
from ida_domain.database import IdaCommandOptions

options = IdaCommandOptions(auto_analysis=False, new_database=False)
with Database.open("sample.i64", options, save_on_close=False) as db:
    # Inspect through the database's Domain API collections.
    pass
```

For raw inputs, create a deterministic cached `.i64` with `auto_analysis=True` and `new_database=True`. Wait for auto-analysis before querying. Hash the input for the cache key, serialize cache creation with a lock, and check for a transient `.nam` file before opening a database being repacked.

## Analysis workflow

1. Identify the binary or intended IDB and make a backup.
2. Open an existing IDB read-only, or create the cache for a raw input.
3. Establish orientation: architecture, image range, segments, entry points, imports, strings, and names.
4. Narrow the search with bounded iteration over the relevant collection.
5. Inspect callers, callees, basic blocks, xrefs, types, and decompiled code around the target.
6. Record addresses and evidence outside the IDB.
7. Apply names, comments, types, or patches only when requested; re-read every changed object and save deliberately.

Use the owning database collection for relationships. For example, query callers through the function collection rather than assuming relationship methods exist on an individual function object. Keep one session alive for related work and avoid concurrent writers.

## Safety

Treat analysis databases as mutable state. Prefer a copy or cache for scripts that write an IDB, and preserve the original before broad renames, type changes, or patches. Use IDASQL for bounded tabular queries and the Domain API for structured analysis.
