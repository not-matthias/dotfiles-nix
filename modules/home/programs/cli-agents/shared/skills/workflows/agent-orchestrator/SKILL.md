---
name: agent-orchestrator
description: "Coordinate existing coding agents across Herdr workspaces. Use when asked to tell each agent to rebase, review changes, fix and resolve PR comments, update PR descriptions/screenshots, push, or merge into main."
---

# Agent Orchestrator

## Discover

- Load `herdr`; verify `HERDR_ENV=1` before session control.
- Load `github` for PR operations; `worktrunk` for worktree operations.
- Discover live agents; map workspace, pane ID, cwd, branch, upstream, and PR.
- Scope by requested repository; exclude unrelated agents and the caller from broadcast.
- Inspect the caller's local changes separately when publication is requested.
- Refresh discovery each batch; never assume old IDs or workspace labels still match branches.
- Missing agent: search for relocation; report absent targets, never silently omit them.
- Preserve user focus and layout; no unsolicited panes, agents, or workspace closures.

## Dispatch

- Send via `herdr agent prompt <pane-id> <prompt>`; independent targets concurrently.
- Include every user requirement and target-specific observations; no assumed shared context.
- Apply new requests to every target; track failed deliveries separately.
- Working agent: follow-up without interrupting an active build/rebase/commit.
- Approval/question UI: inspect and escalate; never answer blindly.
- Timeout/stall: inspect before retrying; no duplicate submissions by default.
- Accepted submission ≠ started turn ≠ completed work; verify the requested level.

## Publish / Merge Contract

- Inspect status and tracking; review/stage only intended feature changes, preserve unrelated work.
- Fetch latest remote `main`; rebase safely, preserve feature intent, resolve conflicts correctly.
- Review the full integrated diff; fix root causes; run project gates and actual changed behavior.
- Inspect all PR review feedback with pagination, including outdated unresolved threads.
- Fix actionable comments; resolve only verified, addressed threads; report unresolved blockers.
- Update existing PR descriptions when stale; refresh actual screenshots only when relevant.
- Commit verified work; push to an explicit feature destination before merging.
- Wrong upstream (feature tracking `main`): correct tracking, never blindly push.
- Rewritten published feature: explicit expected-tip `--force-with-lease` only; never force `main`.
- Merge only with user authorization; authorization to push is not authorization to merge.
- Already merged PR + new work: follow-up PR only when authorized; never re-merge the old PR.
- Multiple merges: serialize integration or reconcile advancing `main` per agent; verify each integrated head.
- Merge the tested head; no bypassing checks, approvals, or protections; no other worktree mutations.
- Requested global “push all, then merge” barrier: confirm every target's push before releasing merges.

## Report

- Prompt dispatch request: delivery evidence and exceptions; no waiting for unrelated completion.
- End-to-end request: observe pushes/merged PR state, not just prompts or agent lifecycle badges.
- Summarize per target: delivered/running, pushed head, PR/merge commit, or exact blocker.
- No blanket “done” while targets remain unconfirmed or blocked.
