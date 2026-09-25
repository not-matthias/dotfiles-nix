#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise never-squash-merge.md through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("never-squash-merge.md")
NAME = RULE.stem

CASES = [
    ("api_equals", True, "tool", "bash", "merge_method=squash"),
    ("api_whitespace_case", True, "tool", "bash", "merge_method = SQUASH"),
    ("text_form", True, "text", None, "Merge method: Squash"),
    ("gh_squash", True, "tool", "bash", "gh pr merge 42 --squash"),
    ("gh_squash_leading_whitespace", True, "tool", "bash", "  gh pr merge 42 --squash"),
    ("gh_squash_newline", True, "tool", "bash", "\n  gh pr merge 42 --squash"),
    (
        "gh_squash_after_separator",
        True,
        "tool",
        "bash",
        "cd repo && gh pr merge 42 --delete-branch --squash",
    ),
    ("git_squash", True, "tool", "bash", "git merge --squash feature"),
    (
        "git_squash_leading_whitespace",
        True,
        "tool",
        "bash",
        "  git merge --squash feature",
    ),
    ("git_squash_newline", True, "tool", "bash", "\n  git merge --squash feature"),
    (
        "git_squash_after_separator",
        True,
        "tool",
        "bash",
        "git fetch origin; git merge --no-edit --squash origin/feature",
    ),
    ("safe_git_merge", False, "tool", "bash", "git merge --no-ff feature"),
    ("safe_git_rebase", False, "tool", "bash", "git rebase feature"),
    ("safe_gh_merge", False, "tool", "bash", "gh pr merge 42 --merge"),
    ("safe_gh_rebase", False, "tool", "bash", "gh pr merge 42 --rebase"),
    ("flag_boundary", False, "tool", "bash", "git merge --squashed feature"),
    ("quoted_shell_discussion", False, "tool", "bash", "echo 'git merge --squash'"),
    (
        "quoted_text_discussion",
        False,
        "text",
        None,
        'The phrase "git merge --squash" is forbidden.',
    ),
    ("filename_discussion", False, "tool", "bash", "cat docs/git merge --squash.txt"),
    ("wrong_tool", False, "tool", "read", "git merge --squash feature"),
    ("wrong_source", False, "thinking", None, "git merge --squash feature"),
]


def main() -> int:
    failures = 0
    for name, expected, source, tool, text in CASES:
        command = [
            "omp",
            "ttsr",
            "test",
            "--rule",
            str(RULE),
            "--json",
            "--source",
            source,
        ]
        if tool is not None:
            command.extend(["--tool", tool])
        result = subprocess.run(
            [*command, text], capture_output=True, text=True, check=True
        )
        data = json.loads(result.stdout)
        hit = next((item for item in data["triggered"] if item["name"] == NAME), None)
        ok = (hit is not None) == expected
        if ok and expected:
            matched = hit["matched"]["regex"]
            ok = bool(matched) and all(
                pattern in hit["defined"]["regex"] for pattern in matched
            )
        failures += not ok
        print(
            f"{'ok  ' if ok else 'FAIL'} {name}: "
            f"triggered={hit is not None} expected={expected}"
        )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
