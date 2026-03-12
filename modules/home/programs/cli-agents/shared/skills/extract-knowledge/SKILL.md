---
name: extract-knowledge
description: Extract patterns and challenges from past Claude Code conversation logs and convert them into reusable skills or memory entries. Run periodically to capture recurring solutions.
license: MIT
---

# Knowledge Extraction from Claude Code Logs

Extract recurring challenges, solutions, and patterns from past Claude Code sessions and distill them into skills or memory entries.

## When to Use This Skill

- After intensive development sessions on a new project
- When you notice solving the same problem repeatedly
- Weekly scan to capture recent learnings
- Before a major refactor (capture current best practices first)

## Log Location & Format

```
~/.claude/projects/<path-encoded-dir>/
├── sessions-index.json     # Metadata index for all sessions in this project
└── <uuid>.jsonl            # Individual session (JSON Lines)
```

**sessions-index.json** — use this to quickly find relevant sessions:
```json
[{
  "sessionId": "uuid",
  "firstPrompt": "what the user asked",
  "summary": "auto-generated summary",
  "messageCount": 42,
  "created": "2025-01-01T00:00:00Z"
}]
```

## Extraction Workflow

### 1. Find relevant sessions

```bash
# List all projects
ls ~/.claude/projects/

# Scan session index for a project
cat ~/.claude/projects/<project>/sessions-index.json | \
  jq '.[] | {prompt: .firstPrompt, count: .messageCount}' | head -50

# Filter by topic
cat ~/.claude/projects/<project>/sessions-index.json | \
  jq '.[] | select(.firstPrompt | test("error|fix|debug|fail"; "i")) | .firstPrompt'
```

### 2. Extract user messages from a session

```bash
cat ~/.claude/projects/<project>/<session>.jsonl | \
  jq 'select(.type == "user") | .message.content' 2>/dev/null | head -30
```

### 3. Categorize findings

| What you found | Target skill |
|----------------|--------------|
| Nix hash errors, build failures, overlays | `nix-package` |
| IDA SDK patterns, plugin boilerplate | `ida-plugin-dev` |
| CodSpeed integration, benchmark setup | `codspeed-bench` |
| Binary analysis, unpacking, emulation | `reverse-engineer` |
| Rust cargo patterns | `rust` |

### 4. Write the finding

Use this format when adding to a skill:

```markdown
### [Problem Title]

**Context**: When does this happen?
**Symptom**: What error/behavior do you see?
**Fix**:
```code```
**Why**: Brief explanation
```

### 5. Where to put it

- **Skill file** (`modules/home/programs/cli-agents/shared/skills/<name>/SKILL.md`):
  reusable techniques, non-obvious gotchas, command patterns
- **Memory** (`~/.claude/projects/<dir>/memory/`):
  project-specific context, preferences

## What NOT to Extract

- One-off hacks for a specific version
- Things already in CLAUDE.md
- Long context dumps — summarize to the essential pattern only
