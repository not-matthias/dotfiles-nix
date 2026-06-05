#!/usr/bin/env python3
"""
Fetch all unresolved, non-outdated PR review threads via GitHub GraphQL API.

WHY GRAPHQL INSTEAD OF REST?
  REST endpoint:  GET /repos/{owner}/{repo}/pulls/{n}/comments
    - Returns individual comments with no thread metadata.
    - Every comment looks the same whether its thread is resolved or not.
    - There is no "resolved" field on a REST comment object.

  GraphQL type: PullRequestReviewThread
    - Has `isResolved` (user clicked "Resolve conversation")
    - Has `isOutdated` (the diff line the comment was on no longer exists)
    - Both must be false for a comment to be genuinely actionable.

  The only correct way to filter unresolved comments is the GraphQL API.

Usage:
  python3 unresolved-pr-comments.py <owner> <repo> <pr-number> [--bots]
  python3 unresolved-pr-comments.py CodSpeedHQ platform 2053
  python3 unresolved-pr-comments.py CodSpeedHQ platform 2053 --bots  # include bot comments
"""

import json
import subprocess
import sys

QUERY = """
query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          isOutdated
          comments(first: 1) {
            nodes {
              author { login }
              path
              line
              body
            }
          }
        }
      }
    }
  }
}
"""

BOT_SUFFIXES = ("[bot]",)


def graphql(owner: str, repo: str, pr: int, cursor: str | None) -> dict:
    body = json.dumps(
        {"query": QUERY, "variables": {"owner": owner, "repo": repo, "pr": pr, "cursor": cursor}}
    )
    result = subprocess.run(
        ["gh", "api", "graphql", "--input", "-"],
        input=body.encode(),
        capture_output=True,
    )
    if result.returncode != 0:
        print(result.stderr.decode(), file=sys.stderr)
        sys.exit(1)
    return json.loads(result.stdout)


def fetch_all_threads(owner: str, repo: str, pr: int) -> list[dict]:
    threads = []
    cursor = None

    while True:
        data = graphql(owner, repo, pr, cursor)
        page = data["data"]["repository"]["pullRequest"]["reviewThreads"]
        threads.extend(page["nodes"])
        page_info = page["pageInfo"]
        if not page_info["hasNextPage"]:
            break
        cursor = page_info["endCursor"]

    return threads


def is_bot(login: str) -> bool:
    return any(login.endswith(s) for s in BOT_SUFFIXES)


def main():
    args = sys.argv[1:]
    include_bots = "--bots" in args
    args = [a for a in args if not a.startswith("--")]

    if len(args) < 3:
        print(__doc__)
        sys.exit(1)

    owner, repo, pr_str = args[0], args[1], int(args[2])

    print(f"Fetching review threads for {owner}/{repo}#{pr_str}...", file=sys.stderr)
    all_threads = fetch_all_threads(owner, repo, pr_str)

    # The two filters that matter:
    #   isResolved  — someone clicked "Resolve conversation"
    #   isOutdated  — the commented line no longer exists in the diff
    unresolved = [t for t in all_threads if not t["isResolved"] and not t["isOutdated"]]

    if not include_bots:
        unresolved = [
            t for t in unresolved if not is_bot(t["comments"]["nodes"][0]["author"]["login"])
        ]

    print(
        f"{len(unresolved)} unresolved threads "
        f"(of {len(all_threads)} total, bots {'included' if include_bots else 'excluded'})\n",
        file=sys.stderr,
    )

    for i, thread in enumerate(unresolved, 1):
        comment = thread["comments"]["nodes"][0]
        author = comment["author"]["login"]
        path = comment["path"]
        line = comment.get("line") or "—"
        body = comment["body"].strip()

        print(f"[{i}] {path}:{line}  @{author}")
        print(f"     {body[:300].replace(chr(10), ' ')}")
        print()


if __name__ == "__main__":
    main()
