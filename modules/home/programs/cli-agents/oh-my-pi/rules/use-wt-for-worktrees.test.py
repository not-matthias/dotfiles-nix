#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise worktree-command detection through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("use-wt-for-worktrees.md")
NAME = RULE.stem

CASES = [
    ("direct_worktree", True, "tool", "bash", "git worktree list"),
    (
        "leading_whitespace",
        True,
        "tool",
        "bash",
        "  git worktree add ../feature feature",
    ),
    (
        "quoted_c_path",
        True,
        "tool",
        "bash",
        'git -C "/home/user/repositories/project copy" worktree list',
    ),
    (
        "single_quoted_c_path",
        True,
        "tool",
        "bash",
        "git -C '/home/user/repositories/project copy' worktree prune",
    ),
    (
        "global_options",
        True,
        "tool",
        "bash",
        'git --no-pager -C "/tmp/project copy" -p worktree list',
    ),
    (
        "newline_command",
        True,
        "tool",
        "bash",
        "printf '%s\\n' ready\ngit worktree remove feature",
    ),
    (
        "chained_command",
        True,
        "tool",
        "bash",
        'cd /tmp/project && git -C "/tmp/project copy" worktree add ../feature feature',
    ),
    ("wt_list_allowed", False, "tool", "bash", "wt list"),
    ("wt_switch_allowed", False, "tool", "bash", "wt switch --create feature"),
    ("wt_remove_allowed", False, "tool", "bash", "wt remove feature"),
    ("ordinary_git_command", False, "tool", "bash", "git status --short"),
    ("word_boundary_plural", False, "tool", "bash", "git worktrees list"),
    ("word_boundary_suffix", False, "tool", "bash", "git worktreeish list"),
    ("word_boundary_hyphen", False, "tool", "bash", "git worktree-list"),
    ("embedded_git_name", False, "tool", "bash", "mygit worktree list"),
    ("quoted_prose", False, "tool", "bash", 'printf "%s" "git worktree list"'),
    ("wrong_tool", False, "tool", "read", "git worktree list"),
    ("wrong_source", False, "thinking", None, "git worktree list"),
    ("text_scope", False, "text", None, "git worktree list"),
]


def main() -> int:
    failures = 0
    for name, expected, source, tool, text in CASES:
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
            f"{'ok  ' if ok else 'FAIL'} {name}: triggered={hit is not None} expected={expected}"
        )
    return int(bool(failures))


if __name__ == "__main__":
    sys.exit(main())
