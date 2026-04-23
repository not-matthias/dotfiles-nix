// Vendored from:
// https://github.com/DonaldMurillo/my-pi/tree/main/extensions/compaction-survival
// Retrieved 2026-04-22.

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

import { registerCompactionSurvival } from "./core.ts";

export default function (pi: ExtensionAPI) {
  const survival = registerCompactionSurvival(pi);

  pi.registerCommand("compaction-survival", {
    description: "Show compaction survival status",
    handler: async (_args, ctx) => {
      const snapshot = survival.getSnapshot();
      const lines = [
        "Compaction Survival",
        `  pending resume: ${survival.getPendingPrompt() ? "yes" : "no"}`,
        `  mode: ${snapshot.mode}`,
        `  assistant tail: ${snapshot.assistantTail || "none"}`,
      ];
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
