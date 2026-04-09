import test from "node:test";
import assert from "node:assert/strict";

import {
  getDefaultSessionPrefs,
  getIdleWindowKey,
  getProviderCacheTtlMs,
  isLargeContext,
  shouldWarn,
  type WarningSnapshot,
} from "./warning-policy.ts";

function makeSnapshot(overrides: Partial<WarningSnapshot> = {}): WarningSnapshot {
  return {
    now: 1_710_000_000_000,
    providerId: "anthropic",
    modelId: "claude-sonnet-4-5",
    lastActivityMs: 1_709_999_400_000,
    idleMs: 600_000,
    ttlMs: 300_000,
    cacheLikelyCold: true,
    contextTokens: 92_000,
    contextWindow: 200_000,
    contextPercent: 0.5,
    isLargeContext: true,
    reason: "resume",
    ...overrides,
  };
}

test("getProviderCacheTtlMs uses provider-specific defaults", () => {
  assert.equal(getProviderCacheTtlMs("anthropic"), 300_000);
  assert.equal(getProviderCacheTtlMs("openai"), 600_000);
  assert.equal(getProviderCacheTtlMs("openai-codex"), 600_000);
  assert.equal(getProviderCacheTtlMs("unknown-provider"), 300_000);
  assert.equal(getProviderCacheTtlMs(null), 300_000);
});

test("isLargeContext only warns when percent is at or above threshold", () => {
  assert.equal(isLargeContext(null), false);
  assert.equal(isLargeContext(0.49), false);
  assert.equal(isLargeContext(0.5), true);
  assert.equal(isLargeContext(0.9), true);
});

test("isLargeContext respects custom minPercent threshold", () => {
  assert.equal(isLargeContext(0.3, 0.5), false);
  assert.equal(isLargeContext(0.3, 0.25), true);
  assert.equal(isLargeContext(0.6, 0.5), true);
});

test("getDefaultSessionPrefs returns initial preferences", () => {
  const prefs = getDefaultSessionPrefs();

  assert.equal(prefs.suppressed, false);
  assert.equal(prefs.lastAcknowledgedWindowKey, null);
});

test("getIdleWindowKey ignores trigger source so resume and input share one acknowledgement window", () => {
  const fromResume = getIdleWindowKey(makeSnapshot({ reason: "resume" }));
  const fromInput = getIdleWindowKey(makeSnapshot({ reason: "input" }));

  assert.equal(fromResume, fromInput);
});

test("shouldWarn returns true only for large, cold, unsuppressed sessions", () => {
  const prefs = getDefaultSessionPrefs();

  assert.equal(shouldWarn(makeSnapshot(), prefs), true);
  assert.equal(shouldWarn(makeSnapshot({ cacheLikelyCold: false }), prefs), false);
  assert.equal(shouldWarn(makeSnapshot({ isLargeContext: false }), prefs), false);
  assert.equal(shouldWarn(makeSnapshot(), { ...prefs, suppressed: true }), false);
});

test("shouldWarn skips already-acknowledged idle windows", () => {
  const snapshot = makeSnapshot();
  const prefs = {
    suppressed: false,
    lastAcknowledgedWindowKey: getIdleWindowKey(snapshot),
  };

  assert.equal(shouldWarn(snapshot, prefs), false);
});
