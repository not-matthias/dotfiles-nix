#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise direct rm detection through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("use-trash-put.md")
NAME = RULE.stem

CASES = [
    ("plain_rm", True, "tool", "bash", "rm file.txt"),
    ("leading_whitespace_rm", True, "tool", "bash", "  rm file.txt"),
    ("newline_rm", True, "tool", "bash", "printf 'done\n'\nrm file.txt"),
    ("rm_flags", True, "tool", "bash", "rm -rf build/"),
    ("sudo_rm", True, "tool", "bash", "sudo rm -rf /tmp/cache"),
    ("env_rm", True, "tool", "bash", "env FORCE=1 rm file.txt"),
    ("assignment_rm", True, "tool", "bash", "CLEAN=1 rm file.txt"),
    ("trash_put", False, "tool", "bash", "trash-put file.txt"),
    ("git_rm", False, "tool", "bash", "git rm file.txt"),
    ("docker_rm_flag", False, "tool", "bash", "docker run --rm image"),
    ("rmdir_substring", False, "tool", "bash", "rmdir cache"),
    ("firm_substring", False, "tool", "bash", "firm file.txt"),
    ("wrong_source", False, "text", "bash", "rm file.txt"),
    ("wrong_tool", False, "tool", "edit", "rm file.txt"),
]


def main() -> int:
    failures = 0
    for name, expected, source, tool, text in CASES:
        result = subprocess.run(
            [
                "omp",
                "ttsr",
                "test",
                "--rule",
                str(RULE),
                "--json",
                "--source",
                source,
                "--tool",
                tool,
                text,
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        data = json.loads(result.stdout)
        hit = next(
            (item for item in data.get("triggered", []) if item.get("name") == NAME),
            None,
        )
        ok = (hit is not None) == expected
        if ok and expected:
            declared = hit["defined"]["regex"]
            ok = bool(declared) and hit["matched"]["regex"] == declared
        failures += not ok
        print(
            f"{'ok  ' if ok else 'FAIL'} {name}: triggered={hit is not None} expected={expected}"
        )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
