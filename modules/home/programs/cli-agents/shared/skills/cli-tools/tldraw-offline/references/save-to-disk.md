# Persist edits to the `.tldr` file

Use this reference only when the user needs a canvas mutation persisted on disk. The HTTP API edits the app's in-memory store; it has no save endpoint and no autosave. `api.getFocusedDoc().unsavedChanges` can remain `true`, and the archive's `db.sqlite` can remain unchanged. A renderer-side `KeyboardEvent` or `dispatchEvent` for Ctrl+S also does nothing: saving is an Electron main-process menu accelerator.

## Send the real OS accelerator

On Wayland with niri:

```bash
# Find the tldraw offline window and remember the currently focused window.
niri msg windows
niri msg focused-window

# Replace IDs, then focus tldraw, send a real Ctrl+S, and restore focus.
niri msg action focus-window --id <TLDRAW_ID>
sleep 0.6
wtype -M ctrl s -m ctrl
sleep 1.5
niri msg action focus-window --id <ORIGINAL_ID>
```

The tldraw App ID is `tldraw offline`; a leading bullet in the title (for example `• name.tldr`) indicates unsaved changes. On X11 use the equivalent real-window injector such as `xdotool key --window <id> ctrl+s`; `ydotool` is an alternative when its daemon is available. The focus change is intentional and must be restored afterward.

## Confirm both app and archive state

First confirm the app cleared its dirty state through the authenticated search endpoint:

```bash
P=$(jq -r .port "$HOME/.config/tldraw/server.json")
T=$(jq -r .token "$HOME/.config/tldraw/server.json")
curl -s -X POST "http://localhost:$P/api/search" \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $T" \
  -d '{"code":"const d=await api.getFocusedDoc();return {unsaved:d.unsavedChanges,shapes:d.shapeCount}"}'
```

Then inspect the archive without modifying it. A `.tldr` is a zip containing `db.sqlite`; after saving, its database should grow or have a newer mtime and the `documents` table should contain one row per persisted shape:

```python
import sqlite3
import tempfile
import zipfile

with zipfile.ZipFile("path/to/file.tldr") as archive:
    sqlite_path = tempfile.mktemp(".sqlite")
    with open(sqlite_path, "wb") as output:
        output.write(archive.read("db.sqlite"))
connection = sqlite3.connect(sqlite_path)
print(connection.execute(
    "select count(*) from documents where id like 'shape:%'"
).fetchone()[0])
```

The `documents` schema is `(id, state, lastChangedClock)` and shape ids begin with `shape:`. Never edit `db.sqlite`, `db.sqlite-wal`, `db.sqlite-shm`, the archive, or `.script-workspace/**` while the app has the file open. If the `tq` helper is unavailable, use raw `curl` and re-read port/token from `server.json` in every fresh shell; exported variables do not persist between Bash calls.