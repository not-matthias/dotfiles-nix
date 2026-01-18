---
name: worktree-parallel
description: Create and manage Git worktrees for parallel feature development. Use when user wants to work on multiple features simultaneously or needs isolated development environments.
---

<!-- Source: Original work -->

# Worktree Parallel Skill

This skill automates creating and managing Git worktrees for simultaneous feature development.

## Key Purpose
"Create and manage a git worktree for parallel feature development, then open the new worktree in the editor" for concurrent coding sessions.

## Core Workflow Steps

1. **Confirm repository root** — Use the current directory unless specified otherwise
2. **Establish branch naming** — Default pattern is `feat/<slug>`, or use user-provided branch names
3. **Set worktree directory** — Typically `../<project_name>-wt` (created if needed)
4. **Execute worktree creation** — Uses `git worktree add` with either new or existing branches
5. **Launch editor** — Opens the worktree via `code -n <path>` or alternative editor command
6. **Initiate Codex session** — Suggests running `cd <path> && codex` in the new workspace
7. **Verify setup** — Optional confirmation using `git worktree list`

## Safety Guidelines
- Avoids `--force` flags unless explicitly requested
- Preserves existing worktrees unless cleanup is requested
- Offers optional removal commands only when the user asks

This skill streamlines parallel development workflows by eliminating manual setup steps.
