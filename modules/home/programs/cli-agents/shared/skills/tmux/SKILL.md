---
name: tmux-cli
description: Use when manipulating tmux sessions, creating windows or panes, or looking up tmux CLI commands for terminal multiplexer operations
---

# Tmux Reference

## Overview

Quick reference for tmux CLI commands. Covers session management, windows, and panes.

## When to Use

- Creating or attaching to tmux sessions
- Managing windows and panes programmatically
- Need CLI commands (not keybindings)
- Automating tmux operations

**When NOT to use:**
- Looking for keybindings (this is CLI only)
- Configuration file syntax (`.tmux.conf`)

## User's Config

- **Prefix**: `Ctrl+B` (default)
- **Base index**: 1 (windows and panes start at 1)
- **Shell**: Fish
- **Mouse**: enabled
- **Plugins**: resurrect (auto-save/restore), continuum (auto-save every 60min), cpu
- **Split bindings**: `\` horizontal, `-` vertical
- **Pane navigation**: `Ctrl+Arrow` (no prefix)

## Quick Reference

### Sessions

| Task | Command |
|------|---------|
| New session | `tmux new-session -s <name>` |
| New session (detached) | `tmux new-session -d -s <name>` |
| Attach to session | `tmux attach-session -t <name>` |
| List sessions | `tmux list-sessions` or `tmux ls` |
| Kill session | `tmux kill-session -t <name>` |
| Kill all sessions | `tmux kill-server` |
| Rename session | `tmux rename-session -t <old> <new>` |

### Windows

| Task | Command |
|------|---------|
| New window | `tmux new-window` |
| New window with name | `tmux new-window -n <name>` |
| New window with cwd | `tmux new-window -c <path>` |
| Kill window | `tmux kill-window -t <index>` |
| Rename window | `tmux rename-window -t <index> <name>` |
| Select window | `tmux select-window -t <index>` |
| List windows | `tmux list-windows` |

### Panes

| Task | Command |
|------|---------|
| Split horizontally | `tmux split-window -h` |
| Split vertically | `tmux split-window -v` |
| Split with cwd | `tmux split-window -h -c <path>` |
| Kill pane | `tmux kill-pane -t <index>` |
| Select pane | `tmux select-pane -t <index>` |
| Resize pane | `tmux resize-pane -D 10` (or `-U`, `-L`, `-R`) |
| List panes | `tmux list-panes` |

### Sending Commands

| Task | Command |
|------|---------|
| Send keys to pane | `tmux send-keys -t <target> '<command>' Enter` |
| Send keys to window | `tmux send-keys -t <session>:<window> '<command>' Enter` |
| Run command in new window | `tmux new-window '<command>'` |
| Run command in new pane | `tmux split-window '<command>'` |

### Common Patterns

**New session with named window and command:**
```bash
tmux new-session -d -s dev -n editor
tmux send-keys -t dev:editor 'nvim' Enter
tmux attach-session -t dev
```

**Multi-pane development layout:**
```bash
tmux new-session -d -s work -c ~/project
tmux split-window -h -c ~/project
tmux split-window -v -c ~/project
tmux select-pane -t 1
tmux attach-session -t work
```

**Run command in specific session/window:**
```bash
tmux send-keys -t mysession:1 'cargo test' Enter
```

**Target syntax:**
```
session:window.pane
dev:1.2          # session "dev", window 1, pane 2
:1               # current session, window 1
:.2              # current session, current window, pane 2
```

## Common Mistakes

**Wrong: Confusing split directions**
- `split-window -h` = split with a **vertical** line (panes side by side)
- `split-window -v` = split with a **horizontal** line (panes stacked)

**Wrong: Forgetting `-d` for scripted sessions**
Without `-d`, `new-session` attaches immediately, blocking further setup commands.

**Wrong: Using 0-based indices**
This config uses `base-index 1` - windows and panes start at 1, not 0.

## Notes

- All commands work from outside tmux (prefix with `tmux`)
- Target flag `-t` accepts session, window, or pane targets
- Use `-c <path>` to set working directory for new windows/panes
- Resurrect plugin auto-saves sessions; `prefix + Ctrl+S` to save manually, `prefix + Ctrl+R` to restore
