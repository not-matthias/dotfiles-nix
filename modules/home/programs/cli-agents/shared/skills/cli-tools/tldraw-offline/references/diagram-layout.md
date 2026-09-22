# Diagram layout and `/exec` mechanics

Use this reference for programmatic box-and-arrow diagrams, trees, reflow, and comparison panels. Start with the server/session workflow in [the canonical skill](../SKILL.md).

## Safe request setup

Write a JavaScript snippet to a temporary file and post it as `text/plain`; this avoids shell quoting failures:

```bash
PORT=$(jq -r .port "$HOME/.config/tldraw/server.json")
TOKEN=$(jq -r .token "$HOME/.config/tldraw/server.json")
curl -s -X POST "http://localhost:$PORT/api/doc/<DOC_ID>/exec" \
  -H 'content-type: text/plain' \
  -H "authorization: Bearer $TOKEN" \
  --data-binary @/tmp/tld.js
```

Use an id returned by `api.getDocs()`. The short `documentId` works, as does a raw `tldr:file:...` id; do **not** URL-encode the latter or the server looks for `tldr%3Afile%3A...` and returns 404.

## API traps

- `helpers.createArrowBetweenShapes(fromId, toId, options)` returns a bare `TLShapeId` string, not a shape record. Use `const arrowId = ...`; `arrowId.id` fails.
- `text` and `geo` shapes use `props.richText: toRichText(value)`. A text shape with `props.text` fails validation.
- Meaningful connections must use `helpers.createArrowBetweenShapes` so both ends are bound. Raw arrows are only for explicitly decorative marks.
- `text`/`richText` passed to `createArrowBetweenShapes` is ignored. Create the arrows first, then label them by their bindings:

```js
const { toRichText } = await import('tldraw')
const labels = new Map([
  // Use the actual bound shape ids, not array indexes.
  [fromId + '>' + toId, 'passed'],
])
const updates = []
for (const arrow of editor.getCurrentPageShapes().filter(s => s.type === 'arrow')) {
  const bindings = editor.getBindingsFromShape(arrow.id, 'arrow')
  const from = bindings.find(b => b.props.terminal === 'start')?.toId
  const to = bindings.find(b => b.props.terminal === 'end')?.toId
  const label = labels.get(from + '>' + to)
  if (label) {
    updates.push({
      id: arrow.id,
      type: 'arrow',
      props: { richText: toRichText(label), font: 'mono', size: 's' },
    })
  }
}
editor.updateShapes(updates)
```

Stable ids make this pass repeatable. Use `createShapeId(panelPrefix + role)` (for example `a0_l1`, `a0_dhit`, `a2_...`, `d_...`) and keep a table of endpoint roles rather than relying on creation order.

## `growY` and spacing

Geo shapes can silently become taller than `props.h` when text wraps. Inspect both the declared and rendered geometry:

```js
const s = editor.getShape(shapeId)
return {
  declaredHeight: s.props.h,
  growY: s.props.growY,
  bounds: editor.getShapePageBounds(shapeId),
}
```

A non-zero `growY` means the content overflowed. `helpers.getLints()` may report `growY-on-shape` and then `overlapping-text`; setting `growY: 0` alone does not fix the content. Fix in this order:

1. Shorten the longest lines and remove needless parenthetical detail.
2. Widen the box so the remaining lines fit.
3. Only then increase `h` and re-pitch every row below it.

Useful starting dimensions for mono `size: 's'`:

- Connected boxes: horizontal gap at least **200px**; this keeps roughly 24-character edge labels on one line.
- Rows of 100px boxes: vertical gap at least **180px**.
- Boxes: `w: 270` for two-line labels, `330` for three-line stacks, `340` for four-line timeline cards.
- Panel frame: `fill: 'none'`, `color: 'grey'`, about 40px padding around content, sent behind content with `editor.sendToBack([frameId])`.

For a branching tree, leave at least 130px parent-to-child vertical distance, push the hit branch left and the miss branch right, and leave enough horizontal separation that sibling labels cannot collide. For two converging pipelines, keep each pipeline on its own row and put the shared gate in a rightmost column; this avoids crossing arrows without bend tuning.

For side-by-side variants, build every panel through one parameterized `panel()` helper, use deterministic per-panel prefixes, and leave about 600–800px between panel bounds before boxing them. In a cost tree, put each cost on the edge (`hit +5 cyc`, `miss +40 cyc`) and the running total only in the leaf (`served by LL\ntotal 80`).

## Reflow and visual proof

When spacing is wrong, update existing shapes by stable key; do not redraw them:

```js
const dy = { dhit: 50, dll: 50, dllhit: 130 }
editor.updateShapes(Object.entries(dy).map(([role, delta]) => {
  const shape = editor.getShape(createShapeId('a0_' + role))
  return { id: shape.id, type: shape.type, y: shape.y + delta }
}))
```

Run `helpers.getLints()` after each layout pass and fix every actionable result. Lint-clean does not prove that an arrow label is visually clear: labels can wrap mid-word without a lint. Capture and inspect a full canvas screenshot:

```js
return await api.getScreenshot(DOC_ID, { mode: 'canvas', size: 'full' })
```

`bounds` applies only with `mode: 'canvas'`; do not pass canvas bounds while requesting a window capture. A screenshot result contains a temporary `filePath`, not image bytes.

For persistence after a successful edit, use [the OS-level save procedure](save-to-disk.md).