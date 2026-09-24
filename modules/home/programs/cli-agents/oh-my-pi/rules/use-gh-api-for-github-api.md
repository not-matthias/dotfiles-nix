---
name: use-gh-api-for-github-api
description: "Prefer gh api for GitHub API requests"
condition: "(?:^|[;&|]\\s*)(?:curl|wget)\\b[^;&|\\n]*https?://api\\.github\\.com(?:[/?#][^\\s;&|'\"`]*)?['\"]?(?:\\s|$)"
scope: "tool:bash"
---

For GitHub API requests, prefer the equivalent `gh api` command instead of fetching `api.github.com` directly with `curl` or `wget`. For example, use `gh api repos/OWNER/REPO/issues` for `curl https://api.github.com/repos/OWNER/REPO/issues`; this is a reminder to use GitHub-aware authentication and formatting, not a prohibition on other downloads.
