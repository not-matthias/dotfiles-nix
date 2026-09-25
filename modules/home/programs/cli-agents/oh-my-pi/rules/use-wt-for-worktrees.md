---
name: use-wt-for-worktrees
description: "Use Worktrunk instead of manually managing Git worktrees"
condition: "(?:^|[;&|()\\n])\\s*\\bgit\\b(?:\\s+(?:(?:-[Cc])\\s+(?:\"[^\"]*\"|'[^']*'|\\S+)|-[pP]|--[A-Za-z][A-Za-z0-9-]*(?:=\\S+)?))*\\s+worktree(?=$|[\\s;&|()<>])"
scope: "tool:bash"
---

Use Worktrunk (`wt`) for all Git worktree operations. Use `wt switch --create <branch>` to create a worktree, `wt list` to inspect worktrees, `wt switch <branch>` to switch between worktrees, and `wt remove <branch>` to remove one. Do not invoke `git worktree` directly, including via `git -C ... worktree`.
