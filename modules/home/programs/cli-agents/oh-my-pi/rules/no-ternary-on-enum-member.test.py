#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise the sibling no-ternary-on-enum-member.md rule via omp's native matcher.

Runs every case against the source file in isolation, then again through real
discovery if the rule is installed (~/.omp/agent/rules after a home-manager switch).
Exits non-zero if any case disagrees with the expected outcome.
"""

import json
import subprocess
import sys
from pathlib import Path

RULE = Path(__file__).with_name("no-ternary-on-enum-member.md")
NAME = RULE.stem
TS_EDIT = ["--source", "tool", "--tool", "edit", "--path", "src/a.ts"]

OP_FIRST = r'[!=]==\s*[\x27"][\w-]+[\x27"]\s*\?(?![?.])'
LITERAL_FIRST = r'[\x27"][\w-]+[\x27"]\s*[!=]==\s*\w+(\.\w+)*\s*\?(?![?.])'

# (name, expected_trigger, expected_regex or None, flags, text)
CASES = [
    ("multiline_ternary", True, OP_FIRST,
     ["--source", "tool", "--tool", "edit", "--path", "src/shapes/area.ts"],
     'const areaOf: (shape: Shape) => number =\n'
     '    kind === "circle"\n'
     '      ? (shape) => Math.PI * (shape as Circle).radius ** 2\n'
     '      : areaOfPolygon;'),
    ("neq_single_quote_tsx_write", True, OP_FIRST,
     ["--source", "tool", "--tool", "write", "--path", "src/a.tsx"],
     "const x = kind !== 'square' ? a : b;"),
    ("yoda_literal_first", True, LITERAL_FIRST, TS_EDIT,
     'const x = "circle" === kind ? a : b;'),
    ("yoda_member_access", True, LITERAL_FIRST, TS_EDIT,
     "const x = 'square' !== shape.kind\n  ? a\n  : b;"),
    ("switch_iife_alternative", False, None, TS_EDIT,
     'const areaOf = (() => {\n  switch (kind) {\n    case "circle": return f;\n    case "square": return g;\n  }\n})();'),
    ("nullish_coalescing", False, None, TS_EDIT, 'const x = (a === "b") ?? c;'),
    ("optional_chain", False, None, TS_EDIT, 'const x = m === "circle"?.foo;'),
    ("boolean_and_numeric_ternary", False, None, TS_EDIT,
     'const x = isCircle ? a : b;\nconst y = n === 3 ? a : b;'),
    ("wrong_tool_bash", False, None, ["--source", "tool", "--tool", "bash"],
     "echo 'kind === \"circle\" ? a : b'"),
    ("wrong_extension_rs", False, None,
     ["--source", "tool", "--tool", "edit", "--path", "src/a.rs"],
     'let x = if k == "circle" ? a : b;'),
    ("prose_text", False, None, ["--source", "text"],
     'Avoid `kind === "circle" ? a : b` here.'),
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
