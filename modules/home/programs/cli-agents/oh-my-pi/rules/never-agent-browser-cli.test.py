#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Verify rule boundaries with the native OMP matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("never-agent-browser-cli.md")
NAME = RULE.stem
CASES = [
    ("agent-browser open https://example.com", True, "tool", "bash"),
    ("npx agent-browser snapshot", True, "tool", "bash"),
    ("true && agent-browser click button", True, "tool", "bash"),
    ('printf "%s" "agent-browser open example.com"', False, "tool", "bash"),
    ("# agent-browser open example.com", False, "tool", "bash"),
    ("my-agent-browser open example.com", False, "tool", "bash"),
    ("wt list", False, "tool", "bash"),
    ("agent-browser open https://example.com", False, "tool", "write"),
    ("agent-browser open https://example.com", False, "tool", "edit"),
    ("agent-browser open https://example.com", False, "tool", "read"),
    ("agent-browser open https://example.com", False, "text", None),
    ("agent-browser open https://example.com", False, "thinking", None),
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
