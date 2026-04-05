import type { ExtensionCommandContext, ExtensionFactory } from "@anthropic-ai/pi-coding-agent";
import { SelectList, type SelectItem } from "@mariozechner/pi-tui";

const THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;
type ThinkingLevel = (typeof THINKING_LEVELS)[number];

const THINKING_LEVEL_SET = new Set<string>(THINKING_LEVELS);

const ALIASES: Record<string, ThinkingLevel> = {
  none: "off",
  min: "minimal",
  med: "medium",
  max: "xhigh",
};

function normalizeThinkingLevel(input: string): ThinkingLevel | null {
  const normalized = input.trim().toLowerCase().replace(/[-_\s]/g, "");
  if (!normalized) return null;

  const fromAlias = ALIASES[normalized];
  if (fromAlias) return fromAlias;

  if (THINKING_LEVEL_SET.has(normalized)) {
    return normalized as ThinkingLevel;
  }

  return null;
}

async function showThinkingLevelSelector(
  ctx: ExtensionCommandContext,
  current: ThinkingLevel,
): Promise<ThinkingLevel | null> {
  const selected = await ctx.ui.custom<string | undefined>((tui, theme, _kb, done) => {
    const items: SelectItem[] = THINKING_LEVELS.map((level) => ({
      value: level,
      label: level,
      description: level === current ? "current" : undefined,
    }));

    const selectList = new SelectList(
      items,
      Math.min(items.length, 8),
      {
        selectedPrefix: (text) => theme.fg("accent", text),
        selectedText: (text) => theme.fg("accent", text),
        description: (text) => theme.fg("muted", text),
        scrollInfo: (text) => theme.fg("dim", text),
        noMatch: (text) => theme.fg("warning", text),
      },
    );

    const currentIndex = THINKING_LEVELS.indexOf(current);
    if (currentIndex >= 0) {
      selectList.setSelectedIndex(currentIndex);
    }

    selectList.onSelect = (item) => done(item.value);
    selectList.onCancel = () => done(undefined);

    return {
      render(width: number) {
        return selectList.render(width);
      },
      invalidate() {
        selectList.invalidate();
      },
      handleInput(data: string) {
        selectList.handleInput(data);
        tui.requestRender();
      },
    };
  });

  return normalizeThinkingLevel(selected ?? "");
}

const effortExtension: ExtensionFactory = (pi) => {
  pi.registerCommand("effort", {
    description: "Set thinking effort: off|minimal|low|medium|high|xhigh",

    getArgumentCompletions: (prefix) => {
      const normalizedPrefix = prefix.trim().toLowerCase();

      const items = THINKING_LEVELS.map((value) => ({
        value,
        label: value,
      })).filter((item) => item.value.startsWith(normalizedPrefix));

      return items.length > 0 ? items : null;
    },

    handler: async (args, ctx) => {
      const input = (args ?? "").trim();
      const current = normalizeThinkingLevel(pi.getThinkingLevel()) ?? "off";

      if (!input) {
        if (!ctx.hasUI) {
          ctx.ui.notify(
            `Current effort: ${current}. Use /effort <${THINKING_LEVELS.join("|")}> to change it.`,
            "info",
          );
          return;
        }

        const parsedSelectedLevel = await showThinkingLevelSelector(ctx, current);
        if (!parsedSelectedLevel) return;

        pi.setThinkingLevel(parsedSelectedLevel);
        const applied = pi.getThinkingLevel();

        if (applied !== parsedSelectedLevel) {
          ctx.ui.notify(`Requested effort '${parsedSelectedLevel}', applied '${applied}' (model-limited).`, "warning");
          return;
        }

        ctx.ui.notify(`Thinking effort set to '${applied}'.`, "info");
        return;
      }

      const nextLevel = normalizeThinkingLevel(input);
      if (!nextLevel) {
        ctx.ui.notify(
          `Unknown effort '${input}'. Use one of: ${THINKING_LEVELS.join(", ")}.`,
          "error",
        );
        return;
      }

      pi.setThinkingLevel(nextLevel);
      const applied = pi.getThinkingLevel();

      if (applied !== nextLevel) {
        ctx.ui.notify(`Requested effort '${nextLevel}', applied '${applied}' (model-limited).`, "warning");
        return;
      }

      ctx.ui.notify(`Thinking effort set to '${applied}'.`, "info");
    },
  });
};

export default effortExtension;
