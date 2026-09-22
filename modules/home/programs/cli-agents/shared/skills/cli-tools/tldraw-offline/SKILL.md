---
name: tldraw-offline
description: "Operate the user's tldraw offline canvas and open .tldraw/.tldr files: inspect shapes, make bound diagrams, arrange or script durable behavior, lint/screenshot the result, and persist requested edits."
---

# tldraw canvas operator

Use this skill for an open tldraw Desktop document when the task involves inspecting, editing, arranging, connecting, linting, scripting, or saving a canvas.

## Operating boundary

- Inspect the target document, shapes, bindings, and viewport before mutating anything. Separate read-only inspection from `/exec` mutation and from on-disk save.
- Static drawing edits (moving, arranging, labeling, styling) use `/api/doc/:id/exec`. Durable behavior (clickable UI, animations, reactive layouts, run-on-open logic) uses `/script-workspace` and direct edits under `script/**`.
- Never delete unknown shapes, all page contents, or an entire document. Restrict deletion to ids established for the requested panel/keep-set and to arrows whose bindings are part of that known set.
- Never edit an open `.tldraw` archive, `db.sqlite`, `db.sqlite-wal`, `db.sqlite-shm`, `metadata.json`, `.lock`, or `.script-workspace/**` directly.
- For diagram layout, use [diagram-layout.md](references/diagram-layout.md). For generic appearance and comparisons, use [diagram-style.md](references/diagram-style.md). For status-DAG/work dashboards, use [status-dag.md](references/status-dag.md). For requested on-disk persistence, use [save-to-disk.md](references/save-to-disk.md).

## Server and authentication

The default server is `http://localhost:7236`. If that port is inactive, read `port` and the per-launch `token` from `$HOME/.config/tldraw/server.json`. A clean quit removes that file; it also records `pid` and `startedAt`. If the file exists but requests to its port fail, treat it as stale: the app is not running.

Every request except `GET /` and `/readme` needs `authorization: Bearer <token>`. Read the current port and token together before issuing requests:

```bash
PORT=$(jq -r .port "$HOME/.config/tldraw/server.json")
TOKEN=$(jq -r .token "$HOME/.config/tldraw/server.json")
```

For Claude subagents, the optional [context-injection hook](inject-server-context.sh) can supply the URL and token at `SubagentStart`. It is not automatically enabled; registration details are in the script header. Other agents use `tq` or `server.json`.

The `tq` helper ships beside this file. Resolve it relative to the directory containing the loaded `SKILL.md`; do not assume a client installation path:

```bash
SKILL_DIR=/path/to/this/skill
sh "$SKILL_DIR/tq" POST /api/search '{"code":"return await api.getDocs()"}'
sh "$SKILL_DIR/tq" POST /api/doc/DOC_ID/exec 'return editor.getCurrentPageShapes().length'
sh "$SKILL_DIR/tq" GET /api/doc/DOC_ID/script-status
```

`tq` re-reads `server.json` per call. A body beginning with `{` is sent as JSON; other bodies are sent as raw `text/plain`. If it is unavailable, use raw `curl` with the port/token reads above. `GET /readme` is the public fallback for undocumented endpoint details.

## Discover, inspect, then mutate

Core endpoints:

- `POST /api/search`: execute JavaScript with an `api` object to discover docs, read shapes/bindings, capture screenshots, and query the editor API.
- `POST /api/doc/:id/exec`: execute JavaScript with a live `editor` scoped to one document.
- `POST /api/doc/:id/script-workspace`: expose live script paths for durable document-script and asset edits.
- `GET /api/doc/:id/script-status`: inspect watcher state and `errorLogPath`.

The code-taking POST endpoints accept raw JavaScript (`content-type: text/plain`) or `{"code":"..."}` JSON and wrap it in an async function, so top-level `await` works. Begin with the target document and its current records:

```bash
curl -s -X POST http://localhost:$PORT/api/search \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $TOKEN" \
  -d '{"code":"return await api.getDocs()"}'

curl -s -X POST http://localhost:$PORT/api/search \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $TOKEN" \
  -d '{"code":"const doc = await api.getFocusedDoc(); const page = doc ? await api.getShapes(doc.id) : null; return { doc, shapes: page?.shapes.map(s => ({ id: s.id, type: s.type, x: s.x, y: s.y, props: s.props, meta: s.meta })) ?? [] }"}'

curl -s -X POST http://localhost:$PORT/api/search \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $TOKEN" \
  -d '{"code":"const doc = await api.getFocusedDoc(); return doc ? await api.getBindings(doc.id) : []"}'
```

Do not write to an id absent from `getDocs()`. If an edit is requested, post a script to `/exec`; use records to verify once afterward, and take a screenshot when placement or UI chrome is visually uncertain.

## Shape records and imports

`api.getShapes()`, `/exec`, and document scripts use raw tldraw SDK records. Create shapes with normal tldraw partials. In `/exec`, import primitives dynamically; document scripts may use top-level imports. The `helpers` bag contains editor-bound conveniences, not SDK primitives. Read `api.imports` through `/api/search` when an import is unknown:

```js
const { createShapeId, toRichText } = await import('tldraw')
editor.createShape({
  id: createShapeId('box1'),
  type: 'geo',
  x: 100,
  y: 100,
  props: { geo: 'rectangle', w: 300, h: 200, richText: toRichText('Label') },
})
```

For meaningful connections, use bound arrows via `helpers.createArrowBetweenShapes`; the arrow-label second pass and layout arithmetic are in [diagram-layout.md](references/diagram-layout.md).

For a static edit, post the snippet as raw `text/plain` and then inspect the resulting records:

```bash
curl -s -X POST "http://localhost:$PORT/api/doc/DOC_ID/exec" \
  -H 'content-type: text/plain' \
  -H "authorization: Bearer $TOKEN" \
  --data-binary @/tmp/tld.js
```

The target id must be one returned by `api.getDocs()`; layout-specific id encoding is documented in [diagram-layout.md](references/diagram-layout.md).

## Screenshots, lints, and reporting

`api.getScreenshot(docId, opts?)` returns `{ filePath, width, height, pageName, viewport, bounds, captureMode }`; it writes a JPEG to a temporary path. `opts.size` is `small | medium | large | full`; `opts.mode` is `canvas` (shapes framed to bounds) or `window` (the whole app window, including UI drawn by a script's `components` override). `opts.bounds` applies only to canvas mode; passing it with another mode can silently fall back to a window capture. Prefer shape records; screenshot when the user asks for visual proof or placement is uncertain.

For diagrams, return `helpers.getLints()` and address actionable results before reporting. Lint-clean does not guarantee an arrow label is not wrapped; inspect a full-canvas screenshot as described in the layout reference.

Keep the final summary tight: document id/name, changed shape ids or script path, and the one verification result. If something fails, quote the server error, digest mismatch, or relevant `.script-workspace/error.log` line.

## Durable scripts and configuration

For durable behavior, open `/script-workspace`, inspect the existing `mainJsPath`, write `script/main.js`, check `/script-status`, and verify once. `state: "applied"` is success; `"pending"` means retry once; `"error"` means read `lastApplyError` or `errorLogPath`. `isDefaultScript: true` means the untouched starter exists; when false, extend the existing script instead of clobbering it. Keep run-on-mount logic in `main.js`. Read the clickable-UI recipe before inventing pointer/click APIs; other useful recipes include `stack-existing-boxes`, `add-durable-behavior-with-a-document-script`, `editable-furniture-with-anchored-internals`, `clickable-card-or-button-ui`, `connection-dependent-behavior`, `animation-simulation-loop`, `custom-shape-config-js`, and `custom-overlay-config-js`.

For durable furniture, use stable ids and `helpers.createShapeIfMissing`/`createShapesIfMissing`; never delete and redraw user-facing shapes on rerun. Use one visible anchor, `helpers.onShapeTranslate(anchorId, callback, { signal })`, and `helpers.translateShapes` for script-owned internals. Wrap other script-owned writes in `editor.run(fn, { history: 'ignore' })`. Avoid broad `store.listen`/`afterChange` handlers that react to the script's own writes and recurse.

Custom shape types, tools, overlays, or UI components require a sibling `script/config.js` created through `/script-workspace`; `main.js` alone cannot register them. Its default export runs before mount with `{ config }`, whose arrays include `shapeUtils`, `bindingUtils`, `assetUtils`, `overlayUtils`, `tools`, and `components`; optional fields include `getShapeVisibility`, `assetUrls`, `initialState`, and `options`. Push constructors onto those arrays; a util/tool whose static `type`/`id` matches a stock one replaces it. Define custom `ShapeUtil`/`OverlayUtil` classes in sibling modules, and read the `custom-shape` and `custom-overlay` recipes from `api.recipes` before implementing one. Types live in `.script-workspace/script-context.d.ts`. Saving `config.js` or an imported config file remounts the store/editor (document, camera, and selection survive; undo history resets); saving `main.js` does not.

When a durable script or config edit is complete, use the requested OS-level save procedure in [save-to-disk.md](references/save-to-disk.md) if the `.tldr` archive must contain it.
