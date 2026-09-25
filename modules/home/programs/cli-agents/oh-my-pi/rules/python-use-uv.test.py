#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise Python package and environment command detection."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("python-use-uv.md")
NAME = RULE.stem

CASES = [
    ("pip_install", True, "tool", "bash", "pip install requests"),
    ("pip3_install", True, "tool", "bash", "pip3 install requests"),
    ("versioned_pip_install", True, "tool", "bash", "pip3.12 install requests"),
    ("leading_whitespace", True, "tool", "bash", "  pip install requests"),
    ("newline_separated", True, "tool", "bash", "echo ready\n  pip install requests"),
    ("chained_install", True, "tool", "bash", "echo ready && pip install requests"),
    (
        "python_module_pip_install",
        True,
        "tool",
        "bash",
        "python -m pip install requests",
    ),
    (
        "versioned_python_module_pip_install",
        True,
        "tool",
        "bash",
        "python3.12 -m pip install requests",
    ),
    ("python_module_venv", True, "tool", "bash", "python -m venv .venv"),
    ("versioned_python_module_venv", True, "tool", "bash", "python3 -m venv .venv"),
    ("python_module_virtualenv", True, "tool", "bash", "python -m virtualenv .venv"),
    ("virtualenv_command", True, "tool", "bash", "virtualenv .venv"),
    ("poetry_command", True, "tool", "bash", "poetry add requests"),
    ("pipenv_command", True, "tool", "bash", "pipenv install requests"),
    ("conda_command", True, "tool", "bash", "conda create -n test"),
    ("uv_pip_install", False, "tool", "bash", "uv pip install requests"),
    ("uv_venv", False, "tool", "bash", "uv venv .venv"),
    ("direct_python", False, "tool", "bash", "python script.py"),
    ("python_module_pytest", False, "tool", "bash", "python -m pytest"),
    ("pip_show", False, "tool", "bash", "pip show requests"),
    ("embedded_pip_text", False, "tool", "bash", "echo 'pip install requests'"),
    ("pip_substring", False, "tool", "bash", "mypip install requests"),
    ("wrong_source", False, "text", "bash", "pip install requests"),
    ("wrong_tool", False, "tool", "edit", "pip install requests"),
]


def run(source: str, tool: str, text: str) -> dict:
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
    return json.loads(result.stdout)


def main() -> int:
    failures = 0
    for name, expected, source, tool, text in CASES:
        result = run(source, tool, text)
        hit = next(
            (item for item in result.get("triggered", []) if item.get("name") == NAME),
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
