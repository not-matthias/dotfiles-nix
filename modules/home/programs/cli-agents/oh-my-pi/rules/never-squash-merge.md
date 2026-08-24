---
name: never-squash-merge
description: "Never use squash merging; preserve the original commit history"
condition: ["merge_method=squash", "Merge method:\\s*[Ss]quash"]
scope: ["tool:bash(*)", "text"]
---

Never use squash merging. Preserve the original commits with a rebase or merge commit. If repository rules disallow those methods, stop and ask instead of selecting squash.
