# Status-DAG and work-dashboard panels

Use this reference for project/todo DAGs, pipeline panels, PR stacks, milestone timelines, and task ledgers built from supplied status data.

## Status convention

Use one marker per task and keep the legend below the panels:

| marker | color | fill | meaning |
|---|---|---|---|
| `[x]` | green | semi | done |
| `[>]` | orange | semi | in progress |
| `[ ]` | blue / violet | none or semi | not started |
| `[!]` | red | semi | blocked |

`[>]` is not self-evident without the legend. Never merge a finished sub-step with its unfinished successor: represent `[x] X` → `[>] Y`, rather than recoloring one combined node.

These colors are a scoped exception to the generic monochrome defaults in [diagram-style.md](diagram-style.md); keep all other diagram decoration plain.

## Panel geometry

For two parallel tracks converging on a shared gate and terminal node:

- Put track A at `y1`, track B at `y1 + 180`.
- Use boxes around `w: 270–330` (up to `340` for long timeline cards), with at least `180px` between connected columns.
- A track may skip an empty column; keep the shared gate in its own rightmost column so both tracks approach from the left without crossing.
- Add a `LEGEND` row of four small swatches (`w: 230`, `h: 50`) below the panels.
- Use a `geo` frame with `fill: 'none'`, `color: 'grey'`, roughly 40px padding, and send it behind content with `editor.sendToBack([frameId])`. Keep sibling frames the same width.
- Keep each per-step arrow label to one short line (about ten characters at a 180px gap); the destination box carries the task name and marker.

A practical dashboard arrangement uses columns at `x = 140, 610, 1140, 1620, 2090`, rows at `y = 240, 420`, and boxes about `h: 100`. Reflow by keyed ids if the real bounds do not fit; do not recreate the panel.

## Build and update safely

Use deterministic ids such as `createShapeId(panelPrefix + role)`. Create all known boxes/frames, send frames to the back, then create bound arrows and label them in a second pass. The relevant API facts are:

```js
const arrowId = helpers.createArrowBetweenShapes(fromId, toId)
editor.updateShapes([{
  id: arrowId,
  type: 'arrow',
  props: { richText: toRichText(label), font: 'mono', size: 's' },
}])
```

The helper returns a `TLShapeId` string, not an object; `arrowId.id` is invalid. Text shapes also require `props.richText: toRichText(value)`, never `props.text`. For complete binding-based relabeling, use the procedure in [diagram-layout.md](diagram-layout.md).

When rebuilding one known panel, collect its shape ids into a `Set`, collect only arrows whose bindings point into that set, delete those known shapes and arrows, then recreate them. When pruning to a keep-set, retain an arrow only when both bound endpoints remain:

```js
const bindings = editor.getBindingsFromShape(arrow.id, 'arrow')
const endpoints = bindings.map(binding => binding.toId)
const keepArrow = endpoints.length === 2 && endpoints.every(id => keep.has(id))
```

Never delete all page shapes, an entire document, or an id not established by the current panel/keep-set. Unknown user shapes and unrelated panels must survive.

## Safety and visual review

Before writing, use `api.getDocs()` and inspect the target document's current shapes and bindings. A missing document id is a 404; do not redirect the write to another document. If a user says the result is not visible, inspect shape bounds and `editor.getViewportPageBounds()` before redrawing, then check the tldraw window with `niri msg windows` and focus the correct window if needed.

After the edit, return `helpers.getLints()`, then capture and inspect a full-canvas screenshot. Linting does not see wrapped arrow labels or all box/arrow collisions. For text that wraps, inspect `shape.props.growY` and rendered bounds; shorten lines or widen/re-space before accepting the layout. Persist a requested on-disk result with [save-to-disk.md](save-to-disk.md).