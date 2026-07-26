---
name: personal-notes
description: "Save notes, journal entries, and research to the personal-notes Obsidian vault (personal-vault-v2). Use when the user asks to 'save note', 'save to notes', 'write to personal notes', 'save to daily notes', 'note this down', or wants to persist findings/analysis to their personal vault."
license: MIT
---

# Personal Notes

Save notes to the `personal-notes` Obsidian vault — the `personal-vault-v2` vault — defaulting to the current week's `notes/` folder.

## Vault Location

Resolve the vault root dynamically:

```bash
VAULT_ROOT="$(zoxide query personal-vault-v2)"
```

## Target Directory

Notes are saved to: `$VAULT_ROOT/daily-notes/<YEAR>/week-<WEEK_NUMBER>/notes/`

Where:
- `<YEAR>` is the current year (e.g. `2026`)
- `<WEEK_NUMBER>` is the **ISO week number**, zero-padded (e.g. `week-02`, `week-12`)

Compute the current week folder:

```bash
YEAR=$(date +%Y)
WEEK=$(date +%V)  # ISO week number, zero-padded
NOTES_DIR="$VAULT_ROOT/daily-notes/$YEAR/week-$WEEK/notes"
```

If the directory does not exist, **create it** (including parent directories):

```bash
mkdir -p "$NOTES_DIR"
```

> The vault's daily journal is migrating from `daily-notes/<YEAR>/<MM>/` to the week-based layout above. Standalone notes from this skill go in the parallel `week-<WEEK>/notes/` subtree — the same layout the `codspeed-notes` vault uses. The journal note itself is still created by `devenv run daily` / `.scripts/daily-note-path.fish`; this skill does not touch it.

## File Naming

Use date + slug format:

```
<YYYY-MM-DD>-<slug>.md
```

- Date prefix is today's date
- Slug is short, lowercase, kebab-case (matching the vault's filename convention)
- Example: `2026-07-26-framework-hinge-replacement.md`

## Note Content

- Start with a `# Title` heading
- Write in markdown (Obsidian-flavored is fine: wikilinks, callouts, etc.)
- Include context about **why** the note exists, not just raw findings
- Structure with headings for scanability
- If the note captures an investigation or analysis from the current conversation, distill the key findings — don't just dump the entire conversation

## Committing

The vault uses `devenv` for git automation — **do not** run manual `git add/commit/push`. After writing the note:

```bash
cd "$VAULT_ROOT"
devenv run backup   # commits with "chore: automatic backup" and pushes
```

## When to use this skill vs. the vault's PARA routing

This skill is for **standalone, point-in-time captures** (investigations, research, meeting write-ups) — the `codspeed-notes` equivalent. The vault follows PARA methodology (see its `AGENTS.md`); when the content is clearly organizable, route it to its permanent home instead of `daily-notes/`:

- **Agent-generated analysis** → `_generated/YYYY-MM-DD-[topic].md`
- **Unsorted quick-capture before PARA triage** → `_inbox/`
- **Topic-organized knowledge** → the matching `areas/<area>/` subfolder (the vault's `AGENTS.md` has the full routing table)

Use `personal-notes` when the note is a dated capture, not a permanent `areas/` entry.

## Example

```bash
VAULT_ROOT="$(zoxide query personal-vault-v2)"
NOTES_DIR="$VAULT_ROOT/daily-notes/2026/week-30/notes"
mkdir -p "$NOTES_DIR"
# Write file: $NOTES_DIR/2026-07-26-framework-hinge-replacement.md
# Then: cd "$VAULT_ROOT" && devenv run backup
```

## Workflow

1. Resolve vault root via `zoxide query personal-vault-v2`
2. Compute the target directory from today's date (year + ISO week)
3. Create the directory if needed (`mkdir -p`)
4. Generate the filename: `<date>-<slug>.md`
5. Write the note content using the Write tool
6. Commit + push via `devenv run backup` (not manual git)
7. Confirm the path to the user
