---
description: Prefer safe fast-forward updates when merging pull requests
condition: >-
  (?:^|[;&|()\n])[ \t]*gh\s+pr\s+merge\b[^;&|\n]*[ \t](?:--rebase|-r)(?=$|[\s;&|)])
scope:
  - tool:bash
interruptMode: always
---

Do not use `gh pr merge --rebase`. Prefer updating the pull request's base branch to its head with a normal fast-forward push when the repository permits it. This preserves the existing commits and their signatures rather than relying on GitHub-generated rebase commits.

1. Inspect the pull request's actual base repository and branch, head SHA, required reviews, checks, and branch protection. Fetch the current base and head from the correct remotes; do not assume `origin/main`.
2. Verify the base commit is an ancestor of the head. If not, rebase only when rewriting the PR branch is safe and permitted. Updating the rewritten head may require `git push --force-with-lease`; do so only if that branch is unprotected and repository policy and user authorization allow it, and never force-push a protected ref. When signatures are required, sign every rewritten commit and verify those signatures. Rerun required checks and verify ancestry and signatures again; otherwise stop.
3. When signed commits are required, verify every commit in `base..head` is signed, for example with `git log --format='%h %G? %s' <base-ref>..<head-sha>`; every entry must show `G`.
4. Only when the fast-forward, required signatures, reviews, checks, and repository policy all pass, update the actual base ref with a normal push, such as `git push <base-remote> <head-sha>:refs/heads/<base-branch>`. Never force-push the base ref or bypass branch protection. If direct updates are prohibited, stop and report the blocker rather than switching merge methods.
5. Confirm the pull request is merged with `gh pr view <N> --json state`.

Fast-forwarding is the user's approved default when these conditions hold. Do not ask again or offer squash merging. If any condition fails, stop and explain why; do not assume every pull request can be fast-forwarded.
