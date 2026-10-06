---
name: oracle
description: "Oracle second-model review: bundle prompts/files, debug, refactor, design."
---

# Oracle (CLI) — best use

Oracle bundles a prompt and selected files into a one-shot request so another
model can answer with real repository context through the API or browser. A
prompt is required; attach files only when they add necessary context. Treat
responses as advisory and verify them against the codebase and tests.

## Golden path

1. Pick the smallest file set that still contains the truth.
2. Preview the bundle with `--dry-run` and `--files-report`.
3. Use browser mode for a signed-in ChatGPT session; require verified picker evidence before claiming a specific model.
4. If a run detaches or times out, reattach to the stored session instead of
   starting a duplicate.

## Commands

- Show help:
  - `oracle --help --verbose`
- Preview without calling a model:
  - `oracle --dry-run summary --files-report -p "<task>" --file "src/**" --file "!**/*.test.*"`
- Browser run with verified model selection:
  - `oracle --engine browser --browser-manual-login --browser-model-strategy select --model gpt-5.6-sol --timeout 180 -p "<task>" --file "src/**"`
- Manual paste fallback:
  - `oracle --render-markdown --copy-markdown -p "<task>" --file "src/**"`
- Inspect sessions:
  - `oracle status --hours 72`
  - `oracle session <id> --render`

## Attaching files

`--file` accepts files, directories, and globs. Pass it multiple times or use
comma-separated entries.

- Include: `--file "src/**"`, `--file src/index.ts`, `--file docs`
- Exclude: prefix a pattern with `!`, for example `--file "!src/**/*.test.*"`
- Never attach `.env` files, private keys, auth tokens, or other secrets.
- Use `--files-report` to identify oversized inputs and keep total input under
  roughly 196k tokens.

## Engines and safety

- Explicitly select browser mode so an API key cannot silently select paid API mode.
- Browser mode requires a signed-in Chrome or Chromium session.
- API runs require explicit user consent because they may incur usage costs.
- Check the run's model-selection evidence for `verified=yes` before attributing an answer to the requested model. `--model` alone does not pin the browser model when `modelStrategy` is `ignore` or `current`; use `--browser-model-strategy current` only when the selected model does not matter.
- Sessions are stored under `~/.oracle/sessions`; override with
  `ORACLE_HOME_DIR` when needed.

## Prompt template

Oracle starts with zero project knowledge. Include:

- Project briefing: stack, services, build/test commands, and platform constraints
- Where things live: entrypoints, configs, key modules, and dependency boundaries
- Exact question, prior attempts, and verbatim error text
- Constraints such as API compatibility, performance budgets, and files not to change
- Desired output such as a patch plan, tests, risk list, or tradeoff comparison

For a long investigation, put a restorable briefing at the top of the prompt
and attach all context files required by a fresh model at the bottom.
