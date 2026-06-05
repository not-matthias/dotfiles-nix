---
name: defuddle
description: Extract clean markdown content from web pages using Defuddle CLI, removing clutter and navigation to save tokens. Use instead of WebFetch when the user provides a URL to read or analyze, for online documentation, articles, blog posts, or any standard web page.
---

# Defuddle

Use Defuddle CLI to extract clean readable content from web pages. Prefer over WebFetch for standard web pages — it removes navigation, ads, and clutter, reducing token usage.

Always run via `bunx` (do not install globally).

## Usage

Always use `--md` for markdown output:

```bash
bunx defuddle parse <url> --md
```

Save to file:

```bash
bunx defuddle parse <url> --md -o content.md
```

Extract specific metadata:

```bash
bunx defuddle parse <url> -p title
bunx defuddle parse <url> -p description
bunx defuddle parse <url> -p domain
```

## Output formats

| Flag | Format |
|------|--------|
| `--md` | Markdown (default choice) |
| `--json` | JSON with both HTML and markdown |
| (none) | HTML |
| `-p <name>` | Specific metadata property |

<!-- Original source: https://github.com/kepano/obsidian-skills/blob/main/skills/defuddle/SKILL.md -->
