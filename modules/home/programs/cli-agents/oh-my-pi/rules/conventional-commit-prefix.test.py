#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise the conventional commit reminder with omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("conventional-commit-prefix.md")
NAME = RULE.stem

CASES = [
    ("plain_commit", True, "tool", "bash", "git commit"),
    ("nonconventional_message", True, "tool", "bash", 'git commit -m "correct behavior"'),
    ("fixup_option_equals", False, "tool", "bash", "git commit --fixup=c0235673"),
    ("fixup_option_separate", False, "tool", "bash", "git commit --fixup c0235673"),
    ("fixup_after_other_option", False, "tool", "bash", "git commit --no-edit --fixup=c0235673"),
    ("reported_pipeline", False, "tool", "bash",
     "cargo build -p memtrack 2>&1 | tail -2 && "
     "git add crates/memtrack/src/ebpf/c/attach.h crates/memtrack/src/ebpf/c/utils/stopped.h "
     "crates/memtrack/src/ebpf/c/utils/pressure.bpf.h && "
     "git commit --fixup=c0235673 2>&1 | tail -3 && git push 2>&1 | tail -3"),
    ("message_option", False, "tool", "bash", 'git commit -m "fix: correct behavior"'),
    ("non_commit", False, "tool", "bash", "git status"),
    ("wrong_source", False, "text", "bash", "git commit"),
    ("wrong_tool", False, "tool", "edit", "git commit"),
]


def run(source: str, tool: str, text: str) -> dict:
    result = subprocess.run(
        ["omp", "ttsr", "test", "--rule", str(RULE), "--json", "--source", source, "--tool", tool, text],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def main() -> int:
    failures = 0
    for name, expected, source, tool, text in CASES:
        result = run(source, tool, text)
        hit = next((item for item in result.get("triggered", []) if item.get("name") == NAME), None)
        ok = (hit is not None) == expected
        if ok and expected:
            declared = hit["defined"]["regex"]
            ok = bool(declared) and hit["matched"]["regex"] == declared
        failures += not ok
        print(f"{'ok  ' if ok else 'FAIL'} {name}: triggered={hit is not None} expected={expected}")
    return bool(failures)


if __name__ == "__main__":
    sys.exit(main())
