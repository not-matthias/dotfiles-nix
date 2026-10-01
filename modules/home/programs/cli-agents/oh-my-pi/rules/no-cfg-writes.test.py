#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise config writes and allowed alternatives via OMP's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-cfg-writes.md")
NAME = RULE.stem

# (name, expected trigger, source, tool, path, content)
CASES = [
    ("session_override", True, "tool", "write", "cfg://sharpshooter/model", "openai-codex/gpt-6-luna"),
    ("persisted_override", True, "tool", "write", "cfg://sharpshooter/model/save", "openai-codex/gpt-6-luna"),
    ("dotted_setting", True, "tool", "write", "cfg://sharpshooter.model/save", "openai-codex/gpt-6-luna"),
    ("record_setting", True, "tool", "write", "cfg://modelRoles/save", '{"smol":"openai-codex/gpt-6-luna"}'),
    ("empty_setting", True, "tool", "write", "cfg://shellPath", ""),
    ("partial_content", True, "tool", "write", "cfg://modelRoles/save", "{"),
    ("read_settings", False, "tool", "read", "cfg://modelRoles", "cfg://modelRoles"),
    ("edit_source_config", False, "tool", "edit", "modules/home/programs/cli-agents/oh-my-pi/config.yml", "smol: openai-codex/gpt-6-luna"),
    ("write_source_config", False, "tool", "write", "modules/home/programs/cli-agents/oh-my-pi/config.yml", "sharpshooter:\n  model: openai-codex/gpt-6-luna"),
    ("write_cfg_documentation", False, "tool", "write", "notes.md", "Do not write cfg://modelRoles/save."),
    ("other_protocol", False, "tool", "write", "proc://worker/kill", ""),
    ("similar_scheme", False, "tool", "write", "cfgx://modelRoles/save", "{}"),
    ("missing_path", False, "tool", "write", None, "cfg://modelRoles/save"),
    ("discuss_settings", False, "text", None, "cfg://modelRoles/save", "Use dotfiles-nix instead of cfg:// writes."),
    ("think_about_settings", False, "thinking", None, "cfg://modelRoles/save", "I should avoid cfg:// writes."),
]


def run_case(case: tuple, isolated: bool) -> bool:
    name, expected, source, tool, path, content = case
    command = ["omp", "ttsr", "test", "--json", "--file", "-", "--source", source]
    if isolated:
        command.extend(["--rule", str(RULE)])
    if tool:
        command.extend(["--tool", tool])
    if path:
        command.extend(["--path", path])
    result = subprocess.run(command, input=content, capture_output=True, text=True, check=True)
    hits = json.loads(result.stdout).get("triggered", [])
    hit = next((item for item in hits if item.get("name") == NAME), None)
    correct = (hit is not None) == expected
    if hit is not None:
        correct = correct and "^" in hit.get("matched", {}).get("regex", [])
    mode = "isolated" if isolated else "discovery"
    print(f"[{mode}] {'ok' if correct else 'FAIL'} {name}: triggered={hit is not None}, expected={expected}")
    return correct


def main() -> int:
    listing = subprocess.run(["omp", "ttsr", "list", "--json"], capture_output=True, text=True, check=True)
    modes = [True]
    if NAME in listing.stdout:
        modes.append(False)
    else:
        print(f"[discovery] skipped: {NAME} not installed yet (Home Manager activation pending)")
    failures = sum(not run_case(case, isolated) for isolated in modes for case in CASES)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
