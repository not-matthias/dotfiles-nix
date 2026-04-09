export const EXTENSION_ID = "resume-context-warning";
export const DEFAULT_CONTEXT_PERCENT_THRESHOLD = 0.5;
export const DEFAULT_TTL_BY_PROVIDER_MS: Record<string, number> = {
  anthropic: 5 * 60_000,
  openai: 10 * 60_000,
  "openai-codex": 10 * 60_000,
  default: 5 * 60_000,
};

export interface SessionPrefs {
  suppressed: boolean;
  lastAcknowledgedWindowKey: string | null;
}

export interface WarningSnapshot {
  now: number;
  providerId: string | null;
  modelId: string | null;
  lastActivityMs: number;
  idleMs: number;
  ttlMs: number;
  cacheLikelyCold: boolean;
  contextTokens: number | null;
  contextWindow: number | null;
  contextPercent: number | null;
  isLargeContext: boolean;
  reason: "resume" | "input";
}

export function getProviderCacheTtlMs(
  providerId: string | null,
  overrides: Record<string, number> = DEFAULT_TTL_BY_PROVIDER_MS,
): number {
  if (providerId && overrides[providerId] !== undefined) {
    return overrides[providerId];
  }

  return overrides.default ?? 5 * 60_000;
}

export function getIdleWindowKey(
  snapshot: Pick<WarningSnapshot, "providerId" | "lastActivityMs" | "ttlMs">,
): string {
  return `${snapshot.providerId ?? "unknown"}:${snapshot.lastActivityMs}:${snapshot.ttlMs}`;
}

export function isLargeContext(
  contextPercent: number | null,
  minPercent: number = DEFAULT_CONTEXT_PERCENT_THRESHOLD,
): boolean {
  if (contextPercent === null) {
    return false;
  }

  return contextPercent >= minPercent;
}

export function shouldWarn(snapshot: WarningSnapshot, prefs: SessionPrefs): boolean {
  if (prefs.suppressed) {
    return false;
  }

  if (!snapshot.cacheLikelyCold) {
    return false;
  }

  if (!snapshot.isLargeContext) {
    return false;
  }

  return prefs.lastAcknowledgedWindowKey !== getIdleWindowKey(snapshot);
}

export function getDefaultSessionPrefs(): SessionPrefs {
  return {
    suppressed: false,
    lastAcknowledgedWindowKey: null,
  };
}
