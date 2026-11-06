#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise fast-forward PR merge detection through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("fast-forward-signed-pr-merges.md")
NAME = RULE.stem

FORBIDDEN = [
    "gh pr merge 42 --rebase",
    "gh pr merge --rebase 42",
    "gh pr merge 42 -r",
    "cd repo && gh pr merge 42 --delete-branch --rebase",
    "gh pr merge 42 --rebase; echo merged",
    "  gh pr merge 42 --rebase",
]
ALLOWED = [
    "gh pr merge 42 --merge",
    "gh pr merge 42 --squash",
    "gh pr merge 42 --reviewer alice",
    "gh issue view 42",
    "echo 'gh pr merge 42 --rebase'",
    "# gh pr merge 42 --rebase",
    "gh pr merge 42",
]
CASES = [
    *[(text, True, "tool", "bash") for text in FORBIDDEN],
    *[(text, False, "tool", "bash") for text in ALLOWED],
    ("gh pr merge 42 --rebase", False, "tool", "write"),
    ("gh pr merge 42 --rebase", False, "tool", "edit"),
    ("gh pr merge 42 --rebase", False, "text", None),
    ("gh pr merge 42 --rebase", False, "thinking", None),
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
