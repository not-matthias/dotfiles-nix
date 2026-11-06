#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Verify rule boundaries with the native OMP matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("never-mutate-github-review-comments.md")
NAME = RULE.stem
CASES = [
    ("gh api -X PATCH repos/a/b/pulls/comments/12", True, "tool", "bash"),
    ("gh api repos/a/b/pulls/comments/12 --method=DELETE", True, "tool", "bash"),
    (
        "gh api --method POST repos/a/b/pulls/1/comments/12/replies",
        True,
        "tool",
        "bash",
    ),
    ("gh api repos/a/b/pulls/1/comments -f body=hello", True, "tool", "bash"),
    ("gh api repos/a/b/pulls/comments/12", False, "tool", "bash"),
    ("gh api --method GET repos/a/b/pulls/1/comments", False, "tool", "bash"),
    ("gh api -X PATCH repos/a/b/issues/12", False, "tool", "bash"),
    (
        'printf "%s" "gh api -X PATCH repos/a/b/pulls/comments/12"',
        False,
        "tool",
        "bash",
    ),
    ("gh api -X PATCH repos/a/b/pulls/comments/12", False, "tool", "write"),
    ("gh api -X PATCH repos/a/b/pulls/comments/12", False, "tool", "edit"),
    ("gh api -X PATCH repos/a/b/pulls/comments/12", False, "tool", "read"),
    ("gh api -X PATCH repos/a/b/pulls/comments/12", False, "text", None),
    ("gh api -X PATCH repos/a/b/pulls/comments/12", False, "thinking", None),
]


def main() -> int:
    failures = 0
    for text, expected, source, tool in CASES:
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
            declared = hit["defined"]["regex"]
            ok = bool(declared) and hit["matched"]["regex"] == declared
        failures += not ok
        print(
            f"{'ok  ' if ok else 'FAIL'} {source}/{tool}: {text!r}: "
            f"triggered={hit is not None} expected={expected}"
        )
    print(f"{len(CASES) - failures}/{len(CASES)} cases passed")
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
