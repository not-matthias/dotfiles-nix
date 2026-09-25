---
name: use-trash-put
description: "Use trash-put instead of permanently deleting files with rm"
condition: '(?:^|(?:&&|\|\||[;&|])|\r?\n)\s*(?:[A-Za-z_][A-Za-z0-9_]*=[^\s;&|]+\s+)*(?:(?:sudo|env)(?:\s+(?:-[^\s;&|]+(?:\s+[^\s;&|]+)?|[A-Za-z_][A-Za-z0-9_]*=[^\s;&|]+))*\s+)?rm(?=\s|$)'
scope: "tool:bash"
---

Use `trash-put` instead of directly running `rm` so deleted files can be restored from the trash. Replace direct `rm <path>` with `trash-put <path>`, including command chains and `sudo` or `env` prefixes. This does not apply to `git rm` or `docker --rm`.
