import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

type CavemanLevel = "off" | "lite" | "full" | "ultra";

type Completion = {
  value: CavemanLevel;
  label: CavemanLevel;
};

let currentLevel: CavemanLevel = "full";

const instructions: Record<Exclude<CavemanLevel, "off">, string> = {
  lite: `For all explanations, use caveman lite style unless the user explicitly asks for a different intensity. Drop filler words like "just", "really", "basically", "actually", and "simply". Remove pleasantries like "sure", "certainly", "of course", and "happy to". Keep grammar and technical precision.`,
  full: `For all explanations, use caveman full style unless the user explicitly asks for a different intensity. Drop articles (a, an, the), filler, pleasantries, and hedging. Use fragments when clearer. Prefer short synonyms. Keep technical terms, code, command names, API names, commit messages, and quoted errors exact. Code blocks unchanged. Pattern: [thing] [action] [reason]. [next step].`,
  ultra: `For all explanations, use caveman ultra style unless the user explicitly asks for a different intensity. Maximum compression. State each fact once. Strip conjunctions when cause and effect stay clear. Keep technical terms, code, command names, API names, commit messages, and quoted errors exact. Code blocks unchanged.`,
};

const completions: Completion[] = ["off", "lite", "full", "ultra"].map((level) => ({
  value: level as CavemanLevel,
  label: level as CavemanLevel,
}));

function normalizeLevel(value: string): CavemanLevel | undefined {
  const level = value.trim().toLowerCase().split(/\s+/)[0]?.replace(/[^a-z]/g, "");
  if (level === "off" || level === "lite" || level === "full" || level === "ultra") {
    return level;
  }
  return undefined;
}

function status(level: CavemanLevel): string {
  if (level === "off") {
    return "Caveman off. Normal style.";
  }
  if (level === "lite") {
    return "Caveman lite. Drop filler, keep grammar.";
  }
  if (level === "ultra") {
    return "Caveman ultra. Maximum compression.";
  }
  return "Caveman full. Drop articles, fragments ok.";
}

function levelFromText(text: string): CavemanLevel | undefined {
  if (text.includes("stop caveman") || text.includes("normal mode")) {
    return "off";
  }

  const enablesCaveman = [
    "caveman mode",
    "talk like caveman",
    "use caveman",
    "less tokens",
    "fewer tokens",
    "be brief",
  ].some((trigger) => text.includes(trigger));

  if (!enablesCaveman) {
    return undefined;
  }
  if (text.includes("lite")) {
    return "lite";
  }
  if (text.includes("ultra")) {
    return "ultra";
  }
  return "full";
}

export default function caveman(pi: ExtensionAPI) {
  pi.setLabel("Caveman");

  pi.registerCommand("caveman", {
    description: "Set caveman response style: off, lite, full, or ultra",
    getArgumentCompletions: (prefix: string) => completions.filter((item) => item.value.startsWith(prefix)),
    handler: async (args: string | undefined, ctx) => {
      const rawArgs = (args ?? "").trim();
      if (rawArgs.length === 0) {
        currentLevel = currentLevel === "off" ? "full" : "off";
        ctx.ui.notify(status(currentLevel), "info");
        return;
      }

      const requestedLevel = normalizeLevel(rawArgs);
      if (!requestedLevel) {
        ctx.ui.notify(`Unknown caveman level: ${rawArgs}. Use off, lite, full, or ultra.`, "error");
        return;
      }

      currentLevel = requestedLevel;
      ctx.ui.notify(status(currentLevel), "info");
    },
  });

  pi.on("session_start", async () => {
    currentLevel = "full";
  });

  pi.on("input", async (event, ctx) => {
    const nextLevel = levelFromText(event.text.toLowerCase());
    if (!nextLevel) {
      return;
    }
    currentLevel = nextLevel;
    ctx.ui.notify(status(currentLevel), "info");
  });

  pi.on("before_agent_start", async (event) => {
    if (currentLevel === "off") {
      return;
    }
    return {
      systemPrompt: [...event.systemPrompt, instructions[currentLevel]],
    };
  });
}
