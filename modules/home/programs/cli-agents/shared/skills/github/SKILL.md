---
name: github
description: "Use whenever working with GitHub — PRs, issues, CI runs, review comments, unresolved threads, code search, or any `gh` CLI / GraphQL query."
---

<!-- Source: https://github.com/mitsuhiko/agent-stuff/blob/main/skills/github/SKILL.md -->

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Pull Requests

Check CI status on a PR:
```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:
```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:
```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:
```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## PR Review Comments

### All comments (REST)

Fetch every review comment on a PR:
```bash
gh api repos/owner/repo/pulls/55/comments
```

> **Limitation:** The REST API returns a flat list with no `isResolved` field. You cannot distinguish resolved from unresolved threads using REST alone.

### Unresolved comments only (GraphQL)

The GraphQL API models reviews as **threads**, each with `isResolved` and `isOutdated` flags. Use this to get only actionable, unresolved threads:

```bash
gh api graphql \
  -f owner="OWNER" -f repo="REPO" -F pr=55 \
  -f query='
query FetchReviewComments($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 50) {
            nodes {
              author { login }
              body
            }
          }
        }
      }
    }
  }
}' | jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false and .isOutdated == false)'
```

Key fields on each `reviewThread`:
- **`isResolved`** — user clicked "Resolve conversation" in the GitHub UI
- **`isOutdated`** — the diff line no longer exists (code moved/deleted)

Both must be `false` for a comment to be genuinely actionable.

To exclude bot comments, add: `| select(.comments.nodes[0].author.login | endswith("[bot]") | not)`

### Script: `scripts/unresolved-pr-comments.py`

For a complete solution with pagination and formatted output, use the bundled script:

```bash
uv run scripts/unresolved-pr-comments.py <owner> <repo> <pr-number>         # exclude bots (default)
uv run scripts/unresolved-pr-comments.py <owner> <repo> <pr-number> --bots  # include bot comments
```

Handles pagination, bot filtering, and prints a numbered list of actionable threads with file path, line number, author, and comment body.

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:
```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

## JSON Output

Most commands support `--json` for structured output. You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```

## Resources

- [scripts/unresolved-pr-comments.py] - Fetch unresolved PR review threads with pagination and bot filtering
