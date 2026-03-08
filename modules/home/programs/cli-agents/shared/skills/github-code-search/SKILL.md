---
name: github-code-search
description: Search GitHub code using gh code-search command. Use when looking for reference implementations, code examples, or specific patterns across GitHub repositories. Particularly useful for Nix configurations, language-specific patterns, or learning how others solved similar problems.
license: MIT
---

# GitHub Code Search via gh CLI

Search across GitHub's entire codebase using the `gh code-search` command. This is faster than browsing and helps you find real-world examples of how to structure code, configure tools, or solve problems.

## When to Use

- Finding reference implementations (e.g., how others structure flake.nix)
- Learning patterns for specific languages or frameworks
- Discovering how popular projects configure tools
- Finding examples of specific Nix packages or functions
- Researching best practices for code organization

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth login`)
- Understanding basic GitHub search syntax

## Workflow

### Step 1: Construct Your Search Query

Use operators and filters to narrow results:

**Basic syntax:**
```bash
gh code-search [query] [flags]
```

**Common operators:**
- `language:nix` - Search only in Nix files
- `language:python` - Search in Python files
- `repo:owner/repo` - Limit to specific repository
- `filename:flake.nix` - Search only in files named flake.nix
- `org:nixos` - Search within an organization
- `stars:>100` - Limit to popular repos (helps avoid noise)

**Combining operators:**
```bash
gh code-search 'stdenv.mkDerivation' language:nix repo:nixos/nixpkgs stars:>50
```

### Step 2: Execute the Search

Run the search and review results:

```bash
gh code-search 'search query' language:nix --limit 10
```

**Flags:**
- `--limit N` - Show first N results (default 30, max 100)
- `--json` - Output as JSON for processing
- `--match <field>` - Match against: path, symbol, or content (default: content)

### Step 3: Navigate Results

Each result shows:
- Repository name
- File path
- Repository description
- URL to view on GitHub

Click or copy the URL to examine the full context in your browser.

## Examples

### Find Nix Package Examples

Search for how others define packages:

```bash
# Look for fetchFromGitHub usage
gh code-search 'fetchFromGitHub' language:nix stars:>50 --limit 10

# Find similar packages (e.g., Rust tools)
gh code-search 'rustPlatform.buildRustPackage' language:nix --limit 20

# Find AppImage packaging examples
gh code-search 'appimageTools' language:nix --limit 5
```

### Find Nix Service Configurations

```bash
# Systemd service examples
gh code-search 'systemd.services' language:nix org:nixos --limit 10

# Home Manager module examples
gh code-search 'home.packages' language:nix stars:>100 --limit 15
```

### Find flake.nix Patterns

```bash
# Browse flakes with specific input patterns
gh code-search 'inputs.nixpkgs' filename:flake.nix stars:>50 --limit 20

# Find flake outputs patterns
gh code-search 'outputs = {' filename:flake.nix --limit 10
```

### Non-Nix Examples

```bash
# Python package examples
gh code-search 'def setup(' language:python filename:setup.py stars:>100

# Rust build patterns
gh code-search 'cargo.toml' language:toml stars:>50

# Shell script patterns
gh code-search '#!/bin/bash' language:shell --limit 10
```

## Advanced Patterns

### Exclude Noise

Add negative filters to exclude test files or templates:

```bash
gh code-search 'pattern' language:nix -filename:test.nix
```

### Search Organization

Find patterns within the NixOS organization (most authoritative):

```bash
gh code-search 'stdenv.mkDerivation' language:nix org:nixos --limit 50
```

### Combine With Local Processing

Export to JSON and process locally:

```bash
gh code-search 'query' language:nix --json | jq '.[] | .url' > results.txt
```

## Common Issues

**Issue**: Too many irrelevant results
- **Solution**: Add filters like `stars:>100` to focus on popular, well-maintained repos. Add `org:nixos` for authoritative NixOS examples.

**Issue**: Results seem outdated
- **Solution**: Focus on recent changes by searching for specific patterns in active projects. Check the repository's last update date on GitHub.

**Issue**: Can't find specific syntax
- **Solution**: Try variations of the syntax (e.g., `stdenv.mkDerivation` vs `mkDerivation`). Search for similar projects that use the same tool/library.

## Tips

- **Start broad, narrow down**: Begin with simple queries, then add filters based on results
- **Use stars for quality**: `stars:>50` helps surface well-maintained examples
- **Check multiple examples**: Different people solve problems differently—see 3-5 implementations to find patterns
- **Use filename filters**: `filename:flake.nix` is faster than searching content for specific file types
- **Bookmark useful repos**: When you find a good reference, star it or note the URL for future reference
- **Cross-reference**: Use multiple searches to find complementary examples

## See Also

- `gh code-search --help` - Full command reference
- https://docs.github.com/en/search-github/searching-on-github/searching-code - GitHub search documentation
- https://github.com/nixos/nixpkgs - Primary Nix package repository for official examples
