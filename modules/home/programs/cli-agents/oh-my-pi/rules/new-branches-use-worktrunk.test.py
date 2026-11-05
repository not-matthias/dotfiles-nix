#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise branch-creation detection through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("new-branches-use-worktrunk.md")
NAME = RULE.stem

FORBIDDEN = [
    "git switch -c feature",
    "git switch -C feature",
    "git switch -cfeature",
    "git switch --create feature",
    "git switch --force-create=feature",
    "git switch --orphan feature",
    "git checkout -b feature",
    "git checkout -Bfeature",
    "git checkout --orphan=feature",
    "git worktree add ../feature feature",
    'git -C "/tmp/project copy" switch -c feature',
    "git -C '/tmp/project copy' checkout -b feature",
    "git --no-pager -c advice.detachedHead=false switch -c feature",
    "git switch --no-track -q -c feature",
    "git checkout -q -b feature",
    "git status && git switch -c feature",
    "printf ready\ngit checkout -b feature",
    "  git\tswitch\t-c feature",
]
ALLOWED = [
    "wt switch --create feature",
    "git switch feature",
    "git checkout feature",
    "git checkout -- file.txt",
    "git checkout -- -b",
    "git status --short",
    "git worktree list",
    "mygit switch -c feature",
    "git switcheroo -c feature",
    "git worktree addition",
    'printf "%s" "git switch -c feature"',
    "# git checkout -b feature",
    "git switch",
    "git switch --cre",
]
CASES = [
    *[(text, True, "tool", "bash") for text in FORBIDDEN],
    *[(text, False, "tool", "bash") for text in ALLOWED],
    ("git switch -c feature", False, "tool", "write"),
    ("git switch -c feature", False, "tool", "edit"),
    ("git switch -c feature", False, "tool", "read"),
    ("git switch -c feature", False, "text", None),
    ("git switch -c feature", False, "thinking", None),
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
