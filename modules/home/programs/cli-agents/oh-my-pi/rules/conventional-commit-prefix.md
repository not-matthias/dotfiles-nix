---
name: conventional-commit-prefix
description: "Use a conventional prefix for commit messages"
condition: '(?i)\bgit\s+commit\b(?![^\r\n]*\s--fixup(?:=|\s))(?![^\r\n]*\s-m\s*["'']?\w+(?:\([^)]*\))?!?:)'
scope: "tool:bash"
interruptMode: never
---

Use a conventional prefix in the final commit message, such as `feat:`, `fix:`, or `chore:`. This is an advisory reminder: the matcher cannot determine whether arbitrary `-m`, editor-based, or multiline commit-message content is valid, so verify the final message yourself.

Commands using `git commit` with `--fixup` are exempt, including chained commands such as `git commit -q --fixup=732838a1 && git log --oneline -3 && git status --short`; preserve Git's autosquash message prefix.
