---
name: claude-to-agents
description: >-
  Normalize Claude-specific project config to the generic Agent Skills convention.
  Merge CLAUDE.md into AGENTS.md and merge .claude/ into .agents/ as the
  canonical location, then create Claude compatibility symlinks back to the
  generic files. Use when asked to "normalize agent config", "sync agent files",
  "set up AGENTS.md", "make this repo work with other agents", "create generic
  agent config", or "claude to agents".
compatibility: Requires git, Bash, and coreutils; rsync is optional but preferred
---

<!--
Sources:
- https://agentskills.io/llms.txt (Agent Skills specification)
- https://agentskills.io/specification.md
- https://agentskills.io/client-implementation/adding-skills-support.md
-->

# Claude to Agents

Normalize Claude-specific project config to the generic `.agents/` / `AGENTS.md`
convention defined by the [Agent Skills spec](https://agentskills.io/specification).

The generic side is canonical:

- `AGENTS.md` is the real project instructions file
- `.agents/` is the real project agent-config directory
- `CLAUDE.md` is a compatibility symlink to `AGENTS.md`
- `.claude` is a compatibility symlink to `.agents`

Never make `.agents` point at `.claude`. Always merge toward `.agents`, then
replace `.claude` with a symlink.

The `.agents/skills/` path is the official cross-client interop directory
scanned by Claude Code, Cursor, Gemini CLI, Amp, VS Code Copilot, OpenCode,
Roo Code, Goose, Junie, Codex, Kiro, and many others. See
[agentskills.io/clients](https://agentskills.io/clients.md) for the full list.

## When to Use

- User wants the repo to work with non-Claude agents
- User asks to "create AGENTS.md", "set up .agents/", or "normalize config"
- User wants cross-client skill sharing
- A repo has `.claude/` content that should become shared `.agents/` content

## Canonical Mapping

| Claude-specific | Generic canonical path | Action |
|-----------------|------------------------|--------|
| `CLAUDE.md` | `AGENTS.md` | Merge content into `AGENTS.md`, then symlink `CLAUDE.md` → `AGENTS.md` |
| `.claude/` | `.agents/` | Merge directory contents into `.agents/`, then symlink `.claude` → `.agents` |
| `.claude/skills/` | `.agents/skills/` | Merged as part of the full `.claude/` directory |
| `.claude/docs/` | `.agents/docs/` | Merged as part of the full `.claude/` directory |
| `.claude/scripts/` | `.agents/scripts/` | Merged as part of the full `.claude/` directory |
| `.claude/commands/` | `.agents/commands/` | Merged as part of the full `.claude/` directory |
| `.claude/SCRATCHPAD.md` | `.agents/SCRATCHPAD.md` | Merged as part of the full `.claude/` directory |
| `.claude/settings.json` | `.agents/settings.json` | Merged so Claude still sees it through the `.claude` symlink |
| `.claude/settings.local.json` | `.agents/settings.local.json` | Preserve if present, but keep ignored |
| `.claude/tmp/` | `.agents/tmp/` | Usually skip unless the user explicitly asks to preserve it |

User-level paths can follow the same direction only when explicitly requested:
`~/.agents/` is canonical and `~/.claude` becomes a symlink to `~/.agents`.
Do not normalize user-level config unless the user asks for it.

## Workflow

### Step 1: Scan current state

From the project root:

```bash
ls -la CLAUDE.md AGENTS.md .claude .agents 2>/dev/null
find .claude .agents -maxdepth 2 -mindepth 1 -print 2>/dev/null | sort
```

Classify each path:

- **Only Claude path exists** → migrate it to the generic path, then symlink back
- **Only generic path exists** → create the Claude compatibility symlink
- **Both exist and one is already the correct symlink** → verify and skip
- **Both exist as real files/directories** → merge into the generic path first
- **Generic path points to Claude path** → convert so the generic path is real and Claude points to it

### Step 2: Normalize `AGENTS.md`

`AGENTS.md` is canonical.

- If only `CLAUDE.md` exists, move or copy it to `AGENTS.md`, then replace `CLAUDE.md` with `ln -s AGENTS.md CLAUDE.md`
- If only `AGENTS.md` exists, create `ln -s AGENTS.md CLAUDE.md`
- If both exist and are identical, keep `AGENTS.md` and replace `CLAUDE.md` with the symlink
- If both exist and differ, stop and ask which content to keep or how to merge it

Never overwrite a real `AGENTS.md` or `CLAUDE.md` without checking for content
differences first.

### Step 3: Check directory conflicts

Before copying `.claude/` into `.agents/`, find same-path files with different
content:

```bash
mkdir -p .agents

while IFS= read -r -d '' file; do
  rel="${file#./.claude/}"
  rel="${rel#.claude/}"
  target=".agents/$rel"

  if [ ! -e "$target" ]; then
    continue
  fi

  if cmp -s "$file" "$target"; then
    continue
  fi

  printf 'CONFLICT %s\n' "$rel"
done < <(find .claude -type f ! -path '.claude/tmp/*' -print0 2>/dev/null)
```

If any conflicts appear, stop and ask the user how to merge those files. Do not
silently choose `.claude` or `.agents` content for conflicting files.

### Step 4: Merge into `.agents/`

Merge all intentional `.claude/` content into `.agents/`. Prefer `rsync` when
available because it handles nested directories and hidden files cleanly:

```bash
mkdir -p .agents
rsync -a --exclude 'tmp/' .claude/ .agents/
```

If `rsync` is unavailable, use Bash and `cp -a` after conflicts are resolved:

```bash
mkdir -p .agents
shopt -s dotglob nullglob
for item in .claude/* .claude/.[!.]* .claude/..?*; do
  if [ "$(basename "$item")" = "tmp" ]; then
    continue
  fi

  cp -a "$item" .agents/
done
```

Skip ephemeral cache/temp folders unless the user explicitly asks to keep them.
Preserve Claude-specific config files like `settings.json` because Claude will
still access them through the `.claude` symlink.

### Step 5: Replace `.claude` with a symlink

After verifying the merge, remove or move the real `.claude/` directory and
create a relative symlink to `.agents`:

```bash
# If .claude is tracked, remove it from the old location after copying.
git rm -r .claude 2>/dev/null || true

# If anything remains, preserve it before replacing the directory.
if [ -e .claude ] && [ ! -L .claude ]; then
  backup=".claude.before-agents-$(date +%Y%m%d%H%M%S)"
  mv .claude "$backup"
fi

ln -s .agents .claude
```

Use `trash-put` instead of deleting any backup when available. Keep the backup
until `git diff` confirms all intended files now exist under `.agents/`.

### Step 6: Update `.gitignore` if needed

Ensure symlinks are tracked but local/ephemeral files are not:

```gitignore
# Agent config — track symlinks, ignore ephemeral/local files
.claude/tmp/
.agents/tmp/
.claude/settings.local.json
.agents/settings.local.json
```

### Step 7: Report

Print a summary:

```text
Normalized agent config:
  AGENTS.md ← canonical file
  CLAUDE.md → AGENTS.md (symlink created)
  .agents/ ← canonical directory, merged from .claude/
  .claude → .agents (symlink created)
  .agents/tmp/ — skipped as ephemeral
```

## Important Notes

- Always use **relative symlinks**: `CLAUDE.md -> AGENTS.md`, `.claude -> .agents`
- Always merge directories into `.agents/`; never merge `.agents/` into `.claude/`
- Symlink the whole `.claude` directory after merging, not individual subdirectories
- Never overwrite conflicting real files without asking the user
- Preserve `.claude/settings.json` by moving it to `.agents/settings.json`
- Keep `.agents/settings.local.json` ignored if local Claude settings are migrated
- Only handles Claude ↔ generic mapping; other client-specific files like `.cursorrules` and `.gemini/` are out of scope

## See Also

- https://agentskills.io/specification
- https://agentskills.io/clients.md
- https://agentskills.io/client-implementation/adding-skills-support.md
