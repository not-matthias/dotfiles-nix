import type { ExtensionFactory } from "@anthropic-ai/pi-coding-agent";

const tabQueue: ExtensionFactory = (pi) => {
  const queue: string[] = [];

  const updateWidget = (ctx: { ui?: { setWidget?: Function } }) => {
    if (!ctx.ui?.setWidget) return;

    if (queue.length === 0) {
      ctx.ui.setWidget("tab-queue", undefined);
      return;
    }

    const lines = queue.map(
      (m, i) => `  ${i + 1}. ${m.slice(0, 60)}${m.length > 60 ? "…" : ""}`,
    );
    ctx.ui.setWidget("tab-queue", [`⏳ Queued (${queue.length}):`, ...lines]);
  };

  const getTextFromContent = (content: unknown): string => {
    if (typeof content === "string") return content;
    if (!Array.isArray(content)) return "";

    const textParts: string[] = [];
    for (const part of content) {
      if (!part || typeof part !== "object") continue;
      if (!("type" in part) || !("text" in part)) continue;
      if ((part as { type?: unknown }).type !== "text") continue;
      if (typeof (part as { text?: unknown }).text !== "string") continue;

      textParts.push((part as { text: string }).text);
    }

    return textParts.join("\n");
  };

  pi.registerShortcut("tab", {
    description: "Submit message as follow-up (queued until agent finishes)",
    handler: async (ctx) => {
      const editorText = ctx.ui.getEditorText();
      const message = editorText?.trim();
      if (!message) return;

      ctx.ui.setEditorText("");

      if (ctx.isIdle()) {
        pi.sendUserMessage(message);
        return;
      }

      queue.push(message);
      pi.sendUserMessage(message, { deliverAs: "followUp" });
      updateWidget(ctx);
    },
  });

  pi.registerShortcut("escape", {
    description: "Clear the follow-up queue",
    handler: async (ctx) => {
      if (queue.length === 0) return;
      queue.length = 0;
      updateWidget(ctx);
    },
  });

  pi.registerShortcut("up", {
    description: "Pop last queued message back into the editor",
    handler: async (ctx) => {
      if (queue.length === 0) return;
      const message = queue.pop()!;
      ctx.ui.setEditorText(message);
      updateWidget(ctx);
    },
  });

  pi.on("message_end", (event, ctx) => {
    if (queue.length === 0) return;
    if (!("message" in event)) return;

    const message = event.message;
    if (!message || typeof message !== "object") return;
    if (!("role" in message) || message.role !== "user") return;

    const deliveredText = getTextFromContent((message as { content?: unknown }).content).trim();
    if (!deliveredText) return;
    if (deliveredText !== queue[0]) return;

    queue.shift();
    updateWidget(ctx);
  });

  pi.on("agent_end", (ctx) => {
    queue.length = 0;
    updateWidget(ctx);
  });
};

export default tabQueue;
