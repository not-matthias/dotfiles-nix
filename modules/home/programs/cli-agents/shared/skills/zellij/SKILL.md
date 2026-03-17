---
name: zellij
description: Use when manipulating Zellij sessions, creating tabs or panes, sending commands to panes, capturing output, or looking up Zellij CLI commands for terminal multiplexer operations
---

# Zellij Reference

## Overview

Quick reference for Zellij CLI commands. Covers session management, tabs, panes, programmatic control, and layouts.

## When to Use

- Creating or attaching to Zellij sessions
- Managing tabs and panes programmatically
- Sending commands to or reading output from panes
- Running parallel tasks in separate panes
- Automating Zellij operations

**When NOT to use:**
- Layout file syntax (see layout section below for basics)
- Deep configuration changes (edit zellij.nix directly)

## User's Config

- **Prefix/Tmux mode**: `Ctrl+B` (enters Tmux mode for tab switching)
- **Session manager**: `Ctrl+J`
- **Sessionizer**: `Ctrl+S` (zoxide-based)
- **Help/forgot**: `Ctrl+F`
- **Tab switching**: In Tmux mode, `1-9` to switch tabs
- **Mouse**: enabled
- **Pane frames**: disabled
- **Status bar**: zjstatus plugin (bottom, 2 lines)
- **Session jump**: zoxide integration in session manager

## Quick Reference

### Sessions

| Task | Command |
|------|---------|
| New session | `zellij -s <name>` |
| New session (detached) | `zellij attach -b <name>` |
| Create or attach | `zellij attach -c <name>` or `zellij attach --create <name>` |
| List sessions | `zellij list-sessions` or `zellij ls` |
| Attach to session | `zellij attach <name>` or `zellij a <name>` |
| Kill session | `zellij kill-session <name>` or `zellij k <name>` |
| Delete exited session | `zellij delete-session <name>` |
| Kill all sessions | `zellij kill-all-sessions --yes` |
| Delete all exited | `zellij delete-all-sessions` |

### Tabs

| Task | Command |
|------|---------|
| New tab | `zellij action new-tab` |
| New tab with name | `zellij action new-tab --name <name>` |
| New tab with cwd | `zellij action new-tab --cwd <path>` |
| New tab with layout | `zellij action new-tab --layout <layout>` |
| Close tab | `zellij action close-tab` |
| Rename tab | `zellij action rename-tab <name>` |
| Go to tab by name | `zellij action go-to-tab-name <name>` |
| Go to tab by index | `zellij action go-to-tab <index>` |
| Next/prev tab | `zellij action go-to-next-tab` / `go-to-previous-tab` |

### Panes

| Task | Command |
|------|---------|
| New pane (auto) | `zellij action new-pane` |
| Split right | `zellij action new-pane --direction right` |
| Split down | `zellij action new-pane --direction down` |
| Floating pane | `zellij action new-pane --floating` |
| Floating with size | `zellij action new-pane --floating --width 80% --height 60%` |
| Pane with command | `zellij action new-pane -- <command>` |
| Close pane | `zellij action close-pane` |
| Rename pane | `zellij action rename-pane <name>` |
| Move focus | `zellij action move-focus left\|right\|up\|down` |
| Toggle floating | `zellij action toggle-floating-panes` |
| Toggle fullscreen | `zellij action toggle-fullscreen-focus` |
| List panes | `zellij action list-panes` |

### Run Commands in Panes

| Task | Command |
|------|---------|
| Run in new pane | `zellij run -- <command>` |
| Run floating | `zellij run -f -- <command>` |
| Run with direction | `zellij run --direction down -- <command>` |
| Close on exit | `zellij run -c -- <command>` |
| Start suspended | `zellij run -s -- <command>` |
| Named pane | `zellij run -n "build" -- <command>` |
| In-place (replace pane) | `zellij run -i -- <command>` |
| Sized floating | `zellij run -f --width 80% --height 80% -- <command>` |

### Edit Files in Panes

| Task | Command |
|------|---------|
| Edit file | `zellij edit <file>` |
| Edit floating | `zellij edit -f <file>` |
| Edit at line | `zellij edit -l 42 <file>` |

## Programmatic Control

### Sending Text to Panes

```bash
# Send text to focused pane (no execution)
zellij action write-chars "some text"

# Send command with Enter to execute
zellij action write-chars $'echo hello\n'

# Send to specific session
zellij -s my-session action write-chars $'cargo test\n'

# Send control characters
zellij action write 3      # Ctrl+C
zellij action write 4      # Ctrl+D
zellij action write 27     # Escape
```

### Capturing Pane Output

```bash
# Dump visible pane content to file
zellij action dump-screen /tmp/output.txt

# Dump with full scrollback history
zellij action dump-screen --full /tmp/output.txt

# Dump current layout (useful for saving/sharing)
zellij action dump-layout
```

### Switch Modes Programmatically

```bash
zellij action switch-mode locked    # Pass-through mode
zellij action switch-mode normal    # Back to normal
```

## Common Patterns

**New tab for specific task:**
```bash
zellij action new-tab --name "backend" --cwd ~/api
```

**Split pane and run command:**
```bash
zellij action new-pane --direction down -- npm run dev
```

**New pane with guaranteed working directory:**
```bash
# For interactive shell with specific directory
zellij action new-pane --cwd /path/to/dir

# For command that must run in specific directory
zellij action new-pane --cwd /path/to/dir -- sh -c 'cd /path/to/dir && your-command'

# For nvim that must start in specific directory
zellij action new-pane --cwd /path/to/worktree -- sh -c 'cd /path/to/worktree && nvim'
```

**Floating scratch terminal:**
```bash
zellij action new-pane --floating --width 90% --height 90%
```

**Run parallel agents in separate sessions:**
```bash
# Create detached sessions
zellij attach -b agent-1
zellij attach -b agent-2

# Send commands to each
zellij -s agent-1 action write-chars $'cd /tmp/project1 && codex "Fix bug X"\n'
zellij -s agent-2 action write-chars $'cd /tmp/project2 && codex "Fix bug Y"\n'

# Check output
zellij -s agent-1 action dump-screen /tmp/agent1-output.txt
```

## Session Resurrection

Zellij auto-saves session state. Exited sessions can be resurrected:

```bash
zellij ls                                  # Shows EXITED sessions
zellij attach <exited-session>             # Resurrect it
zellij attach <name> --force-run-commands  # Skip "Press ENTER" confirmation
zellij delete-session <name>               # Permanently remove
```

## Setup Utilities

```bash
zellij setup --dump-config                # Print default config
zellij setup --dump-layout default        # Print default layout
zellij setup --dump-layout compact        # Print compact layout
zellij setup --generate-completion fish   # Fish completions
zellij setup --check                      # Validate config
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ZELLIJ` | Set to `0` inside a session (use for nesting prevention) |
| `ZELLIJ_SESSION_NAME` | Current session name |

## Common Mistakes

**Wrong: Using `new-pane --horizontal`**
Correct: `--direction down` (not `--horizontal`)

**Wrong: Confusing toggle with create**
- `toggle-floating-panes` = show/hide existing floating panes
- `new-pane --floating` = create NEW floating pane

**Wrong: Forgetting `action` subcommand**
`zellij new-tab` -> `zellij action new-tab`

**Wrong: Pane not starting in correct directory**
Using `--cwd` alone doesn't always ensure the command runs in that directory:
```bash
# Wrong - nvim might not start in the right directory
zellij action new-pane --cwd /path -- nvim

# Correct - explicitly cd first
zellij action new-pane --cwd /path -- sh -c 'cd /path && nvim'
```

**Wrong: Text not appearing in target pane**
- Ensure the target pane is focused
- Try switching to normal mode first: `zellij action switch-mode normal`
- Remember to include newline for execution: `$'command\n'`

## Notes

- All `zellij action` commands work inside or outside a session
- Use `--` to separate pane command from zellij options
- Direction options: `right`, `left`, `up`, `down`
- Size units: bare integers or percentages (e.g., `80%`)
- Hold SHIFT to bypass Zellij mouse capture for terminal selection
- Use `-s <session>` flag to target specific sessions when automating

<!-- Sources: openclaw/skills (jivvei/zellij), wcygan/dotfiles, denolfe/dotfiles, dashed/claude-marketplace -->
