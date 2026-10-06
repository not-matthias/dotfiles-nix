---
name: taskwarrior-implementation
description: "Use when selecting and implementing work from Taskwarrior project tasks. Skip Triage and Backlog; follow task scope and verify outcomes."
---

# Taskwarrior Implementation

- Load the `taskwarrior` skill for task-management rules.
- Export the requested project's tasks with `task rc.context= project:<project> status:pending export`; read annotations and dependencies before selecting work.
- Skip Triage and Backlog when implementing, unless explicitly requested. In the Taskwarrior Web workflow, untagged, unstarted pending tasks are Triage; `backlog` marks Backlog. Do not treat every pending task as Todo.
- Leave skipped tasks unchanged. Respect dependency blockers and the user's explicit exclusions.
- Implement the stated outcome, not extra ideas. Ask when requirements are unclear; do not expand scope from a vague title.
- Exercise the changed behavior and report verification. Mark tasks done only when the user authorizes it; use UUIDs for updates.
