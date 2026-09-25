---
name: taskwarrior
description: "Use when creating, organizing, updating, or reviewing Taskwarrior tasks and projects. Covers project confirmation, concise titles, detailed annotations, and dependencies."
---

# Taskwarrior

## Organize work

- Put almost every task in a project. Reuse a suitable existing project; leave a task unassigned only when it genuinely stands alone.
- Always ask before creating a project. Propose a short name and scope, then wait for approval. Taskwarrior creates projects implicitly when a task receives a new `project:` value; this still requires confirmation.
- Inspect `task projects` and relevant tasks before adding work. Check completed tasks when needed to avoid duplicates. Check the active context; use `rc.context=` on commands that must see or modify tasks outside it.
- Keep titles concise but specific: include the target and outcome, such as `Deploy Navidrome on Framework server`. Avoid vague titles that need the annotation to identify the work.
- Taskwarrior's `description` field is the title. Put longer details in annotations with `task <uuid> annotate 'Details'`. Use a **What / How** split: **What** explains the scope, context, and desired result; **How** describes the approach, constraints, and verification. Do not merely repeat the title. Distinguish known requirements from proposed steps and unresolved questions.
- Preserve the user's scope. Do not invent deadlines, priorities, tags, or extra requirements.

## Split and sequence

- Split independently actionable outcomes into separate tasks within the same project. Keep small implementation steps in annotations.
- Taskwarrior has no native parent/sub-issue field. Represent sub-work as separate tasks; use dotted subprojects only when useful and confirmed as new projects.
- Add `depends:<prerequisite-uuid>` only when one task truly cannot proceed before another. Dependencies mean blocking, not parenthood or mere topic similarity.
- Use UUIDs for follow-up commands and dependencies; numeric IDs can change.

## Execute and verify

1. Inspect existing projects, context, and relevant tasks.
2. Confirm any new project names and any other changes for which the user requested confirmation.
3. Add tasks with `task rc.context= add project:<approved-project> 'Short title'`.
4. Obtain each UUID from a scoped JSON export, then attach annotations and genuine dependencies.
5. Read back `task rc.context= project:<approved-project> export`. Check descriptions, annotations, status, project, and dependency UUIDs against the request.
6. Report the project and created task IDs concisely. Recording a task does not authorize executing its underlying work.

Do not directly edit the Taskwarrior database. Do not mark tasks done, delete tasks, or synchronize to a remote service unless requested. If a command fails partway through, inspect saved state and resume without duplicating successful additions.

## Repository integration

- Keep this skill under `shared/program-skills/taskwarrior/` and register it through `programs.cli-agents.programSkills` only when `programs.taskwarrior.enable` is true.
