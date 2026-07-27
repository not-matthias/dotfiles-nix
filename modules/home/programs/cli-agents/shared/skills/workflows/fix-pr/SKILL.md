---
name: fix-pr
description: Use whenever the user asks to address, fix, resolve, review, or respond to pull-request comments or review feedback.
---

First, use the ask tool to ask:
> Do you want me to propose changes or fix them?

Do not start work until the user chooses.

Then read the `github` skill and fetch the unresolved PR comments.
- **Propose changes:** Inspect the comments and code, then list the proposed fixes. Do not edit anything.
- **Fix them:** Fix the comments, test, commit, and push. Then say:

