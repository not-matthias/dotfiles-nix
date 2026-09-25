---
name: never-squash-merge
description: "Never use squash merging; preserve the original commit history"
condition: ["(?i)\\bmerge_method\\s*=\\s*squash\\b", "(?i)\\bmerge\\s+method:\\s*squash\\b", "(?:^[ \\t]*|[;&|\\n][ \\t]*)gh\\s+pr\\s+merge\\b[^\\n;&|]*\\s--squash(?:\\s|$)", "(?:^[ \\t]*|[;&|\\n][ \\t]*)git\\s+merge\\b[^\\n;&|]*\\s--squash(?:\\s|$)"]
scope: ["tool:bash", "text"]
---

Never use squash merging, including `gh pr merge --squash`, `git merge --squash`, or API requests with `merge_method=squash`. Preserve the original commits with a rebase or merge commit. If repository rules disallow those methods, stop and ask instead of selecting squash.
