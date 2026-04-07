---
name: claude-to-agents
description: >-
  Create symlinks between Claude-specific config files (CLAUDE.md, .claude/) and
  the generic Agent Skills convention (AGENTS.md, .agents/) so the repo works
  with any compatible agent. Use when asked to "normalize agent config", "sync
  agent files", "set up AGENTS.md", "make this repo work with other agents",
  "create generic agent config", or "claude to agents".
compatibility: Requires git and a POSIX shell (ln, mkdir, readlink)
---

<!--
Sources:
- https://agentskills.io/llms.txt (Agent Skills specification)
- https://agentskills.io/specification.md
- https://agentskills.io/client-implementation/adding-skills-support.md
-->

# Claude to Agents

Create relative symlinks between Claude-specific config and the generic
`.agents/` / `AGENTS.md` convention defined by the
[Agent Skills spec](https://agentskills.io/specification).

The `.agents/skills/` path is the official cross-client interop directory
scanned by Claude Code, Cursor, Gemini CLI, Amp, VS Code Copilot, OpenCode,
Roo Code, Goose, Junie, Codex, Kiro, and many others. See
[agentskills.io/clients](https://agentskills.io/clients.md) for the full list.

## When to Use

- User wants the repo to work with non-Claude agents
- User asks to "create AGENTS.md", "set up .agents/", or "normalize config"
- User wants cross-client skill sharing

## Mapping

| Claude-specific         | Generic equivalent       | Sync? |
|-------------------------|--------------------------|-------|
| `CLAUDE.md`             | `AGENTS.md`              | Yes   |
| `.claude/skills/`       | `.agents/skills/`        | Yes   |
| `.claude/docs/`         | `.agents/docs/`          | Yes   |
| `.claude/scripts/`      | `.agents/scripts/`       | Yes   |
| `.claude/SCRATCHPAD.md` | `.agents/SCRATCHPAD.md`  | Yes   |
| `.claude/settings.json` | —                        | No    |
| `.claude/settings.local.json` | —               | No    |
| `.claude/tmp/`          | —                        | No    |

User-level paths follow the same pattern:

| Claude user-level       | Generic user-level       |
|-------------------------|--------------------------|
| `~/.claude/skills/`     | `~/.agents/skills/`      |

## Workflow

### Step 1: Scan for existing files

From the project root:

```bash
ls -la CLAUDE.md AGENTS.md .claude .agents 2>/dev/null
```

Classify each pair:
- **Source exists, target missing** → create symlink
- **Both exist, one is already a symlink** → already synced, skip
- **Both exist, neither is a symlink** → warn user, ask which to keep
- **Neither exists** → skip

### Step 2: Determine source of truth

Whichever file/directory is a **real file** (not a symlink) is the source of
truth. If both are real:
1. Prefer the one with more content or a more recent mtime
2. If ambiguous → ask the user

### Step 3: Create symlinks

Always use **relative** symlinks so they work when the repo is cloned elsewhere.

```bash
# CLAUDE.md is source of truth
ln -s CLAUDE.md AGENTS.md

# Or AGENTS.md is source of truth
ln -s AGENTS.md CLAUDE.md

# Subdirectories — sync individually, not the whole parent
mkdir -p .agents
ln -s ../.claude/skills .agents/skills
ln -s ../.claude/docs .agents/docs

# Reverse direction
mkdir -p .claude
ln -s ../.agents/skills .claude/skills
```

### Step 4: Handle subdirectories carefully

Sync `.claude/` ↔ `.agents/` **per-subdirectory**, not by symlinking the
entire directory. Each side may have unique content (e.g. `.claude/settings.json`
is Claude-only).

Only sync: `skills/`, `docs/`, `scripts/`, `SCRATCHPAD.md`

**Never sync**: `settings.json`, `settings.local.json`, `tmp/`, or any
client-specific cache/config files.

### Step 5: Update .gitignore if needed

Ensure symlinks are tracked but ephemeral files are not:

```gitignore
# Agent config — track symlinks, ignore ephemeral
.claude/tmp/
.agents/tmp/
.claude/settings.local.json
```

### Step 6: Report

Print a summary:

```
Normalized agent config:
  CLAUDE.md ← source of truth
  AGENTS.md → CLAUDE.md (symlink created)
  .agents/skills/ → .claude/skills/ (symlink created)
  .agents/docs/ — skipped (doesn't exist on either side)
```

## Important Notes

- Always use **relative symlinks** (not absolute paths)
- Never overwrite real files with symlinks without asking
- The mapping is bidirectional — works regardless of which convention existed first
- Only handles Claude ↔ generic mapping; other client-specific files (.cursorrules, .gemini/, etc.) are out of scope
- If both CLAUDE.md and AGENTS.md have real, different content, **stop and ask** — don't silently pick one

## See Also

- https://agentskills.io/specification
- https://agentskills.io/clients.md
- https://agentskills.io/client-implementation/adding-skills-support.md
