import {
  CustomEditor,
  type ExtensionContext,
  type ExtensionFactory,
  type KeybindingsManager,
} from "@mariozechner/pi-coding-agent";
import { matchesKey, type EditorTheme, type TUI } from "@mariozechner/pi-tui";

class EscapeSteerEditor extends CustomEditor {
  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    private readonly isAgentWorking: () => boolean,
    private readonly promptForSteering: () => void,
  ) {
    super(tui, theme, keybindings);
  }

  override handleInput(data: string): void {
    if (matchesKey(data, "escape") && this.isAgentWorking()) {
      this.promptForSteering();
      return;
    }

    super.handleInput(data);
  }
}

const getErrorMessage = (error: unknown): string => {
  if (error instanceof Error) return error.message;
  return String(error);
};

const escapeSteer: ExtensionFactory = (pi) => {
  let promptOpen = false;

  const promptForSteering = async (ctx: ExtensionContext) => {
    if (promptOpen) return;
    if (ctx.isIdle()) return;

    promptOpen = true;

    try {
      const input = await ctx.ui.input("Steer current turn", "Type a steering message…");
      const message = input?.trim();
      if (!message) return;

      if (ctx.isIdle()) {
        pi.sendUserMessage(message);
        return;
      }

      pi.sendUserMessage(message, { deliverAs: "steer" });
      ctx.ui.notify("Steering message queued", "info");
    } catch (error) {
      ctx.ui.notify(`Failed to queue steering message: ${getErrorMessage(error)}`, "error");
    } finally {
      promptOpen = false;
    }
  };

  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    ctx.ui.setEditorComponent((tui, theme, keybindings) =>
      new EscapeSteerEditor(
        tui,
        theme,
        keybindings,
        () => !ctx.isIdle(),
        () => void promptForSteering(ctx),
      ),
    );
  });
};

export default escapeSteer;
