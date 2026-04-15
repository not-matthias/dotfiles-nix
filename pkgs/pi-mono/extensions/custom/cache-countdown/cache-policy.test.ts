import test from "node:test";
import assert from "node:assert/strict";

import { formatCountdown, getProviderCacheTtlMs } from "./cache-policy.ts";

test("getProviderCacheTtlMs returns provider-specific TTLs", () => {
  assert.equal(getProviderCacheTtlMs("anthropic"), 300_000);
  assert.equal(getProviderCacheTtlMs("openai"), 600_000);
  assert.equal(getProviderCacheTtlMs("openai-codex"), 600_000);
  assert.equal(getProviderCacheTtlMs("unknown-provider"), 300_000);
  assert.equal(getProviderCacheTtlMs(null), 300_000);
});

test("formatCountdown shows minutes:seconds when time remains", () => {
  assert.equal(formatCountdown(5 * 60_000), "5:00");
  assert.equal(formatCountdown(90_000), "1:30");
  assert.equal(formatCountdown(61_000), "1:01");
  assert.equal(formatCountdown(1_000), "0:01");
});

test("formatCountdown shows expired at zero or negative", () => {
  assert.equal(formatCountdown(0), "expired");
  assert.equal(formatCountdown(-1_000), "expired");
});

test("formatCountdown rounds sub-second remainders up", () => {
  assert.equal(formatCountdown(500), "0:01"); // 0.5s rounds up to 1s
  assert.equal(formatCountdown(60_500), "1:01"); // 60.5s rounds up to 61s
});
