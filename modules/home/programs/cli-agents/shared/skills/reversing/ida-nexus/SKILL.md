---
name: ida-nexus
description: Use IDA Nexus to let agents, MCP clients, and other tools share and operate on one IDA database. Use when working with IDA 9.4+, the former ida-codemode integration, ida-domain automation, Nexus GUI discovery, shared IDBs, or IDA MCP setup and troubleshooting.
---

# IDA Nexus

IDA Nexus is the successor to the former `ida-codemode` integration. It lets multiple clients discover and operate on the same IDA database (IDB), whether that database is open in the IDA GUI or hosted by a managed `idalib` worker.

Nexus is an experimental prerelease. Preserve valuable IDBs and prefer reversible analysis changes.

## Prerequisites and installation

- Require IDA 9.4 or newer. Do not apply Nexus setup guidance to older IDA releases.
- Install Nexus as an IDA GUI plugin when clients must discover a database already open in IDA:

  ```bash
  uvx ida-hcli plugin install https://github.com/HexRaysSA/ida-nexus
  ```

- Restart IDA after installing or updating the plugin, then open the intended IDB in the GUI.
- The Python package can still manage an `idalib` worker without the GUI plugin, but it cannot transparently attach to an IDB open in the GUI unless the plugin is loaded there.

## Shared-IDB model

Treat Nexus as the coordination layer, not as a separate database format. Clients share the IDB registered by the GUI plugin or a managed worker, so names, comments, types, and other persisted analysis changes can become visible to every connected client.

Before changing anything:

1. List the available databases and identify the intended instance.
2. Select the instance explicitly when more than one IDB is registered.
3. Inspect first; do not let independent agents make overlapping destructive edits.
4. Save or back up the IDB before bulk renames, type changes, patching, or scripts with broad write effects.

## Relationship to ida-domain

`ida-domain` is the high-level Python API exposed through Nexus's compact execution surface. Nexus handles database discovery, sharing, and execution; `ida-domain` provides the domain-oriented API used to inspect and modify the database.

Prefer `ida-domain` APIs over ad hoc low-level IDAPython when they cover the task. Use Nexus's API-reference search before guessing names or signatures, and keep each execution request small enough to review and recover.

## MCP integration

Run Nexus as an MCP server and configure the MCP client to launch it over stdio:

```bash
uvx ida-nexus mcp
```

Typical MCP flow:

1. Use `list_databases` to discover registered GUI and worker instances.
2. Use `open_database` when a database is not already attached.
3. Use `reference` to look up the installed `ida-domain` API.
4. Use `execute_python` for focused analysis or edits, passing an explicit instance ID when needed.
5. Use `save_database` only after checking the result and confirming the target IDB.

Do not assume that the MCP client's selected resource, IDA's foreground tab, and Nexus's current database are the same. Confirm the Nexus instance before every write-heavy operation.

## Safe troubleshooting

- **No GUI database appears:** Confirm IDA is 9.4+, the Nexus plugin is installed in that IDA installation, IDA was restarted, and the IDB is currently open. Inspect IDA's plugin/output logs before reinstalling.
- **MCP server starts but exposes no database:** Separate transport health from database discovery. First list databases; then confirm the GUI plugin or managed worker is running. Do not repeatedly reopen the IDB as a workaround.
- **Python/API errors:** Query the installed `ida-domain` reference and check the returned stdout and stderr. Match code to the installed API rather than copying examples for another version.
- **Wrong or stale instance:** List databases again and pass the desired instance ID explicitly. Stop before saving if paths or database identity do not match expectations.
- **Concurrent edits conflict:** Pause writers, preserve the IDB, inspect the current state from one client, and resume with a single owner for each mutation. Never delete shared state or recreate the database as a first troubleshooting step.
- **Plugin or server failure:** Capture IDA output, MCP stderr, the exact IDA/Nexus versions, and the smallest failing request. Reproduce against a copy of the IDB before changing installation or database state.

<!--
Sources:
- https://github.com/HexRaysSA/ida-nexus
- https://github.com/HexRaysSA/ida-domain
-->
