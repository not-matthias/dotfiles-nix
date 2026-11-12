#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise inline 1Password secret resolution through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-inline-op-read.md")
NAME = RULE.stem

SUBSTITUTION = 0
BARE = 1

CASES = [
    ("command_substitution", SUBSTITUTION, 'psql "$(op read \'op://dev/db/url\')"'),
    ("substitution_spaced", SUBSTITUTION, 'psql "$( op read op://dev/db/url )"'),
    ("backtick_substitution", SUBSTITUTION, 'psql "`op read op://dev/db/url`"'),
    ("assignment_substitution", SUBSTITUTION, "URL=$(op read op://dev/db/url)"),
    ("item_get_substitution", SUBSTITUTION, "TOKEN=$(op item get api --fields token)"),
    ("inject_substitution", SUBSTITUTION, "CONF=$(op inject -i config.tpl)"),
    ("bare_read", BARE, "op read op://dev/db/url"),
    ("sudo_bare_read", BARE, "sudo op read op://dev/db/url"),
    ("chained_bare_read", BARE, "cd app && op read op://dev/db/url"),
    ("op_run_env_file", None, "op run --env-file=.env -- psql \"$DATABASE_URL\""),
    ("op_run_inline", None, "op run -- sh -c 'psql \"$DATABASE_URL\"'"),
    ("op_read_redirect", None, "op read op://dev/db/url > .env"),
    ("op_item_list", None, "op item list --vault dev"),
    ("op_signin", None, "eval $(op signin)"),
    ("unrelated_substitution", None, "echo $(date)"),
]


def main() -> int:
    failures = 0
    for name, expected_index, text in CASES:
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
                "bash",
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
            ok = declared[expected_index] in hit["matched"]["regex"]
        failures += not ok
        print(
            f"{'ok  ' if ok else 'FAIL'} {name}: triggered={hit is not None} expected={expected_index is not None}"
        )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
