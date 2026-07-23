#!/usr/bin/env bun

// Set the outer terminal title to the focused tab's switch position and name.
// The switch position is the 1-based index within the workspace (matches
// `prefix+1..9`), derived from `tab list` order — not the tab's internal
// `number`, which is a large system id that is meaningless for navigation.

import { spawnSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname as pathDirname, join } from "node:path";

const herdr = process.env.HERDR_BIN_PATH || "herdr";
const stateDir = process.env.HERDR_PLUGIN_STATE_DIR || "/tmp";
const statePath = join(stateDir, "last-title");

function run(args) {
  const result = spawnSync(herdr, args, {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    throw new Error(
      `${herdr} ${args.join(" ")} failed: ${result.stderr || result.stdout}`,
    );
  }
  return result.stdout.trim();
}

function json(args) {
  const output = run(args);
  return output ? JSON.parse(output) : null;
}

function cleanPart(value) {
  return String(value ?? "")
    .replace(/[\x00-\x1f\x7f]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function buildTitle() {
  const pane = json(["pane", "current"])?.result?.pane;
  if (!pane) return "herdr";

  const { workspace_id: workspaceId, tab_id: tabId } = pane;
  if (!workspaceId || !tabId) return "herdr";

  const tabs =
    json(["tab", "list", "--workspace", workspaceId])?.result?.tabs ?? [];
  const index = tabs.findIndex((tab) => tab.tab_id === tabId);
  if (index < 0) return "herdr";

  const order = index + 1;
  // Default tab labels mirror the internal number; drop those so only real,
  // human-given names are shown next to the index.
  const label = cleanPart(tabs[index].label);
  const name = label && !/^\d+$/.test(label) ? label : "";

  return name ? `[${order}] ${name}` : `[${order}]`;
}

function lastTitle() {
  try {
    return readFileSync(statePath, "utf8").trim();
  } catch {
    return "";
  }
}

function saveTitle(title) {
  mkdirSync(pathDirname(statePath), { recursive: true });
  writeFileSync(statePath, `${title}\n`);
}

try {
  const title = buildTitle();
  const isStartup = process.env.HERDR_PLUGIN_EVENT === "startup";
  // Skip the IPC call when nothing changed; startup always re-applies so the
  // title recovers after a server restart even if the pane is unchanged.
  if (isStartup || title !== lastTitle()) {
    run(["terminal", "title", "set", title]);
    saveTitle(title);
  }
  console.log(title);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
