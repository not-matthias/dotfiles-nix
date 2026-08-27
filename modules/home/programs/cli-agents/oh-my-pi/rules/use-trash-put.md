---
name: use-trash-put
description: "Use trash-put instead of permanently deleting files with rm"
condition: "\\brm(?:\\s|$)"
scope: "tool:bash"
---

Use `trash-put` instead of `rm` so deleted files can be restored from the trash. Replace `rm <path>` with `trash-put <path>`, including for directories and multiple paths. Do not run `rm`, `rm -r`, or `rm -rf` directly.
