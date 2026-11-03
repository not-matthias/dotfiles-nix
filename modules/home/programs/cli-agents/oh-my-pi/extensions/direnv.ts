/**
 * pi-direnv Extension
 *
 * Automatically loads direnv environment variables at session start and switch.
 * Ensures bash commands have access to project-specific env vars
 * defined in .envrc files (commonly used with Nix flakes).
 *
 * Behavior:
 * - Searches for .envrc from the session cwd up to its git root
 * - Runs `direnv export json` and applies vars to process.env
 * - Shows notification if .envrc is blocked or env loaded
 * - Silently skips if direnv missing or no .envrc exists
 *
 * Vendored from https://github.com/edmundmiller/dotfiles/tree/main/packages/pi-packages/pi-direnv (MIT).
 * Inspired by https://github.com/simonwjackson/opencode-direnv
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 Edmund Miller
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  SessionStartEvent,
  SessionSwitchEvent,
} from "@oh-my-pi/pi-coding-agent";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

export default function (pi: ExtensionAPI) {
  async function loadDirenv(_event: SessionStartEvent | SessionSwitchEvent, ctx: ExtensionContext) {
    const cwd = ctx.sessionManager.getCwd();

    const hasDirenvCmd = await pi.exec("which", ["direnv"]);
    if (hasDirenvCmd.code !== 0) return;

    const gitRoot = await findGitRoot(pi, cwd);
    const envrcPath = findEnvrc(cwd, gitRoot);
    if (!envrcPath) return;

    const envrcDir = dirname(envrcPath);

    try {
      const result = await pi.exec("direnv", ["export", "json"], { cwd: envrcDir });
      if (result.stderr?.includes("is blocked")) {
        ctx.ui.notify("direnv: .envrc is blocked. Run `direnv allow` to enable.", "warning");
        return;
      }
      if (result.code !== 0) return;
      const output = result.stdout?.trim();
      if (!output) return;

      // direnv uses null for variables it unsets
      const envVars = JSON.parse(output) as Record<string, string | null>;
      for (const [key, value] of Object.entries(envVars)) {
        if (value === null) delete process.env[key];
        else process.env[key] = value;
      }

      ctx.ui.notify(`direnv: loaded ${Object.keys(envVars).length} env vars`, "info");
    } catch {
      // direnv failures (parse errors, etc.) are non-fatal
    }
  }

  pi.on("session_start", loadDirenv);
  pi.on("session_switch", loadDirenv);
}

async function findGitRoot(pi: ExtensionAPI, cwd: string): Promise<string | null> {
  try {
    const result = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd });
    return result.stdout?.trim() || null;
  } catch {
    return null;
  }
}

function findEnvrc(startDir: string, stopAt: string | null): string | null {
  const boundary = stopAt || "/";
  let current = startDir;

  while (true) {
    const envrcPath = join(current, ".envrc");
    if (existsSync(envrcPath)) return envrcPath;

    if (current === boundary || current === "/") break;

    const parent = dirname(current);
    if (parent === current) break; // filesystem root
    current = parent;
  }

  return null;
}
