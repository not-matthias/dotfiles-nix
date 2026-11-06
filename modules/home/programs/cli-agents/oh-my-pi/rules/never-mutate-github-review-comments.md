---
name: never-mutate-github-review-comments
description: "Never edit, update, restore, or reply to GitHub review comments without explicit user authorization."
condition: >-
  (?:^|[;&|()\n])\s*gh\s+api\s+(?=[^\n;&|]*repos/[^/\s]+/[^/\s]+/pulls/(?:comments/\d+|\d+/comments)(?=[/\s"'?]|$))(?=[^\n;&|]*(?:(?:--method(?:=|\s+)|-X\s*)(?:POST|PATCH|PUT|DELETE)\b|(?:-f|-F|--field|--raw-field)(?:\s|=)))[^\n;&|]+
scope:
  - tool:bash
interruptMode: always
---

Before posting, editing, deleting, restoring, or replying to a GitHub review comment, require explicit user authorization for that action. Fixing code in response to feedback does not authorize changing the thread. Without authorization, leave the thread unchanged and address the code only. Reading comments is allowed; explicitly authorized mutations may proceed.