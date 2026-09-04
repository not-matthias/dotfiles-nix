# Vendored from Worktrunk

This directory vendors `skills/worktrunk/` from the Worktrunk repository so
the `worktrunk` config skill is discoverable by all shared CLI agents (Claude
Code, omp, Codex, Amp) — not only Claude Code, which loads it via its own
plugin marketplace.

- **Upstream:** https://github.com/max-sixty/worktrunk
- **Pinned commit:** `bc2ec124d6be16b1af1d93c19820417328e071eb`
  (matches the `worktrunk` flake input in this repo's `flake.lock`)
- **License:** MIT OR Apache-2.0 — see `LICENSE` in this directory
- **Source path:** `skills/worktrunk/`. Upstream's
  `reference/README.md` is a symlink to the repository README; it is
  dereferenced here so the vendored reference remains usable.

## Re-syncing

When bumping the `worktrunk` flake input, replace this vendored tree from the
newly locked revision:

```bash
DEST=modules/home/programs/cli-agents/shared/skills/cli-tools/worktrunk
REV=$(jq -r '.nodes.worktrunk.locked.rev' flake.lock)
TMP=$(mktemp -d)
NOTICE="$TMP/NOTICE.md"
cp "$DEST/NOTICE.md" "$NOTICE"
git init --quiet "$TMP/repo"
git -C "$TMP/repo" remote add origin https://github.com/max-sixty/worktrunk
git -C "$TMP/repo" fetch --quiet --depth 1 origin "$REV"
git -C "$TMP/repo" checkout --quiet FETCH_HEAD
rm -rf "$DEST"
mkdir -p "$DEST"
cp -RL "$TMP/repo/skills/worktrunk/." "$DEST/"
cp "$TMP/repo/LICENSE" "$DEST/LICENSE"
mv "$NOTICE" "$DEST/NOTICE.md"
rm -rf "$TMP"
```

The replacement removes files deleted upstream while retaining local
`NOTICE.md`. `-L` dereferences the upstream `reference/README.md` link so its
repository-README content remains available in the vendored skill.
