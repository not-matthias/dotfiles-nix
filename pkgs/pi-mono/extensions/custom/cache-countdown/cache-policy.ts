export const EXTENSION_ID = "cache-countdown";

// Anthropic: 5 min TTL, resets on each cache hit
// OpenAI:    5-10 min inactivity window (using upper bound)
export const DEFAULT_TTL_BY_PROVIDER_MS: Record<string, number> = {
  anthropic: 5 * 60_000,
  openai: 10 * 60_000,
  "openai-codex": 10 * 60_000,
  default: 5 * 60_000,
};

export function getProviderCacheTtlMs(
  providerId: string | null,
  overrides: Record<string, number> = DEFAULT_TTL_BY_PROVIDER_MS,
): number {
  if (providerId && overrides[providerId] !== undefined) {
    return overrides[providerId];
  }

  return overrides.default ?? 5 * 60_000;
}

export function formatCountdown(remainingMs: number): string {
  if (remainingMs <= 0) {
    return "expired";
  }

  const totalSeconds = Math.ceil(remainingMs / 1_000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
}
