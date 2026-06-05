---
name: export-gist
description: Export the current Claude Code conversation to a GitHub Gist as markdown.
  Use when sharing conversation history, archiving sessions, or creating shareable
  documentation from a Claude Code conversation.
license: MIT
---

# Export Gist

Export your Claude Code conversation to a GitHub Gist for sharing and archiving.

## When to Use

- Sharing a conversation with others
- Creating a shareable record of your work
- Archiving important problem-solving sessions
- Documenting debugging or design discussions

## Prerequisites

- `gh` CLI installed and authenticated with GitHub
- Active Claude Code project (conversation JSONL files in `~/.claude/projects/`)

## Workflow

The skill provides a Python script that exports your conversation. When invoked, it will:

1. Find your project's conversation directory (encoded path in `~/.claude/projects/`)
2. Locate the conversation JSONL file (most recent or specified by session ID)
3. Convert to readable markdown with metadata
4. Upload to GitHub as a gist
5. Return the shareable gist URL

You can pass an optional session ID to export a specific conversation, or it will use the most recent one.

## Examples

The skill runs the export script directly. When invoked, you'll see output like:

```
Converting session: abc123def456
Gist created: https://gist.github.com/not-matthias/xyz789...
```

To export a specific session, provide the session ID to the script.

## How It Works

1. **Finds** the conversation directory for your project (encoded path in `~/.claude/projects/`)
2. **Locates** the conversation file (JSONL format) - either the most recent or specified by session ID
3. **Extracts** messages, filtering out tool results and sidechain messages
4. **Converts** to readable markdown with metadata (session ID, project, branch, start time)
5. **Uploads** to GitHub as a public gist using `gh gist create`
6. **Returns** the gist URL

## Common Issues

**"No conversation directory found"**
- Ensure you're in the correct project directory where you started Claude Code
- The script uses `CLAUDE_PROJECT_DIR` environment variable or current working directory

**"No conversations found"**
- The project has no conversation history yet
- Run a Claude Code session first, then export

**"gh: command not found"**
- Install the GitHub CLI: `nix-shell -p gh` or your package manager
- Authenticate with: `gh auth login`

**"Error creating gist"**
- Verify GitHub CLI is authenticated: `gh auth status`
- Check internet connection
- Review the error message for GitHub API details

## Tips

- Exports are public gists by default (GitHub gists are public unless you have GitHub Pro)
- Session IDs are the filename of the JSONL file without extension
- Tool calls are summarized compactly (bash commands, file paths) for readability
- Tool results and thinking blocks are omitted to keep gists concise
