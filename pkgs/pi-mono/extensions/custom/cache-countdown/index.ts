import type { ExtensionContext, ExtensionFactory } from "@mariozechner/pi-coding-agent";

import { EXTENSION_ID, formatCountdown, getProviderCacheTtlMs } from "./cache-policy.ts";

const LEGACY_STATUS_ID = EXTENSION_ID;
const STATUS_ID = `zz-${EXTENSION_ID}`;

function parseTimestamp(timestamp: string): number | null {
  const value = Date.parse(timestamp);
  return Number.isNaN(value) ? null : value;
}

function getLastActivityMs(ctx: ExtensionContext): number | null {
  const entries = ctx.sessionManager.getBranch();

  for (let i = entries.length - 1; i >= 0; i -= 1) {
    const entry = entries[i];
    if (entry.type !== "message") {
      continue;
    }

    if (entry.message.role !== "assistant") {
      continue;
    }

    const parsed = parseTimestamp(entry.timestamp);
    if (parsed !== null) {
      return parsed;
    }
  }

  return null;
}

const cacheCountdown: ExtensionFactory = (pi) => {
  let lastActivityMs: number | null = null;
  let ttlMs = 5 * 60_000;
  let intervalId: ReturnType<typeof setInterval> | null = null;
  let latestCtx: ExtensionContext | null = null;

  function setStatus(text: string | undefined): void {
    if (!latestCtx?.hasUI) {
      return;
    }

    latestCtx.ui.setStatus(LEGACY_STATUS_ID, undefined);
    latestCtx.ui.setStatus(STATUS_ID, text);
  }

  function getStatusText(remainingMs: number): string {
    const text = `Cache: ${formatCountdown(remainingMs)}`;

    if (!latestCtx?.hasUI) {
      return text;
    }

    return latestCtx.ui.theme.fg("dim", text);
  }

  function updateStatus(): void {
    if (!latestCtx?.hasUI) {
      return;
    }

    if (lastActivityMs === null) {
      setStatus(undefined);
      return;
    }

    const remainingMs = Math.max(0, ttlMs - (Date.now() - lastActivityMs));
    setStatus(getStatusText(remainingMs));

    if (remainingMs <= 0) {
      stopInterval();
    }
  }

  function startInterval(): void {
    if (intervalId !== null) {
      return;
    }

    intervalId = setInterval(updateStatus, 1_000);
  }

  function stopInterval(): void {
    if (intervalId === null) {
      return;
    }

    clearInterval(intervalId);
    intervalId = null;
  }

  function resolveProvider(ctx: ExtensionContext): string | null {
    return typeof ctx.model?.provider === "string" ? ctx.model.provider : null;
  }

  function isWaitingForUserInput(ctx: ExtensionContext): boolean {
    return ctx.isIdle() && !ctx.hasPendingMessages();
  }

  function pauseCountdown(ctx: ExtensionContext): void {
    latestCtx = ctx;
    stopInterval();
    setStatus(undefined);
  }

  function startCountdown(ctx: ExtensionContext): void {
    latestCtx = ctx;

    if (!isWaitingForUserInput(ctx) || lastActivityMs === null) {
      pauseCountdown(ctx);
      return;
    }

    startInterval();
    updateStatus();
  }

  function refreshCacheTimer(ctx: ExtensionContext): void {
    ttlMs = getProviderCacheTtlMs(resolveProvider(ctx));
    lastActivityMs = Date.now();
    startCountdown(ctx);
  }

  pi.on("session_start", async (event, ctx) => {
    latestCtx = ctx;
    ttlMs = getProviderCacheTtlMs(resolveProvider(ctx));
    lastActivityMs = null;
    pauseCountdown(ctx);

    // On resume, pick up where we left off based on session history
    if (event.reason !== "resume") {
      return;
    }

    const lastActivity = getLastActivityMs(ctx);
    if (lastActivity === null) {
      return;
    }

    lastActivityMs = lastActivity;
    startCountdown(ctx);
  });

  pi.on("agent_start", async (_event, ctx) => {
    pauseCountdown(ctx);
  });

  // agent_end = agent just finished responding, cache was refreshed
  pi.on("agent_end", async (_event, ctx) => {
    refreshCacheTimer(ctx);
  });
};

export default cacheCountdown;
