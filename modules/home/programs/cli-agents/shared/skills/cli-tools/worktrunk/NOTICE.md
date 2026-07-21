# Vendored from Worktrunk

This directory is a verbatim copy of `skills/worktrunk/` from the Worktrunk
repository, vendored so the `worktrunk` config skill is discoverable by all
shared CLI agents (Claude Code, omp, Codex, Amp) — not only Claude Code, which
loads it via its own plugin marketplace.

- **Upstream:** https://github.com/max-sixty/worktrunk
- **Pinned commit:** `c6eb148e62d54414918697873f2cc8f06222f02f`
  (matches the `worktrunk` flake input in this repo's `flake.lock`)
- **License:** MIT OR Apache-2.0 — see `LICENSE` in this directory
- **Source path:** `skills/worktrunk/` (the authored home; content-identical to
  the plugin mirror at `plugins/worktrunk/skills/worktrunk/`)

## Re-syncing

When bumping the `worktrunk` flake input, re-copy the tree from the newly
locked revision so this vendored copy does not drift:

```bash
DEST=modules/home/programs/cli-agents/shared/skills/cli-tools/worktrunk
REV=$(jq -r '.nodes.worktrunk.locked.rev' flake.lock)
TMP=$(mktemp -d)
git init --quiet "$TMP"
git -C "$TMP" remote add origin https://github.com/max-sixty/worktrunk
git -C "$TMP" fetch --quiet --depth 1 origin "$REV"
git -C "$TMP" checkout --quiet FETCH_HEAD
cp -r "$TMP/skills/worktrunk/." "$DEST/"   # SKILL.md + reference/
cp "$TMP/LICENSE" "$DEST/LICENSE"          # explicit LICENSE refresh
rm -rf "$TMP"
```

The `LICENSE` copy is explicit — re-run it every sync. `NOTICE.md` is local
(not upstream) and survives the copy. The `reference/` docs are regenerated
upstream by `test_docs_are_in_sync`; a re-sync picks them up wholesale. Review
`git diff` afterward — upstream file removals are not mirrored automatically.
