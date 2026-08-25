---
name: python-use-uv
description: "Use uv for Python package installation and environment management"
condition: "(?:pip(?:3)?\\s+install|python(?:3(?:\\.\\d+)?)?\\s+-m\\s+pip\\s+install|python(?:3(?:\\.\\d+)?)?\\s+-m\\s+venv|virtualenv|poetry|pipenv|conda)"
scope: "tool:bash"
---

Use `uv` for Python package installation and environment management. Do not use `pip install`, `python -m pip install`, `python -m venv`, `virtualenv`, `poetry`, `pipenv`, or `conda`; choose the corresponding `uv` command instead.

This rule does not prohibit direct Python execution or standalone tools such as `pytest`, `ruff`, or `mypy`; use the Python skill's `uv run` or `uvx` guidance for those cases.
