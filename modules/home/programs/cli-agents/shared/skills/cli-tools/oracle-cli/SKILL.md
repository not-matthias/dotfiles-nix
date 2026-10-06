---
name: oracle-cli
description: Use for Oracle CLI second-model reviews, prompt/file bundling, browser login, and session recovery.
---

# Oracle CLI

Oracle CLI bundles a prompt and selected project files for a second-model review. Treat responses as advice and verify them against the project; never attach secrets, cookie databases, private keys, or `.env` files.

## Consult workflow

1. Give the model a project briefing, exact question, prior attempts, constraints, and desired output. Select the smallest files that contain the answer.
2. Preview the bundle without calling a model:

   ```sh
   oracle --dry-run summary --files-report -p 'Review this change for risks' --file 'src/**' --file '!**/*.test.*'
   ```

3. For a ChatGPT browser run, use the dedicated signed-in Oracle profile. This machine's `~/.oracle/config.json` selects browser mode, Helium, manual login, and GPT-5.6 Sol:

   ```sh
   oracle --engine browser --browser-model-strategy select --model gpt-5.6-sol \
     --timeout 180 -p 'Review this change for risks' --file 'src/**'
   ```

   API mode may incur charges; use it only when explicitly intended. On a new machine, sign in once with `--engine browser --browser-manual-login --browser-chrome-path "$(command -v helium)" --browser-keep-browser`. Check `oracle session <id> --render` for `verified=yes` before attributing an answer to the requested model; `modelStrategy: "ignore"` and `"current"` do not verify it.

4. Recover detached or timed-out sessions instead of resubmitting:

   ```sh
   oracle status --hours 72
   oracle session <id> --render
   ```

   For manual paste without a model call, use `oracle --render-markdown --copy-markdown -p '...' --file path/to/file`.

This repo patches Oracle's ChatGPT turn detection and model picker in `pkgs/oracle-chatgpt-turns.patch` and `pkgs/oracle-model-picker.patch`. Dropping either patch can leave submitted answers uncaptured or model requests unverified.

## Cookie-sync fallback

The bundled [`scripts/oracle-helium`](scripts/oracle-helium) wrapper copies Helium cookies as a last resort. Prefer manual login: cookie copying can rotate auth tokens and log out the original Helium session. The wrapper selects Helium and its cookie database, then tries the Chromium safe-storage key from `secret-tool` for the Oracle process.

1. Choose the smallest nonsecret file set and preview before every model run (from the repository root):

   ```sh
   modules/home/programs/cli-agents/shared/skills/cli-tools/oracle-cli/scripts/oracle-helium \
     --dry-run summary --files-report \
     -p 'Your specific question' --file README.md
   ```

2. Run from a desktop shell with access to its Wayland display:

   ```sh
   nix-shell -p libsecret --run \
     'modules/home/programs/cli-agents/shared/skills/cli-tools/oracle-cli/scripts/oracle-helium --timeout 180 -p "Your specific question" --file README.md'
   ```

The database's ChatGPT cookies are `v11` encrypted, and this machine has a Chromium keyring entry. Oracle's `sweet-cookie` treats an unrecognized Helium database path as Chrome, so it looks for the wrong safe-storage key. The wrapper tries the Chromium key as a temporary process-local override. Never print the key or enable shell tracing. Adapt the executable, profile path, and keyring identity if a different installation requires it.

## Diagnosis and alternatives

- Launcher mode `ECONNREFUSED 127.0.0.1:9222` may mean the newly launched browser exited. Here the agent shell had no `WAYLAND_DISPLAY`, although `/run/user/1000/wayland-1` existed. An isolated headful launch succeeded after setting `WAYLAND_DISPLAY=wayland-1 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus`. Check the current session's sockets before setting these variables; changing `--browser-port` does not supply a display.
- `No ChatGPT cookies were applied` despite a session-token cookie in the database: check `secret-tool` availability and the keyring identity. Do not dump cookie values.
- `--browser-attach-running` instead uses the live Helium process without copying cookies, but requires an accessible CDP endpoint (default `127.0.0.1:9222`). Do not combine it with `--browser-cookie-sync`, `--browser-cookie-path`, or `--browser-manual-login`.

References: https://askoracle.sh/chromium-forks.html and https://askoracle.sh/browser-mode.html.
