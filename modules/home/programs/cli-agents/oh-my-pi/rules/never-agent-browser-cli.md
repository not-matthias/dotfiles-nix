---
name: never-agent-browser-cli
description: "Never invoke the agent-browser CLI; use the built-in browser tool for UI verification"
condition: '(?:^|[;&|()\n])\s*(?:npx\s+)?agent-browser(?=$|[\s;&|()<>])'
scope:
  - tool:bash
interruptMode: always
---

Do not invoke `agent-browser` through any tool. Use the built-in `browser` tool directly; if it is unavailable, state that UI verification cannot be performed.