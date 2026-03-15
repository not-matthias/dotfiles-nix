---
name: commit
description: "Read this skill before making git commits"
---

<!-- Source: https://github.com/mitsuhiko/agent-stuff/blob/main/skills/commit/SKILL.md -->

Create a git commit for the current changes using a concise Conventional Commits-style subject.

## Format

`<type>(<scope>): <summary>`

- `type` REQUIRED. Use `feat` for new features, `fix` for bug fixes. Other common types: `docs`, `refactor`, `chore`, `test`, `perf`.
- `scope` OPTIONAL. Short noun in parentheses for the affected area (e.g., `api`, `parser`, `ui`).
- `summary` REQUIRED. Short, imperative, <= 72 chars, no trailing period.

## Notes

- Body is **strongly encouraged** — always include one unless the change is trivially obvious (e.g., fixing a typo). The body should explain **what** changed, **why** it changed, the approach taken, and any notable decisions. A reader of `git log` should understand the change without looking at the diff.
- Do NOT include breaking-change markers or footers.
- Do NOT add sign-offs (no `Signed-off-by`).
- Only commit; do NOT push.
- If it is unclear whether a file should be included, ask the user which files to commit.
- Treat any caller-provided arguments as additional commit guidance. Common patterns:
  - Freeform instructions should influence scope, summary, and body.
  - File paths or globs should limit which files to commit. If files are specified, only stage/commit those unless the user explicitly asks otherwise.
  - If arguments combine files and instructions, honor both.

## Examples

Good commit messages are specific about *why* the change matters, not just *what* changed:
```
fix: keep keyboards and mice awake despite powertop autosuspend
fix(ida-pro): fix plugin loading errors for bindiff and binsync
fix: pin docker container images to specific versions instead of latest
fix: tune ZFS txg_sync and zrepl retention to reduce CPU overhead
feat: add agent-browser with versioned npm cache and corruption recovery
feat(niri): add shortcuts for focusing on columns
```

Bad — vague, just restates the diff
```
feat: update config
fix: fix bug
feat: add pi-mono Nix package with extension system
chore: update flake
fix: soulsync stuff
```

## Steps

1. Infer from the prompt if the user provided specific file paths/globs and/or additional instructions.
2. Review `git status` and `git diff` to understand the current changes (limit to argument-specified files if provided).
3. (Optional) Run `git log -n 50 --pretty=format:%s` to see commonly used scopes.
4. If there are ambiguous extra files, ask the user for clarification before committing.
5. Stage only the intended files (all changes if no files specified).
6. Run `git commit -m "<subject>"` (and `-m "<body>"` if needed).

<!-- Reference: https://github.com/HazAT/pi-config/blob/main/skills/commit/SKILL.md -->
