---
name: agent-notes
description: Save notes to the agent-notes Obsidian vault. Use when you discover something worth remembering — insights, decisions, references, or debug findings — for a specific project or as shared cross-project knowledge.
---

# Agent Notes

Save atomic notes to the shared agent-notes vault at `~/Documents/technical/git/agent-notes`.

## Before writing

1. Read `CONVENTIONS.md` at the vault root to understand the full schema and rules.
2. Check if a similar note already exists — search by title keywords in the target project folder or `shared/`.
   - **Exact match**: Update the existing note and set `verified_at` to today.
   - **Partial overlap**: Create a new note for the distinct claim. Link to the related note.
   - **No match**: Proceed with a new note.

## Creating a note

### 1. Determine the location

- **Project-scoped**: `projects/<project-name>/<date>-<title>.md`
- **Cross-project**: `shared/<date>-<title>.md`

If the project folder doesn't exist yet, create it with a `_project.md` card first (see below).

### 2. Pick the note type

| Type | When to use |
|------|-------------|
| `insight` | You discovered a fact, pattern, or non-obvious behavior |
| `decision` | A choice was made between alternatives — record the reasoning |
| `reference` | Summarizing an external resource (article, docs, tool) |
| `debug` | Bug investigation — symptoms, root cause, and fix |

### 3. Write the note

Use templates from `_templates/` in the vault root. Key rules:

- **File name**: `YYYY-MM-DD-<declarative-kebab-case-claim>.md`
- **Title = the claim**, not a topic label. If it's hard to name, the note isn't atomic enough — split it.
- **One idea per note.** Self-contained. Understandable without context.
- **Pure Markdown only.** Standard `[text](relative/path.md)` links, no wikilinks.
- **Frontmatter is required:**

```yaml
---
title: <declarative claim>
type: insight | decision | reference | debug
tags: [<tag>, ...]
confidence: high | medium | low
sources: [<url>, ...]   # optional — URLs that informed this note
created: YYYY-MM-DD
verified_at: YYYY-MM-DD
---
```

- Set `confidence` honestly: `high` = verified/certain, `medium` = likely correct, `low` = speculative.
- Set both `created` and `verified_at` to today's date.
- **Tags**: Prefer existing tags when they fit. Suggested set: `rust`, `python`, `nix`, `performance`, `security`, `ci`, `architecture`, `debugging`, `tooling`. Add new tags freely if none fit.

### 4. Link to related notes

Link aggressively. When a note relates to another, add a `[text](relative/path.md)` link in the body.

## Creating a new project

When saving a note for a project that doesn't have a folder yet:

1. Create `projects/<project-name>/`
2. Create `projects/<project-name>/_project.md` using the project template:

```yaml
---
name: <project name>
description: <one-line summary>
status: active | paused | archived
tags: [<tag>, ...]
links:
  repo: <url>
  docs: <url>          # optional
  ci: <url>            # optional
  tracker: <url>       # optional
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

3. Then create the note in that folder.

## After writing

Commit and push changes:

```bash
cd ~/Documents/technical/git/agent-notes
git add <files>
git commit -m "note(<project>): <short description>"
git push
```

## Staleness rule

When reading existing notes: if `verified_at` is older than 30 days and `confidence` is not `high`, verify the claim before acting on it. If a note is wrong, fix it or delete it. Never leave known-wrong notes in the vault.
