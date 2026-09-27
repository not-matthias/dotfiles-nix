---
name: oracle-cli
description: Use for Oracle CLI second-model reviews, prompt/file bundling, browser login or Helium cookie sync, and session recovery.
---

# Oracle CLI

Oracle CLI bundles a prompt and selected project files for a second-model review. Treat responses as advice and verify them against the project; never attach secrets, cookie databases, private keys, or `.env` files.

## Consult workflow

1. Give the model a project briefing, exact question, prior attempts, constraints, and desired output. Select the smallest files that contain the answer.
2. Preview the bundle without calling a model:

   ```sh
   oracle --dry-run summary --files-report -p 'Review this change for risks' --file 'src/**' --file '!**/*.test.*'
   ```

3. For an actual ChatGPT browser run, pin the model and engine so `OPENAI_API_KEY` cannot silently select paid API mode:

   ```sh
   oracle --engine browser --model gpt-5.6-sol --timeout 180 \
     -p 'Review this change for risks' --file 'src/**'
   ```

   API mode may incur charges; use it only when explicitly intended. The browser requires a signed-in Chrome/Chromium session; choose a dedicated `--browser-manual-login` profile, the Helium wrapper below, or a running browser with `--browser-attach-running` and CDP enabled.

4. Recover detached or timed-out sessions instead of resubmitting:

   ```sh
   oracle status --hours 72
   oracle session <id> --render
   ```

   For manual paste without a model call, use `oracle --render-markdown --copy-markdown -p '...' --file path/to/file`.

## Cookie-sync path

The bundled [`scripts/oracle-helium`](scripts/oracle-helium) wrapper selects the Helium executable and cookie database, then tries the Chromium safe-storage key from `secret-tool` for the Oracle process. It passes other Oracle arguments through unchanged; its distinct command name does not shadow the installed `oracle` CLI.

1. Choose the smallest nonsecret file set and preview before every model run (from the repository root):

   ```sh
   modules/home/programs/cli-agents/shared/skills/cli-tools/oracle-cli/scripts/oracle-helium \
     --dry-run summary --files-report --model gpt-5.6-sol \
     -p 'Your specific question' --file README.md
   ```

2. Run from a desktop shell with access to its Wayland display:

   ```sh
   nix-shell -p libsecret --run \
     'modules/home/programs/cli-agents/shared/skills/cli-tools/oracle-cli/scripts/oracle-helium --model gpt-5.6-sol --timeout 180 -p "Your specific question" --file README.md'
   ```

The database's ChatGPT cookies are `v11` encrypted, and this machine has a Chromium keyring entry. Oracle's `sweet-cookie` treats an unrecognized Helium database path as Chrome, so it looks for the wrong safe-storage key. The wrapper tries the Chromium key as a temporary process-local override; decryption and a model response remain unverified. Never print the key or enable shell tracing. Adapt the executable, profile path, and keyring identity if a different installation requires it. Cookie copying may rotate auth tokens and log out the original Helium session. The alternative `--browser-manual-login` uses Oracle's separate persistent profile and requires its own sign-in.

## Diagnosis and alternatives

- Launcher mode `ECONNREFUSED 127.0.0.1:9222` may mean the newly launched browser exited. Here the agent shell had no `WAYLAND_DISPLAY`, although `/run/user/1000/wayland-1` existed. An isolated headful launch succeeded after setting `WAYLAND_DISPLAY=wayland-1 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus`. Check the current session's sockets before setting these variables; changing `--browser-port` does not supply a display.
- `No ChatGPT cookies were applied` despite a session-token cookie in the database: check `secret-tool` availability and the keyring identity. Do not dump cookie values.
- With the keyring override, headless mode reached a Cloudflare challenge. Headful mode launched but failed at the ChatGPT model selector; `--browser-model-strategy current` then timed out without confirming prompt submission. **No response was verified.** Do not represent these runs as a successful consultation or blindly resubmit the prompt.
- For ambiguous submission, inspect `oracle session <id> --render` or `--harvest` before any new run. The observed harvest reported no confirmed user turn. `oracle status --hours 72` lists sessions.
- `--browser-attach-running` instead uses the live Helium process without copying cookies, but requires an accessible CDP endpoint (default `127.0.0.1:9222`). Do not combine it with `--browser-cookie-sync`, `--browser-cookie-path`, or `--browser-manual-login`.

References: https://askoracle.sh/chromium-forks.html and https://askoracle.sh/browser-mode.html.
