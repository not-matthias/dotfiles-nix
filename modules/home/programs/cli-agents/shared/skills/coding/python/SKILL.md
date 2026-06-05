---
name: python
description: Use uv for Python development. Always prefer uv over pip/poetry/virtualenv. Use ruff for linting/formatting, pytest for testing, mypy for type checking.
license: MIT
---

# Python Development Skill

You are a Python development specialist using uv and related tools. **ALWAYS use uv** — never pip, poetry, virtualenv, or venv directly.

## Package Management with uv

**NEVER use:** `pip install`, `python -m venv`, `poetry`, `pipenv`, `conda`
**ALWAYS use:** `uv`

```bash
# Create project
uv init <name>           # New project with pyproject.toml
uv init --lib <name>     # Library project

# Dependencies
uv add <package>         # Add dependency
uv add --dev <package>   # Add dev dependency
uv remove <package>      # Remove dependency
uv sync                  # Install all deps from lockfile

# Running
uv run python script.py  # Run in project environment
uv run pytest            # Run tool in project environment
uv run <any-command>     # Preferred way to run anything

# Tools (one-off usage, no install needed)
uvx ruff check .         # Run ruff without installing
uvx mypy .               # Run mypy without installing
```

## Standard Development Workflow

Always follow this sequence:

```bash
uv run pytest -q         # Run tests first
uv run ruff check .      # Linting
uv run ruff format --check .  # Format check
uv run mypy .            # Type checking (if project uses it)
```

**Decision tree:**
1. **Validating code?** → `uv run ruff check .` (fast)
2. **Running tests?** → `uv run pytest -q`
3. **Fixing formatting?** → `uv run ruff format .`
4. **Type checking?** → `uv run mypy .`

## Ruff (Linting + Formatting)

Ruff replaces flake8, isort, black, and more. Prefer it over all of them.

```bash
uv run ruff check .              # Lint
uv run ruff check --fix .        # Auto-fix lint issues
uv run ruff format .             # Format (replaces black)
uv run ruff format --check .     # Check formatting without modifying
```

### pyproject.toml configuration

```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]  # pycodestyle, pyflakes, isort, pyupgrade
ignore = ["E501"]               # Line too long (handled by formatter)

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]           # Allow assert in tests
```

## pytest

```bash
uv run pytest                   # Run all tests
uv run pytest -q                # Quiet output
uv run pytest -x                # Stop on first failure
uv run pytest -k "test_name"    # Run matching tests
uv run pytest -v                # Verbose output
uv run pytest --tb=short        # Short traceback
uv run pytest tests/            # Run specific directory
```

### pyproject.toml configuration

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q --tb=short"
```

## mypy (Type Checking)

```bash
uv run mypy .                   # Check entire project
uv run mypy src/                # Check specific directory
uv run mypy --strict .          # Strict mode
```

### pyproject.toml configuration

```toml
[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true
```

## Project Structure

```
my-project/
├── pyproject.toml
├── uv.lock
├── src/
│   └── my_project/
│       ├── __init__.py
│       └── main.py
└── tests/
    ├── __init__.py
    └── test_main.py
```

## pyproject.toml Template

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "ruff", "mypy"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 88

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"

[tool.mypy]
strict = true
ignore_missing_imports = true
```

## Common Workflows

### New Project

```bash
uv init my-project
cd my-project
uv add --dev pytest ruff mypy
uv run pytest  # verify setup works
```

### Adding a Script Entry Point

```toml
[project.scripts]
my-tool = "my_project.cli:main"
```

```bash
uv run my-tool              # Run the script
```

### Running One-off Scripts (no project)

```bash
uv run --with requests python script.py   # Ad-hoc dependency
uvx python-script-tool                    # Run published tool
```

### Pre-commit Validation

```bash
uv run ruff check --fix . && uv run ruff format . && uv run pytest -q
```

## Common Issues

**Issue**: `ModuleNotFoundError` after `uv add`
```bash
uv sync  # Re-sync lockfile to environment
```

**Issue**: Wrong Python version
```bash
uv python pin 3.11          # Pin project to specific version
uv python install 3.11      # Install if not available
```

**Issue**: Stale lockfile
```bash
uv lock --upgrade            # Update all deps
uv lock --upgrade-package X  # Update specific package
```
