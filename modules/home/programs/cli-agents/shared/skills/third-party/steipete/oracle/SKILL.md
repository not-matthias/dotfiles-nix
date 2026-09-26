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
3. Use browser mode for GPT-5.6; use API only when explicitly intended.
4. If a run detaches or times out, reattach to the stored session instead of
   starting a duplicate.

## Commands

- Show help:
  - `oracle --help --verbose`
- Preview without calling a model:
  - `oracle --dry-run summary --files-report -p "<task>" --file "src/**" --file "!**/*.test.*"`
- Browser run:
  - `oracle --engine browser --browser-manual-login --model gpt-5.6-sol --browser-thinking-time extra-high -p "<task>" --file "src/**"`
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

- Auto-selection uses API when `OPENAI_API_KEY` is set and browser otherwise.
- Browser mode requires a signed-in Chrome or Chromium session.
- API runs require explicit user consent because they may incur usage costs.
- Pin the model and set a timeout for automation.
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
