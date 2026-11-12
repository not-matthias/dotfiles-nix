#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise .env value reads in shell commands through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-dotenv-value-reads.md")
NAME = RULE.stem

PAGER = 0
SEARCH = 1

CASES = [
    ("cat_dotenv", PAGER, "tool", "bash", "cat .env"),
    ("cat_relative_dotenv", PAGER, "tool", "bash", "cat ./.env"),
    ("cat_absolute_dotenv", PAGER, "tool", "bash", "cat /srv/app/.env"),
    ("cat_quoted_dotenv", PAGER, "tool", "bash", 'cat "$HOME/app/.env"'),
    ("cat_env_suffix", PAGER, "tool", "bash", "cat .env.local"),
    ("sudo_cat_dotenv", PAGER, "tool", "bash", "sudo cat .env"),
    ("head_dotenv", PAGER, "tool", "bash", "head -5 .env"),
    ("source_dotenv", PAGER, "tool", "bash", "source .env"),
    ("dot_source_dotenv", PAGER, "tool", "bash", ". ./.env"),
    ("chained_cat_dotenv", PAGER, "tool", "bash", "cd app && cat .env"),
    ("newline_cat_dotenv", PAGER, "tool", "bash", "echo start\ncat .env"),
    ("grep_dotenv", SEARCH, "tool", "bash", "grep DATABASE_URL .env"),
    ("rg_dotenv", SEARCH, "tool", "bash", "rg '^POSTGRES' .env.production"),
    ("awk_dotenv", SEARCH, "tool", "bash", "awk -F= '{print $1}' .env"),
    ("env_redact", None, "tool", "bash", "env-redact .env"),
    ("env_redact_pipe", None, "tool", "bash", "env-redact .env | grep DATABASE"),
    ("cat_example", None, "tool", "bash", "cat .env.example"),
    ("cat_sample", None, "tool", "bash", "cat .env.sample"),
    ("cat_template", None, "tool", "bash", "cat .env.template"),
    ("cat_envrc", None, "tool", "bash", "cat .envrc"),
    ("cat_other_file", None, "tool", "bash", "cat config.toml"),
    ("write_dotenv", None, "tool", "bash", "cp .env.example .env"),
    ("append_dotenv", None, "tool", "bash", "printf 'A=1\\n' >> .env"),
    ("env_command", None, "tool", "bash", "env | sort"),
    ("process_env_substring", None, "tool", "bash", "rg 'process.env' src/"),
    ("wrong_source", None, "text", "bash", "cat .env"),
    ("wrong_tool", None, "tool", "edit", "cat .env"),
]


def main() -> int:
    failures = 0
    for name, expected_index, source, tool, text in CASES:
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
        ok = (hit is not None) == (expected_index is not None)
        if ok and expected_index is not None:
            declared = hit["defined"]["regex"]
            ok = hit["matched"]["regex"] == [declared[expected_index]]
        failures += not ok
        print(
            f"{'ok  ' if ok else 'FAIL'} {name}: triggered={hit is not None} expected={expected_index is not None}"
        )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
