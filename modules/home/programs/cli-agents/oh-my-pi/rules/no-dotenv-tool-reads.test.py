#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise .env reads through the read tool with omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-dotenv-tool-reads.md")
NAME = RULE.stem

CASES = [
    ("dotenv", True, "read", ".env", ".env"),
    ("nested_dotenv", True, "read", "services/api/.env", "services/api/.env"),
    ("dotenv_local", True, "read", ".env.local", ".env.local"),
    ("dotenv_production", True, "read", ".env.production", ".env.production"),
    ("dotenv_with_range", True, "read", ".env", ".env:1-20"),
    ("dotenv_example", False, "read", ".env.example", ".env.example"),
    ("dotenv_sample", False, "read", ".env.sample", ".env.sample"),
    ("dotenv_template", False, "read", ".env.template", ".env.template"),
    ("envrc", False, "read", ".envrc", ".envrc"),
    ("other_file", False, "read", "src/config.ts", "src/config.ts"),
    ("wrong_tool_write", False, "write", ".env", ".env"),
    ("wrong_tool_edit", False, "edit", ".env", ".env"),
    ("wrong_tool_bash", False, "bash", ".env", "cat .env"),
]


def main() -> int:
    failures = 0
    for name, expected, tool, path, text in CASES:
        result = subprocess.run(
            [
                "omp",
                "ttsr",
                "test",
                "--rule",
                str(RULE),
                "--json",
                "--source",
                "tool",
                "--tool",
                tool,
                "--path",
                path,
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
            ok = hit["matched"]["regex"] == hit["defined"]["regex"]
        failures += not ok
        print(
            f"{'ok  ' if ok else 'FAIL'} {name}: triggered={hit is not None} expected={expected}"
        )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
