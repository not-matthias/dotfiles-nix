---
name: llm-wiki
description: Build a comprehensive, LLM-friendly Obsidian wiki for any codebase using parallel subagents. Use when the user asks to "document the repository", "build a wiki", "create a knowledge base", "generate docs for the whole project", or wants an LLM-navigable map of a codebase. Produces atomic, interlinked notes with YAML frontmatter, Mermaid diagrams, and a graph-view-ready structure.
license: MIT
context: fork
---

<!-- Source: Original work -->

# LLM Wiki Builder

Build a comprehensive Obsidian wiki that gives any LLM (or developer) a navigable knowledge graph of an entire codebase. The wiki is a set of atomic, interlinked markdown notes with YAML frontmatter, organized into a flat folder structure with a Map-of-Content (MOC) index.

## When to Use

- User asks to "build a wiki", "document the repository", "create a knowledge base"
- User wants an LLM-navigable map of a codebase (for agent onboarding, retrieval, or human reference)
- User says "make this repo easier for an LLM to understand"

## Prerequisites

- The agent must have `read`, `write`, `find`/`search`, and `agent`/`task` tools (for parallel subagents)
- The codebase should have a manifest file (`Cargo.toml`, `package.json`, `go.mod`, `pyproject.toml`, etc.) or a discoverable module structure
- Obsidian is not required to *build* the wiki (it's plain markdown), only to *view* the graph

## Output Structure

```
<target-dir>/                 # user-specified or .agents/wiki/
├── index.md                  # Main entry point (MOC)
├── glossary.md               # Shared terminology
├── log.md                    # Prepend-only build log
├── .obsidian/                # Graph view config (optional)
├── architecture/             # System-level design notes
├── modules/                   # One note per crate/package/module
├── concepts/                  # Domain concepts and patterns
├── guides/                    # How-to guides
└── reference/                 # Reference material (APIs, existing docs, links)
```

Folder names adapt to the project. For a Rust workspace: `crates/`. For a monorepo: `packages/`. For a Python project: `modules/`. Keep it to 5-7 top-level folders.

## Workflow

### Step 1: Research Best Practices (web_search)

Search for current LLM-wiki and Obsidian-vault best practices:

- "Obsidian wiki codebase documentation structure best practices"
- "LLM friendly documentation knowledge base best practices"

Key principles to apply:

| Principle | What it means in practice |
|-----------|--------------------------|
| Three-layer architecture | Codebase is source of truth; wiki is agent-maintained markdown; schema (CLAUDE.md) co-evolves |
| Atomic notes | One concept/crate/component per note |
| Flat structure | 5-7 top-level folders, MOC index notes instead of deep nesting |
| YAML frontmatter | Every note: `title`, `type`, `tags`, `related`, `last_updated` |
| `[[wikilinks]]` | Bidirectional links for graph view; link liberally |
| Mermaid diagrams | Architecture, data flow, sequence diagrams |
| Concise + structured | LLMs perform better with focused context |

### Step 2: Scout the Repository (inline, before fan-out)

**Do NOT skip scouting.** You need the full work-list before fanning out.

1. Read the root manifest (`Cargo.toml`, `package.json`, `go.mod`, etc.) to identify all workspace members/packages
2. `read` each top-level directory to map structure
3. Read existing docs: `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/*.md`, `.github/copilot-instructions.md`
4. Read project-level architecture docs if they exist

Record:
- Full list of modules/crates/packages to document
- Key architectural facts and constraints
- Existing documentation to synthesize

### Step 3: Write Shared Context File

Write a shared context markdown file to a **normal relative path** within the project (e.g. `<target-dir>/_shared-context.md`). Include:

- Mission statement
- Best practices summary (from Step 1)
- Wiki folder structure
- Note template (see [references/note-template.md](references/note-template.md))
- Full list of modules to document
- Key architecture facts and constraints

> **Gotcha**: Do NOT use `local://` URIs for the shared context file. Some tooling creates a literal `local:` directory (with the colon) that Python `os.path.expanduser` cannot resolve. Use a normal relative path and pass the absolute path to subagents.

### Step 4: Fan Out — Wave 1 (parallel subagents)

Group modules into 6-9 task groups by subsystem. Each subagent:

1. Reads source code (manifest, `lib.rs`/`mod.rs`/`index.ts`/`__init__.py`, AGENTS.md, tests)
2. Writes wiki notes directly to disk using the `write` tool
3. Returns a structured summary (notes written, modules documented, key types found)

**Task grouping strategy** (adapt to language):

| Group | What it covers |
|-------|---------------|
| Core types/IR | Central data structures, domain model |
| Compilers/lifters | Translation pipelines |
| Analysis tools | Slicers, analyzers, passes |
| CLI + tests + guides | Entry points, test suites, user guides |
| Foundational crates | Binary parsing, config, utilities |
| Legacy/alternative implementations | Older versions, excluded modules |
| Project-level packages | FFI bindings, external tools, generators |
| Existing docs synthesis | Read all `docs/*.md`, write architecture + concept notes |

Each subagent prompt must include:
- The shared context (read the file path)
- The repo root and wiki output directory (absolute paths)
- Exact list of modules to document
- Instruction to use `[[wikilinks]]` and the note template
- Instruction to write notes to disk and return a summary

### Step 5: Write Index, Glossary, Log (inline)

After Wave 1 returns, write the top-level files:

**index.md** — Main MOC:
- "What is this project?" (1 paragraph)
- "Start Here" section (5-6 entry-point links)
- Category sections linking to all notes
- Statistics (note count, category counts)

**glossary.md** — Shared terminology:
- Tables grouped by category (core terms, domain terms, build terms)
- Each term links to its relevant note via `[[wikilink]]`

**log.md** — Prepend-only build log:
- `[YYYY-MM-DD]` summary: what was done, decisions, coverage, quality stats

**.obsidian/** config (optional, for graph view):
- `app.json`: `alwaysUpdateLinks: true`, `useMarkdownLinks: false`
- `core-plugins.json`: enable graph, backlink, outgoing-link, tag-pane
- `graph.json`: color groups per folder, force layout settings

### Step 6: Audit and Fix (inline)

Run a completeness audit:

1. **Missing modules**: Compare manifest members vs wiki notes. Add stubs for quarantined/excluded modules explaining their status.
2. **Broken wikilinks**: Regex scan all notes for `[[target]]` links that don't resolve to a note. Fix by creating missing notes or correcting the link.
3. **Frontmatter check**: Verify every note starts with `---` YAML frontmatter.
4. **Summary check**: Verify every note (except index/log) has a `## Summary` section.

> **False positive**: Literal mentions of `[[wikilinks]]` in backticks (e.g. in log.md describing the syntax) will appear as broken links. Filter these out.

### Step 7: Cleanup and Report

- Remove the `_shared-context.md` temp file
- Report final stats:

| Metric | How to count |
|--------|-------------|
| Total notes | `find <dir> -name '*.md' \| wc -l` |
| Wikilinks | `grep -roh '\[\[[^]\|#]*' <dir> --include='*.md' \| wc -l` |
| Mermaid diagrams | `grep -r '```mermaid' <dir> --include='*.md' \| wc -l` |
| Broken links | Should be 0 after audit |

## Note Template

Every note MUST follow this format. See [references/note-template.md](references/note-template.md) for the full template and [references/obsidian-config.md](references/obsidian-config.md) for the `.obsidian/` config files.

```markdown
---
title: <Note Title>
type: <architecture | module | concept | guide | reference>
tags: [list, of, tags]
related: ["[[other-note]]", "[[another-note]]"]
last_updated: YYYY-MM-DD
---

# <Title>

## Summary
One paragraph summary.

## Details
... (technical content, code blocks, Mermaid diagrams)

## Key Types / APIs
- `TypeName` - brief description

## Relationships
- Links to related notes via [[wikilinks]]
```

## Scale Guidelines

| Repository size | Subagents | Notes per agent |
|----------------|-----------|-----------------|
| < 10 modules | 3-4 | 2-3 |
| 10-30 modules | 6-9 | 3-5 |
| 30-60 modules | 9-12 | 4-6 |
| 60+ modules | 12-15 | 4-6 (split by subsystem) |

## Common Issues

**Issue**: Subagents write to relative paths instead of the wiki directory.
- **Solution**: Pass absolute paths in the prompt. Verify all files after Wave 1.

**Issue**: Broken wikilinks after audit.
- **Solution**: Either create the missing note (if it's a real concept) or fix the link target. Quarantined/excluded modules get stub notes explaining their status.

**Issue**: Notes are too shallow (just a summary, no technical detail).
- **Solution**: Ensure subagent prompts explicitly say to "read src/lib.rs or mod.rs first, then key modules" and to capture "key types/structs/enums, public API surface, design patterns, invariants".

**Issue**: Duplicate content across notes.
- **Solution**: Use the concept vs module split. A module note documents what the code IS; a concept note documents what a technique MEANS. Cross-link them.
