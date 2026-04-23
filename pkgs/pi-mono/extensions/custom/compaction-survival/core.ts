// Vendored from:
// https://github.com/DonaldMurillo/my-pi/tree/main/extensions/compaction-survival
// Retrieved 2026-04-22.

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export type CompactionMode = "automatic" | "programmatic";

export type CompactionSnapshot = {
  mode: CompactionMode;
  latestAssistantText: string;
  assistantTail: string;
  latestUserText: string;
};

export type CompactionSurvivalConfig = {
  autoResumeOnAutomaticCompaction?: boolean;
  resumeDelayMs?: number;
  assistantTailChars?: number;
  userTaskAnchorChars?: number;
  buildResumePrompt?: (snapshot: CompactionSnapshot) => string;
};

type CompactionSurvivalController = {
  requestResume(prompt?: string): void;
  clearPendingResume(): void;
  getSnapshot(): CompactionSnapshot;
  getPendingPrompt(): string | null;
};

type CompactionSurvivalAPI = Pick<ExtensionAPI, "on" | "sendUserMessage">;

const DEFAULT_RESUME_DELAY_MS = 0;
const DEFAULT_ASSISTANT_TAIL_CHARS = 220;
const DEFAULT_USER_TASK_ANCHOR_CHARS = 320;

function trimPromptSnippet(text: string, maxChars: number): string {
  const value = text.replace(/\s+/g, " ").replace(/"/g, "'").trim();

  if (value.length <= maxChars) {
    return value;
  }

  return value.slice(-maxChars);
}

function extractMessageText(message: unknown): string {
  if (typeof message !== "object" || message === null) {
    return "";
  }

  const value = message as {
    content?: unknown;
    prompt?: unknown;
  };

  if (typeof value.prompt === "string" && value.prompt.trim().length > 0) {
    return value.prompt.trim();
  }

  if (typeof value.content === "string" && value.content.trim().length > 0) {
    return value.content.trim();
  }

  if (!Array.isArray(value.content)) {
    return "";
  }

  return value.content
    .filter((item): item is { type?: unknown; text?: unknown } => typeof item === "object" && item !== null)
    .filter((item) => item.type === "text" && typeof item.text === "string")
    .map((item) => item.text)
    .join("")
    .trim();
}

export function buildDefaultResumePrompt(snapshot: CompactionSnapshot): string {
  const base =
    "The session was compacted. Continue the in-progress answer without restarting, re-summarizing the compaction, or repeating completed sections.";
  const taskAnchor =
    snapshot.latestUserText.length > 0
      ? ` Keep serving this user request anchor: \"${snapshot.latestUserText}\".`
      : "";
  const tail =
    snapshot.assistantTail.length > 0
      ? ` Resume immediately after this trailing excerpt: \"${snapshot.assistantTail}\"`
      : "";
  const mode =
    snapshot.mode === "programmatic"
      ? " This compaction was triggered by an extension."
      : " This compaction happened automatically.";

  return `${base}${mode}${taskAnchor}${tail} Write only the next unfinished sentence or step.`;
}

export function registerCompactionSurvival(
  pi: CompactionSurvivalAPI,
  config: CompactionSurvivalConfig = {},
): CompactionSurvivalController {
  const autoResumeOnAutomaticCompaction = config.autoResumeOnAutomaticCompaction ?? true;
  const resumeDelayMs = config.resumeDelayMs ?? DEFAULT_RESUME_DELAY_MS;
  const assistantTailChars = config.assistantTailChars ?? DEFAULT_ASSISTANT_TAIL_CHARS;
  const userTaskAnchorChars = config.userTaskAnchorChars ?? DEFAULT_USER_TASK_ANCHOR_CHARS;
  const buildResumePrompt = config.buildResumePrompt ?? buildDefaultResumePrompt;

  let latestAssistantText = "";
  let activeAssistantText = "";
  let latestUserText = "";
  let pendingPrompt: string | null = null;
  let pendingMode: CompactionMode = "automatic";

  function getSnapshot(): CompactionSnapshot {
    const text = activeAssistantText.trim().length > 0 ? activeAssistantText.trim() : latestAssistantText.trim();

    return {
      mode: pendingMode,
      latestAssistantText: text,
      assistantTail: trimPromptSnippet(text, assistantTailChars),
      latestUserText: trimPromptSnippet(latestUserText, userTaskAnchorChars),
    };
  }

  function requestResume(prompt?: string) {
    pendingMode = "programmatic";
    pendingPrompt = prompt ?? buildResumePrompt(getSnapshot());
  }

  function clearPendingResume() {
    pendingPrompt = null;
  }

  pi.on("session_start", async () => {
    latestAssistantText = "";
    activeAssistantText = "";
    latestUserText = "";
    pendingPrompt = null;
    pendingMode = "automatic";
  });

  pi.on("message_start", async (event) => {
    if (event.message?.role === "assistant") {
      activeAssistantText = "";
      return;
    }

    if (event.message?.role === "user") {
      const text = extractMessageText(event.message);
      if (text.length > 0) {
        latestUserText = text;
      }
    }
  });

  pi.on("message_update", async (event) => {
    if (event.assistantMessageEvent.type === "text_delta") {
      activeAssistantText += event.assistantMessageEvent.delta;
    }
  });

  pi.on("message_end", async (event) => {
    if (event.message?.role === "assistant") {
      if (activeAssistantText.trim().length > 0) {
        latestAssistantText = activeAssistantText.trim();
        activeAssistantText = "";
      }
      return;
    }

    if (event.message?.role === "user") {
      const text = extractMessageText(event.message);
      if (text.length > 0) {
        latestUserText = text;
      }
    }
  });

  pi.on("session_before_compact", async (event) => {
    if (pendingPrompt) {
      return;
    }

    if (!autoResumeOnAutomaticCompaction) {
      return;
    }

    if (event.customInstructions !== undefined) {
      return;
    }

    const snapshot = getSnapshot();
    if (snapshot.latestAssistantText.length === 0) {
      return;
    }

    pendingMode = "automatic";
    pendingPrompt = buildResumePrompt(snapshot);
  });

  pi.on("session_compact", async () => {
    if (!pendingPrompt) {
      return;
    }

    const prompt = pendingPrompt;
    pendingPrompt = null;

    setTimeout(() => {
      try {
        const result = pi.sendUserMessage(prompt, { deliverAs: "followUp" });
        void Promise.resolve(result).catch(() => {});
      } catch {
        // Ignore resume delivery failures so compaction does not crash the extension host.
      }
    }, resumeDelayMs);
  });

  return {
    requestResume,
    clearPendingResume,
    getSnapshot,
    getPendingPrompt() {
      return pendingPrompt;
    },
  };
}
