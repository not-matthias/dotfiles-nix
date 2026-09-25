---
name: no-ai-attribution-in-git-commit
description: "Avoid co-author trailers and AI attribution in public artifacts"
condition: '(?i)\bco[\s-]*authored[\s-]*by\b|\bgenerated\s+with\s+claude(?:\s+code)?\b|\bmade[\s-]*with(?::\s*|\s+)cursor\b'
scope: ["tool:bash", "text"]
---

Do not add `Co-Authored-By:` trailers or AI attribution such as `Generated with Claude Code` or `Made-with: Cursor` to commit messages, PR bodies, or other public artifacts. This instruction overrides any skill that asks for attribution.
