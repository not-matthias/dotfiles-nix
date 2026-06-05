---
name: zoxide-nav
description: Navigate to directories using zoxide (frecency-based directory jumper).
  Use when the user says "go to", "navigate to", "cd to", "jump to" a project or
  directory by nickname/partial name (e.g. "go to my dotfiles", "jump to dot").
---

<!-- Sources: https://github.com/ajeetdsouza/zoxide, barleytea/dotfiles zoxide-guide skill -->

# Zoxide Directory Navigation

Navigate to directories using [zoxide](https://github.com/ajeetdsouza/zoxide), a frecency-based directory jumper that learns from usage patterns.

## How Zoxide Works

Zoxide maintains a database of directories the user has visited. Each directory gets a **frecency score** (frequency × recency). When you query with a partial name, zoxide returns the highest-scoring match.

- The database lives at `~/.local/share/zoxide/db.zo`
- Scores increase on each visit, decay over time
- Multiple query terms are matched in order: `zoxide query foo bar` matches paths containing `foo` then `bar`

## Finding a Directory

Use `zoxide query` to resolve a partial name to a full path:

```bash
# Find the best match (prints the path)
zoxide query <partial-name>

# Examples
zoxide query dot          # → /home/user/Documents/technical/git/dotfiles-nix
zoxide query apollo       # → /home/user/Documents/technical/git/apollo

# Multiple terms narrow results
zoxide query git dot      # matches path containing "git" then "dot"

# List all matches ranked by score
zoxide query -l <partial-name>
```

## Workflow

1. Run `zoxide query <name>` to resolve the user's partial name to a full path.
2. Use the resolved path as your working directory for subsequent commands.
3. If the query returns an error or empty result, tell the user no match was found and ask for clarification.

### Example

User says: "go to my dotfiles"

```bash
# Resolve the directory
zoxide query dotfiles
# Output: /home/user/Documents/technical/git/dotfiles-nix

# Now use that path for further work
ls /home/user/Documents/technical/git/dotfiles-nix
```

## Important Notes

- **Non-interactive shell**: The `z` / `j` shell aliases do NOT work in the Bash tool because it runs a non-interactive shell. Always use `zoxide query` instead.
- **`j` alias**: The user's fish shell has `j` as an alias for `z` (zoxide). When they say "j dot", they mean "jump to the directory matching 'dot'".
- **No cd needed**: You don't need to `cd` — just resolve the path with `zoxide query` and use absolute paths in subsequent commands.
