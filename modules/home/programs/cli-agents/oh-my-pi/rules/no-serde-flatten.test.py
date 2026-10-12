#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise the sibling no-serde-flatten.md rule via omp's native matcher.

Runs every case against the source file in isolation, then again through real
discovery if the rule is installed (~/.omp/agent/rules after a home-manager switch).
Exits non-zero if any case disagrees with the expected outcome.
"""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-serde-flatten.md")
NAME = RULE.stem
RS_EDIT = ["--source", "tool", "--tool", "edit", "--path", "src/lib.rs"]
FLATTEN = r"#\[serde\([^\]]*\bflatten\b"

# (name, expected_trigger, expected_regex or None, flags, text)
CASES = [
    ("bare_flatten", True, FLATTEN, RS_EDIT,
     "struct Event {\n    #[serde(flatten)]\n    kind: Kind,\n}"),
    ("flatten_with_other_args", True, FLATTEN, RS_EDIT,
     '#[serde(default, flatten)]\nextra: Extra,'),
    ("spaced_flatten_write", True, FLATTEN,
     ["--source", "tool", "--tool", "write", "--path", "src/model.rs"],
     "#[serde( rename = \"x\", flatten )]\nrecord: Box<Record>,"),
    ("nested_field", False, None, RS_EDIT,
     '#[serde(rename = "kind")]\nkind: Kind,'),
    ("adjacent_tag", False, None, RS_EDIT,
     '#[serde(tag = "t", content = "c")]\nenum Kind { A, B }'),
    ("identifier_substring", False, None, RS_EDIT,
     "#[serde(with = \"flattened_map\")]\nmap: Map,"),
    ("iterator_flatten", False, None, RS_EDIT,
     "let all: Vec<_> = nested.into_iter().flatten().collect();"),
    ("wrong_extension_md", False, None,
     ["--source", "tool", "--tool", "edit", "--path", "docs/notes.md"],
     "Avoid `#[serde(flatten)]` in hot paths."),
    ("wrong_tool_bash", False, None, ["--source", "tool", "--tool", "bash"],
     "rg '#\\[serde\\(flatten\\)\\]' src"),
    ("prose_text", False, None, ["--source", "text"],
     "The struct uses `#[serde(flatten)]` today."),
]


def run(flags: list[str], text: str, isolated: bool) -> dict:
    cmd = ["omp", "ttsr", "test", "--json", *(["--rule", str(RULE)] if isolated else []), *flags, text]
    out = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(out.stdout)


def rule_is_discovered() -> bool:
    out = subprocess.run(["omp", "ttsr", "list", "--json"], capture_output=True, text=True)
    return NAME in out.stdout


def main() -> int:
    failures = 0
    modes = [(True, "isolated ")]
    if rule_is_discovered():
        modes.append((False, "discovery"))
    else:
        print(f"[discovery] skipped: {NAME} not installed yet (home-manager switch pending)")
    for isolated, mode in modes:
        for name, expected, pattern, flags, text in CASES:
            result = run(flags, text, isolated)
            hit = next((t for t in result.get("triggered", []) if t.get("name") == NAME), None)
            ok = (hit is not None) == expected
            if ok and pattern is not None:
                ok = pattern in hit.get("matched", {}).get("regex", [])
            status = "ok  " if ok else "FAIL"
            failures += not ok
            print(f"[{mode}] {status} {name:30} triggered={hit is not None} expected={expected}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
