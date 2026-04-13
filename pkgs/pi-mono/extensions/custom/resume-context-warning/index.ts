import type { ExtensionContext, ExtensionFactory } from "@mariozechner/pi-coding-agent";

import {
  DEFAULT_CONTEXT_PERCENT_THRESHOLD,
  EXTENSION_ID,
  getDefaultSessionPrefs,
  getIdleWindowKey,
  getProviderCacheTtlMs,
  isLargeContext,
  shouldWarn,
  type SessionPrefs,
  type WarningSnapshot,
} from "./warning-policy.ts";

const PREFS_TYPE = `${EXTENSION_ID}:prefs`;

const PREFILL_CHOICE = "/compact";
const CLEAR_CHOICE = "/clear";
const CONTINUE_CHOICE = "Continue as-is";

function parseTimestamp(timestamp: string): number | null {
  const value = Date.parse(timestamp);

  if (Number.isNaN(value)) {
    return null;
  }

  return value;
}

function isCompactCommand(text: string): boolean {
  return text.trim().startsWith("/compact");
}

function formatDuration(ms: number): string {
  if (ms < 60_000) {
    return `${Math.max(1, Math.round(ms / 1_000))}s`;
  }

  if (ms < 3_600_000) {
    return `${Math.round(ms / 60_000)}m`;
  }

  return `${(ms / 3_600_000).toFixed(1).replace(/\.0$/, "")}h`;
}

function formatTokenCount(tokens: number | null): string {
  if (tokens === null) {
    return "unknown";
  }

  if (tokens < 1_000) {
    return `${tokens}`;
  }

  return `${(tokens / 1_000).toFixed(1).replace(/\.0$/, "")}k`;
}

function formatPercent(percent: number | null): string {
  if (percent === null) {
    return "unknown";
  }

  return `${Math.round(percent * 100)}%`;
}

function getLatestActivityMs(ctx: ExtensionContext): number | null {
  const entries = ctx.sessionManager.getEntries();

  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];

    if (entry.type === "custom" && "customType" in entry && entry.customType === PREFS_TYPE) {
      continue;
    }

    const parsed = parseTimestamp(entry.timestamp);
    if (parsed !== null) {
      return parsed;
    }
  }

  return null;
}

function loadSessionPrefs(ctx: ExtensionContext): SessionPrefs {
  let prefs = getDefaultSessionPrefs();

  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type !== "custom") {
      continue;
    }

    if (!("customType" in entry) || entry.customType !== PREFS_TYPE) {
      continue;
    }

    if (!("data" in entry) || !entry.data || typeof entry.data !== "object") {
      continue;
    }

    const data = entry.data as Partial<SessionPrefs>;

    prefs = {
      suppressed: data.suppressed === true,
      lastAcknowledgedWindowKey:
        typeof data.lastAcknowledgedWindowKey === "string" ? data.lastAcknowledgedWindowKey : null,
    };
  }

  return prefs;
}

function saveSessionPrefs(
  pi: Parameters<ExtensionFactory>[0],
  prefs: SessionPrefs,
): void {
  pi.appendEntry(PREFS_TYPE, prefs);
}

function buildSnapshot(
  ctx: ExtensionContext,
  reason: WarningSnapshot["reason"],
): WarningSnapshot | null {
  const latestActivityMs = getLatestActivityMs(ctx);
  if (latestActivityMs === null) {
    return null;
  }

  const usage = ctx.getContextUsage();
  if (!usage || usage.percent === null) {
    return null;
  }

  const providerId = typeof ctx.model?.provider === "string" ? ctx.model.provider : null;
  const modelId = typeof ctx.model?.id === "string" ? ctx.model.id : null;
  const ttlMs = getProviderCacheTtlMs(providerId);
  const now = Date.now();
  const idleMs = Math.max(0, now - latestActivityMs);

  return {
    now,
    providerId,
    modelId,
    lastActivityMs: latestActivityMs,
    idleMs,
    ttlMs,
    cacheLikelyCold: idleMs >= ttlMs,
    contextTokens: usage.tokens,
    contextWindow: usage.contextWindow,
    contextPercent: usage.percent,
    isLargeContext: isLargeContext(usage.percent, DEFAULT_CONTEXT_PERCENT_THRESHOLD),
    reason,
  };
}

function prefillCompact(ctx: ExtensionContext): void {
  ctx.ui.setEditorText("/compact");
  ctx.ui.notify("Prefilled /compact. Press Enter to compact before continuing.", "info");
}

function prefillClear(ctx: ExtensionContext): void {
  ctx.ui.setEditorText("/clear");
  ctx.ui.notify("Prefilled /clear. Press Enter to clear the conversation.", "info");
}

async function chooseAction(
  ctx: ExtensionContext,
  snapshot: WarningSnapshot,
): Promise<"prefill" | "clear" | "continue"> {
  const intro =
    snapshot.reason === "resume"
      ? "This resumed session is likely expensive to continue."
      : "This session has been idle long enough that the next turn is likely expensive.";

  ctx.ui.notify(
    `${intro} Idle ${formatDuration(snapshot.idleMs)}; context ${formatTokenCount(snapshot.contextTokens)} / ${formatTokenCount(snapshot.contextWindow)} tokens (${formatPercent(snapshot.contextPercent)}). Prompt cache is likely cold.`,
    "warning",
  );

  const choice = await ctx.ui.select("Prompt cache is likely cold. What do you want to do?", [
    PREFILL_CHOICE,
    CLEAR_CHOICE,
    CONTINUE_CHOICE,
  ]);

  if (choice === PREFILL_CHOICE) {
    return "prefill";
  }

  if (choice === CLEAR_CHOICE) {
    return "clear";
  }

  return "continue";
}

const resumeContextWarning: ExtensionFactory = (pi) => {
  const pendingPromptsBySession = new WeakMap<object, string>();

  const getPendingPrompt = (ctx: ExtensionContext): string | null => {
    return pendingPromptsBySession.get(ctx.sessionManager) ?? null;
  };

  const setPendingPrompt = (ctx: ExtensionContext, prompt: string | null): void => {
    if (prompt === null) {
      pendingPromptsBySession.delete(ctx.sessionManager);
      return;
    }

    pendingPromptsBySession.set(ctx.sessionManager, prompt);
  };

  const warnIfNeeded = async (
    ctx: ExtensionContext,
    reason: WarningSnapshot["reason"],
    pendingPrompt: string | null,
  ): Promise<"continue" | "handled"> => {
    if (!ctx.hasUI) {
      return "continue";
    }

    const prefs = loadSessionPrefs(ctx);
    const snapshot = buildSnapshot(ctx, reason);

    if (!snapshot || !shouldWarn(snapshot, prefs)) {
      return "continue";
    }

    const action = await chooseAction(ctx, snapshot);
    const nextPrefs: SessionPrefs = {
      suppressed: prefs.suppressed,
      lastAcknowledgedWindowKey: getIdleWindowKey(snapshot),
    };

    saveSessionPrefs(pi, nextPrefs);

    if (action === "continue") {
      return "continue";
    }

    if (action === "clear") {
      prefillClear(ctx);
      return "handled";
    }

    setPendingPrompt(ctx, pendingPrompt);
    prefillCompact(ctx);

    if (pendingPrompt) {
      ctx.ui.notify(
        "Your last prompt was not sent. After compaction finishes, the extension will restore it into the editor.",
        "info",
      );
    }

    return "handled";
  };

  pi.on("session_start", async (event, ctx) => {
    setPendingPrompt(ctx, null);

    if (event.reason !== "resume") {
      return;
    }

    await warnIfNeeded(ctx, "resume", null);
  });

  // input fires before agent processing. Intercept if session has been idle too long.
  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") {
      return { action: "continue" as const };
    }

    if (getPendingPrompt(ctx) !== null) {
      if (!isCompactCommand(event.text)) {
        setPendingPrompt(ctx, null);
      }

      return { action: "continue" as const };
    }

    const result = await warnIfNeeded(ctx, "input", event.text);
    if (result === "handled") {
      return { action: "handled" as const };
    }

    return { action: "continue" as const };
  });

  // session_compact fires after compaction completes. Restore the held prompt.
  pi.on("session_compact", async (_event, ctx) => {
    const prompt = getPendingPrompt(ctx);
    if (!prompt) {
      return;
    }

    setPendingPrompt(ctx, null);
    ctx.ui.setEditorText(prompt);
    ctx.ui.notify("Compaction complete. Restored your pending prompt into the editor.", "info");
  });
};

export default resumeContextWarning;
