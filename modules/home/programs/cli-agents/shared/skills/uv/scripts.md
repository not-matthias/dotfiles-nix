# Running Scripts with uv

<!-- Source: https://github.com/mitsuhiko/agent-stuff/blob/main/skills/uv/scripts.md -->

## Basic Usage

```bash
uv run script.py                   # Run a script
uv run script.py arg1 arg2         # With arguments
uv run --python 3.10 script.py     # Specific Python version
echo 'print("hi")' | uv run -      # From stdin
```

In a project directory, use `--no-project` to skip installing the project:

```bash
uv run --no-project script.py
```

## Syntax Verification (No `__pycache__`)

Use the AST parser instead of `python -m py_compile`:

```bash
uv run python -m ast script.py >/dev/null
```

## Ad-hoc Dependencies

```bash
uv run --with requests script.py
uv run --with 'requests>2,<3' script.py
uv run --with requests --with rich script.py
```

## Inline Script Metadata (Recommended)

Declare dependencies directly in the script:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests<3",
#   "rich",
# ]
# ///
```

Then just: `uv run script.py`

### Managing Dependencies

```bash
uv init --script example.py --python 3.12   # Create script with metadata
uv add --script example.py requests rich    # Add dependencies
```

## Locking Dependencies

```bash
uv lock --script example.py  # Creates example.py.lock
```

## Reproducibility

Pin resolution date in inline metadata:

```python
# /// script
# dependencies = ["requests"]
# [tool.uv]
# exclude-newer = "2023-10-16T00:00:00Z"
# ///
```

## Executable Scripts (Shebang)

```python
#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["httpx"]
# ///

import httpx
print(httpx.get("https://example.com"))
```

```bash
chmod +x myscript
./myscript
```
