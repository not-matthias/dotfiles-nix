#!/usr/bin/env bun

// Aggregate herdr agent state into an ActivityWatch bucket once per minute.
// User overrides live in ~/.config/herdr/plugins/config/local.herdr-api/config.env

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import os from "node:os";
import { join } from "node:path";

const herdr = process.env.HERDR_BIN_PATH || "herdr";
const configDir = process.env.HERDR_PLUGIN_CONFIG_DIR;

const fileConfig = {};
if (configDir) {
  const configPath = join(configDir, "config.env");
  if (existsSync(configPath)) {
    try {
      const content = readFileSync(configPath, "utf8");
      for (const rawLine of content.split("\n")) {
        const line = rawLine.trim();
        if (!line || line.startsWith("#")) continue;
        const eq = line.indexOf("=");
        if (eq === -1) continue;
        const key = line.slice(0, eq).trim();
        const val = line.slice(eq + 1).trim();
        if (key) fileConfig[key] = val;
      }
    } catch (err) {
      console.error(`Failed to read config file ${configPath}:`, err);
    }
  }
}

function parsePositiveInt(val, fallback, min) {
  if (val === undefined || val === null || val === "") return fallback;
  const parsed = parseInt(String(val), 10);
  if (Number.isNaN(parsed) || parsed < min) return fallback;
  return parsed;
}

const AW_HOST =
  process.env.AW_HOST || fileConfig.AW_HOST || "http://127.0.0.1:5600";
const AW_HOSTNAME =
  process.env.AW_HOSTNAME || fileConfig.AW_HOSTNAME || os.hostname();
const AW_BUCKET_PREFIX =
  process.env.AW_BUCKET_PREFIX ||
  fileConfig.AW_BUCKET_PREFIX ||
  "aw-watcher-herdr";
const AW_POLL_SECONDS = parsePositiveInt(
  process.env.AW_POLL_SECONDS ?? fileConfig.AW_POLL_SECONDS,
  60,
  5,
);
const AW_PULSETIME = parsePositiveInt(
  process.env.AW_PULSETIME ?? fileConfig.AW_PULSETIME,
  120,
  10,
);

const bucketId = `${AW_BUCKET_PREFIX}_${AW_HOSTNAME}`;

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

async function awFetch(path, opts = {}) {
  const url = `${AW_HOST}/api/0${path}`;
  const res = await fetch(url, {
    signal: AbortSignal.timeout(5000),
    ...opts,
  });
  if (!res.ok && res.status !== 404) {
    const body = await res.text().catch(() => "");
    throw new Error(`AW HTTP ${res.status} on ${path}: ${body.slice(0, 200)}`);
  }
  return res;
}

async function ensureBucket() {
  const res = await awFetch(`/buckets/${bucketId}`);
  if (res.status === 404) {
    const createRes = await fetch(`${AW_HOST}/api/0/buckets/${bucketId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client: "herdr-plugin",
        type: "app.agent.activity",
        hostname: AW_HOSTNAME,
      }),
      signal: AbortSignal.timeout(5000),
    });
    if (!createRes.ok) {
      const body = await createRes.text().catch(() => "");
      throw new Error(
        `Failed to create bucket ${bucketId}: ${createRes.status} ${body.slice(0, 200)}`,
      );
    }
    console.log(`Created bucket ${bucketId}`);
  }
}

function collectSnapshot() {
  const pane = json(["pane", "current"])?.result?.pane;
  const agents = json(["agent", "list"])?.result?.agents ?? [];
  const workspaces = json(["workspace", "list"])?.result?.workspaces ?? [];
  const tabs = pane?.workspace_id
    ? json(["tab", "list", "--workspace", pane.workspace_id])?.result?.tabs ??
      []
    : [];

  const ws = workspaces.find((w) => w.workspace_id === pane?.workspace_id);
  const workspace_label = ws?.label || pane?.workspace_id || "none";

  const tabIndex = pane?.tab_id
    ? tabs.findIndex((t) => t.tab_id === pane.tab_id)
    : -1;
  let tab_label = "none";
  if (tabIndex >= 0) {
    const raw = cleanPart(tabs[tabIndex].label);
    tab_label = raw && !/^\d+$/.test(raw) ? raw : pane?.tab_id || "none";
  } else if (pane?.tab_id) {
    tab_label = pane.tab_id;
  }
  const tab_index = tabIndex >= 0 ? tabIndex + 1 : 0;

  const focused_agent = pane?.agent || "none";
  const focused_agent_status = pane?.agent_status || "none";
  const focused_title = cleanPart(pane?.terminal_title_stripped) || "none";

  const agent_count = agents.length;
  const agents_by_kind = {};
  const agents_by_status = {};
  let working_panes = 0;

  for (const a of agents) {
    if (a.agent) {
      agents_by_kind[a.agent] = (agents_by_kind[a.agent] || 0) + 1;
    }
    if (a.agent_status) {
      agents_by_status[a.agent_status] =
        (agents_by_status[a.agent_status] || 0) + 1;
      if (a.agent_status === "working") {
        working_panes++;
      }
    }
  }

  const workspace_count = workspaces.length;

  return {
    timestamp: new Date().toISOString(),
    duration: 0,
    data: {
      workspace_label,
      tab_label,
      tab_index,
      focused_agent,
      focused_agent_status,
      focused_title,
      agent_count,
      agents_by_kind,
      agents_by_status,
      workspace_count,
      working_panes,
    },
  };
}

async function publish(event) {
  const res = await fetch(
    `${AW_HOST}/api/0/buckets/${bucketId}/heartbeat?pulsetime=${AW_PULSETIME}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(event),
      signal: AbortSignal.timeout(5000),
    },
  );
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Heartbeat failed ${res.status}: ${body.slice(0, 200)}`);
  }
  console.log(
    `published ws=${event.data.workspace_label} agents=${event.data.agent_count} working=${event.data.working_panes}`,
  );
}

async function main() {
  console.log(
    `Starting Herdr API plugin: bucket=${bucketId} host=${AW_HOST} poll=${AW_POLL_SECONDS}s pulsetime=${AW_PULSETIME}s`,
  );

  let needsBucketCheck = false;
  try {
    await ensureBucket();
  } catch (err) {
    console.error(
      "Initial bucket check failed:",
      err instanceof Error ? err.message : String(err),
    );
    needsBucketCheck = true;
  }

  async function tick() {
    try {
      if (needsBucketCheck) {
        await ensureBucket();
        needsBucketCheck = false;
      }
      const snapshot = collectSnapshot();
      await publish(snapshot);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error("Tick error:", msg);
      if (msg.includes("404") || msg.toLowerCase().includes("bucket")) {
        needsBucketCheck = true;
      }
    }
  }

  await tick();
  setInterval(tick, AW_POLL_SECONDS * 1000);

  process.on("SIGTERM", () => process.exit(0));
  process.on("SIGINT", () => process.exit(0));
}

main().catch((err) => {
  console.error("Fatal startup error:", err);
  process.exit(1);
});
