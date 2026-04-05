import type { ExtensionCommandContext, ExtensionFactory } from "@anthropic-ai/pi-coding-agent";
import { SelectList, type SelectItem } from "@mariozechner/pi-tui";

const normalizeThemeName = (value: string): string => value.trim();

function getSortedThemeNames(ctx: ExtensionCommandContext): string[] {
  return ctx.ui
    .getAllThemes()
    .map((theme) => theme.name)
    .filter((name, index, arr) => Boolean(name) && arr.indexOf(name) === index)
    .sort((a, b) => a.localeCompare(b));
}

async function showThemeSelector(
  ctx: ExtensionCommandContext,
  themeNames: string[],
  currentThemeName: string,
): Promise<string | null> {
  const originalTheme = ctx.ui.theme;
  const selected = await ctx.ui.custom<string | undefined>((tui, theme, _kb, done) => {
    const items: SelectItem[] = themeNames.map((name) => ({
      value: name,
      label: name,
      description: name === currentThemeName ? "current" : undefined,
    }));

    const selectList = new SelectList(items, Math.min(items.length, 12), {
      selectedPrefix: (text) => theme.fg("accent", text),
      selectedText: (text) => theme.fg("accent", text),
      description: (text) => theme.fg("muted", text),
      scrollInfo: (text) => theme.fg("dim", text),
      noMatch: (text) => theme.fg("warning", text),
    });

    const currentIndex = themeNames.indexOf(currentThemeName);
    if (currentIndex >= 0) {
      selectList.setSelectedIndex(currentIndex);
    }

    selectList.onSelect = (item) => done(item.value);
    selectList.onCancel = () => done(undefined);
    selectList.onSelectionChange = (item) => {
      const previewTheme = ctx.ui.getTheme(item.value);
      if (!previewTheme) return;
      ctx.ui.setTheme(previewTheme);
    };

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

  if (!selected) {
    ctx.ui.setTheme(originalTheme);
    return null;
  }

  return normalizeThemeName(selected);
}

const themeExtension: ExtensionFactory = (pi) => {
  let cachedThemeNames: string[] = [];

  const refreshThemeCache = (ctx: ExtensionCommandContext) => {
    cachedThemeNames = getSortedThemeNames(ctx);
  };

  pi.on("session_start", async (_event, ctx) => {
    refreshThemeCache(ctx);
  });

  pi.registerCommand("theme", {
    description: "Set UI theme or pick from a list",

    getArgumentCompletions: (prefix) => {
      const normalizedPrefix = normalizeThemeName(prefix).toLowerCase();

      const items = cachedThemeNames
        .filter((name) => name.toLowerCase().startsWith(normalizedPrefix))
        .map((name) => ({
          value: name,
          label: name,
        }));

      return items.length > 0 ? items : null;
    },

    handler: async (args, ctx) => {
      refreshThemeCache(ctx);

      const requested = normalizeThemeName(args ?? "");
      const currentThemeName = normalizeThemeName(ctx.ui.theme.name ?? "");

      if (!requested) {
        if (!ctx.hasUI) {
          ctx.ui.notify("UI not available. Use /theme <name> in interactive mode.", "warning");
          return;
        }

        if (cachedThemeNames.length === 0) {
          ctx.ui.notify("No themes found.", "warning");
          return;
        }

        const selectedTheme = await showThemeSelector(ctx, cachedThemeNames, currentThemeName);
        if (!selectedTheme) return;

        const result = ctx.ui.setTheme(selectedTheme);
        if (!result.success) {
          ctx.ui.notify(`Failed to set theme '${selectedTheme}': ${result.error ?? "unknown error"}`, "error");
          return;
        }

        ctx.ui.notify(`Theme set to '${selectedTheme}'.`, "info");
        return;
      }

      const result = ctx.ui.setTheme(requested);
      if (!result.success) {
        const available = cachedThemeNames.length > 0 ? cachedThemeNames.join(", ") : "(none found)";
        const reason = result.error ? ` (${result.error})` : "";
        ctx.ui.notify(`Failed to set theme '${requested}'${reason}. Available: ${available}`, "error");
        return;
      }

      ctx.ui.notify(`Theme set to '${requested}'.`, "info");
    },
  });
};

export default themeExtension;
