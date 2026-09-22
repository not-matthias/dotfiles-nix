# Diagram style preferences

Use this reference when deciding how a generic diagram should look. It applies to trees, flowcharts, cost models, and side-by-side variants; the status-DAG palette in [status-dag.md](status-dag.md) is the deliberate exception.

## Generic defaults

- Use `font: 'mono'`, `size: 's'`, `geo: 'rectangle'`, `align: 'middle'`, and `verticalAlign: 'middle'` for boxes. Use a `text` shape with size `l` for titles.
- Reproduce an ASCII/terminal-like reference literally: plain rectangles, no fill, and no colors unless the user asks for them.
- Every meaningful connection is a bound arrow from `helpers.createArrowBetweenShapes`; never substitute an unbound arrow.
- Keep edge labels to one line (at most two short lines). Shorten labels such as `miss D1m` rather than wrapping a long counter list.
- Put a cost or weight on the edge, not in the destination box. The leaf carries the destination and running total; a short mono stats note below the tree contains measured facts only.

Use the second-pass binding-based labeling and spacing arithmetic in [diagram-layout.md](diagram-layout.md); passing `text` or `richText` while creating an arrow does not label it.

## Comparison panels

For competing variants, order panels left-to-right in narrative order with the current/shipped state first. Build all variants with one parameterized `panel()` helper so geometry stays comparable while weights, notes, and formulas vary. A panel consists of a title, a one-line formula or summary, one tree per subsystem, and a stats note below the content.

Leave a wide gutter (roughly 600–800px between panel bounds), draw a `geo` frame around each panel with `fill: 'none'` and `color: 'grey'`, and send each frame behind its content. Keep frames and content visually plain; status markers are the only routine use of color.

## Layout review

After any layout pass, run `helpers.getLints()` and resolve all actionable `overlapping-text` results; titles/formulas and the final box/stats note are common collisions. Shift existing keyed shapes rather than shrinking text or redrawing the panel. Then capture a full-canvas screenshot and inspect it, because linting does not detect a wrapped arrow label. See [diagram-layout.md](diagram-layout.md) for the exact screenshot call and `growY` inspection.