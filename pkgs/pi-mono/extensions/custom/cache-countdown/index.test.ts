import test from "node:test";
import assert from "node:assert/strict";

import cacheCountdown from "./index.ts";
import { EXTENSION_ID } from "./cache-policy.ts";

type Handler = (event: any, ctx: any) => Promise<any> | any;

function createHarness() {
  const handlers = new Map<string, Handler[]>();

  const pi = {
    on(event: string, handler: Handler) {
      const existing = handlers.get(event) ?? [];
      existing.push(handler);
      handlers.set(event, existing);
    },
  };

  cacheCountdown(pi as any);

  return {
    async emit(eventName: string, event: any, ctx: any) {
      const registered = handlers.get(eventName) ?? [];
      let result: any;

      for (const handler of registered) {
        result = await handler(event, ctx);
      }

      return result;
    },
  };
}

function iso(ms: number): string {
  return new Date(ms).toISOString();
}

function createContext({
  provider = "anthropic",
  entries = [],
  branchEntries = entries,
}: {
  provider?: string | null;
  entries?: any[];
  branchEntries?: any[];
} = {}) {
  const statusUpdates: Array<{ key: string; text: string | undefined }> = [];

  const ctx = {
    hasUI: true,
    ui: {
      setStatus(key: string, text: string | undefined) {
        statusUpdates.push({ key, text });
      },
      theme: {
        fg(color: string, text: string) {
          return `<${color}>${text}</${color}>`;
        },
      },
    },
    model: provider === null ? undefined : { provider },
    sessionManager: {
      getEntries() {
        return entries;
      },
      getBranch() {
        return branchEntries;
      },
    },
    hasPendingMessages() {
      return false;
    },
    isIdle() {
      return true;
    },
  };

  return { ctx: ctx as any, statusUpdates };
}

test("countdown only runs while waiting for user input", async () => {
  const harness = createHarness();
  const { ctx } = createContext();

  const originalSetInterval = globalThis.setInterval;
  const originalClearInterval = globalThis.clearInterval;

  let nextIntervalId = 0;
  const clearedIds: number[] = [];

  try {
    (globalThis as any).setInterval = () => {
      nextIntervalId += 1;
      return nextIntervalId;
    };

    (globalThis as any).clearInterval = (id: number) => {
      clearedIds.push(id);
    };

    await harness.emit("session_start", { reason: "new" }, ctx);
    assert.equal(nextIntervalId, 0);

    await harness.emit("input", { source: "interactive", text: "hello" }, ctx);
    assert.equal(nextIntervalId, 0);

    await harness.emit("agent_end", { messages: [] }, ctx);
    assert.equal(nextIntervalId, 1);

    await harness.emit("agent_start", {}, ctx);
    assert.deepEqual(clearedIds, [1]);
  } finally {
    globalThis.setInterval = originalSetInterval;
    globalThis.clearInterval = originalClearInterval;
  }
});

test("starting a new session clears stale countdown state", async () => {
  const harness = createHarness();
  const { ctx, statusUpdates } = createContext();

  const originalSetInterval = globalThis.setInterval;
  const originalClearInterval = globalThis.clearInterval;

  let nextIntervalId = 0;
  const clearedIds: number[] = [];

  try {
    (globalThis as any).setInterval = () => {
      nextIntervalId += 1;
      return nextIntervalId;
    };

    (globalThis as any).clearInterval = (id: number) => {
      clearedIds.push(id);
    };

    await harness.emit("agent_end", { messages: [] }, ctx);
    assert.equal(nextIntervalId, 1);

    await harness.emit("session_start", { reason: "new" }, ctx);

    assert.deepEqual(clearedIds, [1]);
    assert.equal(
      statusUpdates.some((update) => update.key === EXTENSION_ID && update.text === undefined),
      true,
    );
  } finally {
    globalThis.setInterval = originalSetInterval;
    globalThis.clearInterval = originalClearInterval;
  }
});

test("resume countdown is based on assistant activity in the active branch", async () => {
  const harness = createHarness();

  const now = 1_000_000;

  const branchEntries = [
    {
      type: "message",
      timestamp: iso(now - 280_000),
      message: { role: "assistant" },
    },
    {
      type: "custom",
      timestamp: iso(now - 5_000),
      customType: "other-ext",
    },
  ];

  const entries = [
    ...branchEntries,
    {
      type: "message",
      timestamp: iso(now - 10_000),
      message: { role: "assistant" },
    },
  ];

  const { ctx, statusUpdates } = createContext({ entries, branchEntries });

  const originalSetInterval = globalThis.setInterval;
  const originalClearInterval = globalThis.clearInterval;
  const originalDateNow = Date.now;

  try {
    (globalThis as any).setInterval = () => 1;
    (globalThis as any).clearInterval = () => {};
    Date.now = () => now;

    await harness.emit("session_start", { reason: "resume" }, ctx);

    assert.equal(statusUpdates.at(-1)?.text, "<dim>Cache: 0:20</dim>");
  } finally {
    globalThis.setInterval = originalSetInterval;
    globalThis.clearInterval = originalClearInterval;
    Date.now = originalDateNow;
  }
});
