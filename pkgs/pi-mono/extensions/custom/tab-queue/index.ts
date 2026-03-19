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

  pi.registerShortcut("tab", {
    description: "Submit message as follow-up (queued until agent finishes)",
    handler: async (ctx) => {
      const text = ctx.ui.getEditorText();
      if (!text?.trim()) return;

      ctx.ui.setEditorText("");

      if (ctx.isIdle()) {
        pi.sendUserMessage(text);
        return;
      }

      queue.push(text.trim());
      pi.sendUserMessage(text, { deliverAs: "followUp" });
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
      const msg = queue.pop()!;
      ctx.ui.setEditorText(msg);
      updateWidget(ctx);
    },
  });

  pi.on("agent_end", (ctx) => {
    queue.length = 0;
    updateWidget(ctx);
  });
};

export default tabQueue;
