---
name: idasql
description: Use when analyzing binaries or IDA databases with the IDASQL CLI or live IDA SQL interface, including functions, strings, cross-references, types, decompilation, annotations, HTTP, or MCP.
---

# IDASQL

Use IDASQL when the task requires structured access to a binary or an IDA database. Keep the execution boundary explicit:

```text
agent -> idasql -> IDALib -> raw binary or IDB
```

The agent issues SQL and interprets results. IDASQL runs IDA's analysis in the background; do not invent an export or indexing step.

## Start a session

Open a binary or database with the CLI:

```bash
idasql -s <binary-or-idb> -q 'SELECT * FROM binary;'
```

Use `-i` for a REPL, `-f analysis.sql` for a SQL file, or `--http <port>` / `--mcp <port>` for a long-lived server. Prefer one long-lived server when exploring repeatedly because opening and analyzing a database is the expensive part.

Start with the binary table to orient yourself:

```sql
SELECT * FROM binary;
```

Discover the exact columns at runtime instead of guessing from a remembered schema:

```sql
PRAGMA table_xinfo(funcs);
PRAGMA table_xinfo(strings);
PRAGMA table_xinfo(xrefs);
```

## Query safely

Keep exploratory queries narrow and bounded:

```sql
SELECT addr, name, size FROM funcs ORDER BY size DESC LIMIT 20;
SELECT addr, content FROM strings WHERE content LIKE '%error%' LIMIT 50;
SELECT * FROM xrefs WHERE to_addr = 0x401000 LIMIT 50;
```

Use the schema output to adjust column names for the current IDA database. Prefer explicit columns and `LIMIT` over `SELECT *` once the table shape is known. Query related tables with joins only after checking their schemas.

## Read before write

Treat the database as mutable state:

1. Read the relevant function, type, or annotation first.
2. Confirm the target address and current value.
3. Make the smallest supported update.
4. Re-query the target to verify the result.

Pass `--write` (or `-w`) when changes must persist on exit. Without it, use the session for read-only analysis and do not assume edits survive. Be especially careful with comments, prototypes, applied types, and decompiler annotations.

## HTTP and MCP

For repeated queries, start a local HTTP server:

```bash
idasql -s sample.i64 --http 8080
curl -X POST http://127.0.0.1:8080/query \
  -d "SELECT addr, name FROM funcs LIMIT 10"
```

Use `--bind 127.0.0.1` unless remote access is explicitly required. Start MCP with `--mcp`; follow the process output for the selected port and connect the agent to that endpoint. From an interactive IDA session, `.http start` exposes the live GUI database without opening a second database.

## Edge cases and troubleshooting

- `-s` accepts either a raw binary or an existing `.idb` / `.i64`; raw binaries trigger fresh IDA analysis.
- A legacy 32-bit `.idb` may be upgraded to a sibling `.i64`. If IDASQL reports `reopen_with`, repeat the command with that path instead of querying the empty upgrade session.
- Keep one database session open for multi-step work; do not repeatedly restart IDASQL for each query.
- If a command fails, run `idasql --help` and use the installed binary's options rather than assuming flags from another IDA release.

## Sources

- <https://github.com/allthingsida/idasql>
- <https://github.com/allthingsida/idasql-skills/blob/main/plugins/idasql/skills/connect/references/cli-reference.md>
- <https://github.com/allthingsida/idasql-skills/blob/main/plugins/idasql/skills/connect/references/schema-catalog.md>

<!-- Adapted as an original cross-agent guide from the upstream IDASQL documentation and schema references. -->
