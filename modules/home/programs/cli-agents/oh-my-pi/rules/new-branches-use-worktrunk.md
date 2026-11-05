---
name: new-branches-use-worktrunk
description: "Create branches with Worktrunk in a separate worktree; preserve the original checkout."
condition: >-
  (?:^|[;&|()\n])\s*git(?:\s+(?:-[Cc]\s+(?:"[^"]*"|'[^']*'|[^\s;&|()<>]+)|-[pP]|--[A-Za-z][A-Za-z0-9-]*(?:=[^\s;&|()<>]+)?))*\s+(?:(?:switch(?:\s+(?:-[a-zA-Z]|--[a-z][a-z-]*(?:=[^\s;&|()<>]+)?))*\s+(?:-[cC][^\s;&|()<>]*|--(?:create|force-create|orphan)(?:=[^\s;&|()<>]+)?)|checkout(?:\s+(?:-[a-zA-Z]|--[a-z][a-z-]*(?:=[^\s;&|()<>]+)?))*\s+(?:-[bB][^\s;&|()<>]*|--orphan(?:=[^\s;&|()<>]+)?)|worktree\s+add))(?=$|[\s;&|()<>])
scope:
  - tool:bash
interruptMode: always
---

## Preserve the current checkout
Create new branches in separate worktrees with Worktrunk (`wt`), not in the current checkout.

1. Read `skill://worktrunk`.
2. Run `wt switch --create <branch> --base <start-point> --no-cd`. Preserve the intended base; use `--base=@` for the current HEAD.
3. Use the new worktree's path as `cwd` for subsequent edits, builds, commits, and pushes.

Leave the original worktree's branch, index, and uncommitted files unchanged. Do not create a branch with Git and then check it out in a separate command, or fall back to direct Git worktree creation if Worktrunk fails.