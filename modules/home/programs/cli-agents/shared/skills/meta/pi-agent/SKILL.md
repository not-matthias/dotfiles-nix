---
name: pi-agent
description: Spawn the pi coding agent with a specific model/provider. Use when asked to run pi with a particular model, switch pi's model, use DeepSeek V4 Flash/Pro in pi, or look up pi's --model/--provider/--models CLI flags and thinking-level shorthand.
---

# Spawning pi with a specific model

`pi` (the pi-mono coding agent) selects its model from CLI flags. Args without a
flag are treated as the initial prompt, so the model must be passed explicitly.

## CLI flags

| Flag | Purpose |
|------|---------|
| `--provider <name>` | Provider id (default: `google`) |
| `--model <pattern>` | Model id/pattern. Supports `provider/id` and `:<thinking>` suffix |
| `--models <patterns>` | Comma-separated patterns for Ctrl+P in-session cycling (globs + fuzzy: `anthropic/*`, `*sonnet*`) |
| `--thinking <level>` | `off`, `minimal`, `low`, `medium`, `high`, `xhigh` |
| `--list-models [search]` | List available models (fuzzy filter optional) |

Each value flag needs an argument — `pi --model` alone errors as "Unknown option".

### Equivalent ways to pick a model

```bash
pi --provider openai --model gpt-4o-mini "refactor this"   # provider + bare id
pi --model openai/gpt-4o "refactor this"                   # provider/id prefix
pi --model sonnet:high "solve this"                        # model + thinking shorthand
```

## DeepSeek V4 Flash & Pro

Two routes. Pick based on which API key is in pi's env file
(`secrets/pi-mono-env.age` → `~/.pi`):

### Via OpenRouter — the configured provider in this dotfiles (`OPENROUTER_API_KEY`)

```bash
pi --provider openrouter --model deepseek/deepseek-v4-flash "your prompt"
pi --provider openrouter --model deepseek/deepseek-v4-pro   "your prompt"

# Free Flash tier:
pi --provider openrouter --model "deepseek/deepseek-v4-flash:free" "your prompt"
```

> Use `--provider openrouter` explicitly. `--model deepseek/deepseek-v4-flash`
> alone parses `deepseek/` as the *native* deepseek provider, not OpenRouter.

### Via DeepSeek's native API (`DEEPSEEK_API_KEY`, api.deepseek.com)

```bash
pi --provider deepseek --model deepseek-v4-flash "your prompt"
pi --provider deepseek --model deepseek-v4-pro   "your prompt"
```

### Cycle between Flash and Pro in-session (Ctrl+P)

```bash
pi --provider openrouter --models deepseek/deepseek-v4-flash,deepseek/deepseek-v4-pro
```

## Notes

- Verify availability and exact ids with `pi --list-models deepseek` (needs the
  relevant API key in the environment).
- Combine with `-p`/`--print` for non-interactive runs, e.g.
  `pi --provider openrouter --model deepseek/deepseek-v4-pro -p "summarize README"`.
