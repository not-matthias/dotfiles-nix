#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise attribution detection through omp's native matcher."""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-ai-attribution-in-git-commit.md")
NAME = RULE.stem

HEREDOC = """cd /home/not-matthias/Documents/work/wgit/runner.cod-3659-bound-stacks-ring-reads-and-release-paused-pids-at-a-low && git add -u crates/memtrack && git -c core.hooksPath=/dev/null commit -q -F - <<'EOF'
perf(memtrack): bound ring reads and resume paused pids at low fill

A regular poll tick drained the whole ring in one `poll(ZERO)`, and
pressure-stopped processes were resumed only after that tick ended with
the ring completely empty. On a large memory benchmark suite with stack
capture, single ticks of the stacks ring ran 0.4-1.7 s, every pressure
stop landed inside one, and stopped processes waited 238-513 ms (median)
to resume, 5-7% of the run.

Ticks now read in chunks of 1024 records with `consume_raw_n` and check
the fill between chunks. Paused processes resume once the ring is below
a quarter full instead of empty; BPF stops them at three quarters, so the
two thresholds leave room between stop and resume. `drain()` still reads
the ring fully, and shutdown still releases unconditionally.

Closes COD-3659

Co-Authored-By: Claude <noreply@anthropic.com>
EOF"""

CASES = [
    ("reported_heredoc", True, "tool", "bash", HEREDOC),
    (
        "clean_heredoc",
        False,
        "tool",
        "bash",
        HEREDOC.replace("\nCo-Authored-By: Claude <noreply@anthropic.com>", ""),
    ),
    (
        "inline_trailer",
        True,
        "tool",
        "bash",
        'git commit -m "fix: repair" -m "Co-Authored-By: Claude <noreply@anthropic.com>"',
    ),
    (
        "fixup_with_attribution",
        True,
        "tool",
        "bash",
        'git commit --fixup=abc123 -m "Co-Authored-By: Claude"',
    ),
    (
        "partial_trailer",
        True,
        "tool",
        "bash",
        "git commit -F - <<'EOF'\nfix: repair\n\nCo-Authored-By:",
    ),
    ("other_author", True, "tool", "bash", 'git commit -m "Co-Authored-By: Codex"'),
    (
        "case_and_spacing",
        True,
        "tool",
        "bash",
        'git commit -m "co authored by: Claude"',
    ),
    (
        "generated_with",
        True,
        "tool",
        "bash",
        'git commit -m "Generated with Claude Code"',
    ),
    ("made_with", True, "tool", "bash", 'gh pr create --body "Made-with: Cursor"'),
    ("text_trailer", True, "text", None, "Co-Authored-By: Claude"),
    ("clean_commit", False, "tool", "bash", 'git commit -m "fix: repair"'),
    ("clean_fixup", False, "tool", "bash", "git commit --fixup=abc123"),
    (
        "ordinary_author_prose",
        False,
        "text",
        None,
        "The commit was authored by the maintainer.",
    ),
    ("wrong_tool", False, "tool", "read", "Co-Authored-By: Claude"),
    ("wrong_source", False, "thinking", None, "Co-Authored-By: Claude"),
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
