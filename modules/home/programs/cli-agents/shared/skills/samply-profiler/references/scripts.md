# Bundled Scripts

The skill includes one primary script, `scripts/analyze_profile.py`.

This follows the Agent Skills script guidance from <https://agentskills.io/skill-creation/using-scripts.md>: bundle deterministic, reusable logic when the command would otherwise be fragile or repeatedly rewritten. Keep scripts non-interactive, provide `--help`, use predictable output sizes, and prefer `uv run` for Python scripts.

## Included Script

### `scripts/analyze_profile.py`

Purpose: offline analysis of samply / Firefox Profiler `profile.json.gz` files after a profile has been captured with `samply record --save-only`.

Capabilities:
- Lists threads by sample count.
- Lists recorded libraries and binary paths from `libs[]`.
- Computes flat self-time and total-time rankings.
- Builds a top-down inclusive call tree.
- Resolves raw hex frames with `addr2line` using `libs[].path` or `--binary`.
- Handles both older per-thread tables and newer `profile.shared` tables.
- Accepts gzip-compressed JSON, plain JSON, or stdin.

Usage:

```bash
SKILL_DIR=/path/to/samply-profiler
uv run python "$SKILL_DIR/scripts/analyze_profile.py" profile.json.gz threads
uv run python "$SKILL_DIR/scripts/analyze_profile.py" profile.json.gz libs
uv run python "$SKILL_DIR/scripts/analyze_profile.py" profile.json.gz flat --auto --top 40
uv run python "$SKILL_DIR/scripts/analyze_profile.py" profile.json.gz flat --auto --resolve --binary ./target/release/my-binary
uv run python "$SKILL_DIR/scripts/analyze_profile.py" profile.json.gz tree --auto --depth 12 --min-pct 1.0
```

## Why Only One Script

Keep one all-in-one analyzer instead of separate `parse_profile.py`, `resolve_symbols.py`, and `extract_calltree.py` helpers. A single entry point is easier for agents to discover with `--help`, reduces duplicated Firefox Profiler parsing logic, and keeps the skill package easier to maintain.

## Optional Future Scripts

Add these only if repeated profile-analysis tasks need them:

- `scripts/capture_profile.sh` – Wrap `samply record --save-only` with consistent output naming and metadata capture.
- `scripts/compare_profiles.py` – Compare two captures and emit function-level deltas.
- `scripts/export_hotspots.py` – Emit JSON/CSV for the top flat and call-tree hot spots.
- `scripts/export_collapsed.py` – Export folded stacks for flamegraph and speedscope tools.
- `scripts/fetch_from_url.py` – Decode a `profiler.firefox.com/from-url/...` link and download the embedded `profile.json`.
