---
name: no-ai-attribution-in-git-commit
description: "Avoid AI attribution markers in Git commit commands"
condition: '(?i)(?=[^\r\n]*\bgit\s+commit\b)(?=[^\r\n]*(?:\bco[\s-]*authored[\s-]*by(?::\s*|\s+)claude\b|\bgenerated\s+with\s+claude(?:\s+code)?\b|\bmade[\s-]*with(?::\s*|\s+)cursor\b))[^\r\n]*'
scope: "tool:bash"
---

Do not add AI attribution markers to Git commit messages, such as `Co-Authored-By: Claude`, `Generated with Claude Code`, or `Made-with: Cursor`. This is a reminder for streamed, single-line `bash` commands only; attribution entered through an editor or a multiline commit message may not be covered.
