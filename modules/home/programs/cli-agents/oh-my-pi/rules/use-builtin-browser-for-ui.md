---
name: use-builtin-browser-for-ui
description: "Use the builtin browser tool for UI verification instead of shelling out to agent-browser"
condition: "\\bagent-browser(?:\\s)+(?:open|wait|eval|screenshot)\\b"
scope: "tool:bash(*.png)"
---

For web UI verification, call the builtin `browser` tool directly. Do not invoke the `agent-browser` CLI through a shell command.