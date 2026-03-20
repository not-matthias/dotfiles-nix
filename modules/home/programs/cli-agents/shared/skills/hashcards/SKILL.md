---
name: hashcards
description: "Plain-text flashcard system using FSRS spaced repetition. Use when 'hashcards' is explicitly mentioned — for creating cards, managing decks, running reviews, or scripting card generation."
---

<!-- Source: https://github.com/eudoxia0/hashcards -->

Hashcards is a plain-text, Rust-based flashcard system using the FSRS algorithm. Cards are Markdown files identified by content hash — editing a card resets its review progress.

## Card Syntax

### Question-Answer

```markdown
Q: What is the capital of France?
A: Paris
```

### Cloze Deletion

```markdown
C: The capital of France is [Paris].
```

Multiple deletions in one card generate multiple review items:

```markdown
C: [Paris] is the capital of [France].
```

Escape literal brackets with backslash: `\[not a deletion\]`.

### Separators

Use `---` between cards for visual organization (optional, ignored by parser).

### Rich Content

- **LaTeX math**: Inline `$E = mc^2$`, display `$$\int_0^1 x\,dx$$`
- **Custom macros**: Define in frontmatter or shared macro files
- **Images**: `![alt](path/to/image.png)` (relative paths)
- **Audio**: Standard Markdown link/embed syntax
- **Code blocks**: Fenced with syntax highlighting
- **Tables**: Standard Markdown tables

### Deck Frontmatter (optional TOML)

```markdown
+++
deck = "physics"
+++

Q: What is Newton's second law?
A: F = ma
```

## CLI Commands

```bash
hashcards drill [DIRECTORY]   # Start review session (web UI on localhost:8000)
hashcards drill --host 0.0.0.0  # Bind to all interfaces
hashcards stats               # Collection statistics as JSON
hashcards check               # Verify collection integrity
hashcards orphans             # Manage deleted cards still in database
hashcards export              # Export collections as JSON
```

### Drill Options

- `--host <addr>` — Bind address (default: 127.0.0.1)
- Port selection for custom listening port
- Card limit to cap review session size
- Deck filtering to review specific decks only

### Review Grading

Four levels: **Forgot** / **Hard** / **Good** / **Easy** (keyboard shortcuts available in web UI).

Sibling burial: when a cloze card generates multiple items, reviewing one buries the others to prevent spoilers.

## Workflow Best Practices

- **Version control**: Store card files in Git — content-addressed design works naturally with diffs and history
- **Scripted generation**: Generate cards programmatically from CSV or structured data, writing Q:/A: or C: format to `.md` files
- **Deck organization**: Use directories and/or TOML frontmatter `deck` field to group cards by topic
- **Editing awareness**: Changing card text resets its FSRS progress (the hash changes). Typo fixes or rewords will lose review history
- **Integrity checks**: Run `hashcards check` periodically to catch corrupt or malformed cards
- **Stats monitoring**: Use `hashcards stats` to track review load and identify struggling decks
