---
name: python-use-uv
description: "Use uv for Python package installation and environment management"
condition: '(?:^|[\n;&|]+)\s*(?:sudo\s+)?(?:pip(?:3(?:\.\d+)?)?\s+install\b|python(?:3(?:\.\d+)?)?\s+-m\s+(?:pip\s+install|venv|virtualenv)\b|(?:virtualenv|poetry|pipenv|conda)(?:\s|$))'
scope: "tool:bash"
---

Use `uv pip install` for package installation and `uv venv` for environment creation. Do not run `pip install`, `python -m pip install`, `python -m venv`, `virtualenv`, `poetry`, `pipenv`, or `conda` commands.

This rule does not prohibit direct Python execution or standalone tools such as `pytest`, `ruff`, or `mypy`; use the Python skill's `uv run` or `uvx` guidance for those cases.
