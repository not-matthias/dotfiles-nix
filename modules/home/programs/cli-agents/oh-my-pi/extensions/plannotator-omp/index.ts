/**
 * Plannotator OMP Extension — Plan mode with visual browser review via the
 * plannotator CLI binary.
 *
 * During planning the agent writes a markdown plan file and calls
 * plannotator_submit_plan. The plan opens in the browser where the user can
 * approve, deny with feedback, or annotate. On approval the agent gets full
 * tool access to execute the plan.
 *
 * Commands:
 *   /plannotator              Toggle plan mode
 *   /plannotator-review       Open code review UI for current changes
 *   /plannotator-annotate <f> Open a file/URL/folder in annotation UI
 *   /plannotator-last         Annotate the last assistant message
 *
 * Tool:
 *   plannotator_submit_plan   Submit plan file for browser review
 *
 * Flag:
 *   --plan                    Start in plan mode
 */

import { statSync } from "node:fs";
import { resolve, relative } from "node:path";
import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

type Phase = "idle" | "planning" | "executing";

interface PlannotatorDecision {
  decision: "approved" | "dismissed" | "annotated";
  feedback?: string;
}

const PLANNING_PROMPT = `[PLANNOTATOR - PLANNING PHASE]
You are in plan mode. You MUST NOT make any changes to the codebase — no edits,
no commits, no installs, no destructive commands. During planning you may only
write or edit markdown files (.md, .mdx) inside the working directory.

Available tools: read, bash, grep, glob, write (markdown only), edit (markdown only), plannotator_submit_plan

Do not run destructive bash commands (rm, git push, npm install, etc.) — focus
on reading and exploring the codebase.

## Workflow

1. Explore the codebase using read, grep, glob, and bash.
2. Write your plan to a markdown file (e.g. PLAN.md or plans/<name>.md).
3. Call plannotator_submit_plan with the path to submit for review.
4. If denied with feedback, edit the plan file and resubmit.

### Plan File Structure

- **Context** — Why this change is being made.
- **Approach** — Your recommended approach.
- **Files to modify** — Critical file paths.
- **Steps** — Implementation checklist:
  - [ ] Step 1 description
  - [ ] Step 2 description
- **Verification** — How to test end-to-end.

Your turn should only end by asking a question or calling plannotator_submit_plan.`;

const PLANNOTATOR_RUN_ERROR = "Failed to run plannotator. Is it installed and on PATH?";

/** Run the plannotator CLI, returning stdout. Rejects on spawn failure. */
function runPlannotator(args: string[], stdin?: string): Promise<string> {
  const { promise, resolve: settle, reject } = Promise.withResolvers<string>();
  const child = spawn("plannotator", args, {
    stdio: ["pipe", "pipe", "ignore"],
  });
  let stdout = "";
  child.stdout.on("data", (data: Buffer) => {
    stdout += data.toString();
  });
  child.on("error", (err) => reject(err));
  child.on("close", () => settle(stdout));
  if (stdin) child.stdin.write(stdin);
  child.stdin.end();
  return promise;
}

function parseDecision(stdout: string): PlannotatorDecision | null {
  try {
    return JSON.parse(stdout) as PlannotatorDecision;
  } catch {
    return null;
  }
}

/** True if the path is a markdown file inside cwd (no directory traversal). */
function isMarkdownInCwd(inputPath: string, cwd: string): boolean {
  if (!/\.mdx?$/i.test(inputPath)) return false;
  const cwdResolved = resolve(cwd);
  const rel = relative(cwdResolved, resolve(cwdResolved, inputPath));
  return rel !== "" && !rel.startsWith("..");
}

export default function plannotator(pi: ExtensionAPI): void {
  const { z } = pi.zod;
  let phase: Phase = "idle";
  let lastSubmittedPath: string | null = null;
  let lastAssistantText = "";

  // ── Flag ──────────────────────────────────────────────────────────

  pi.registerFlag("plan", {
    description: "Start in plan mode (restricted exploration and planning)",
    type: "boolean",
    default: false,
  });

  // ── Commands ──────────────────────────────────────────────────────

  pi.registerCommand("plannotator", {
    description: "Toggle plannotator plan mode",
    handler: async (_args, ctx) => {
      if (phase === "idle") {
        phase = "planning";
        ctx.ui.setStatus("plannotator", ctx.ui.theme.fg("warning", "\u23F8 plan"));
        ctx.ui.notify(
          "Plannotator: planning mode enabled. Writes restricted to .md files.",
          "info",
        );
      } else {
        phase = "idle";
        lastSubmittedPath = null;
        lastAssistantText = "";
        ctx.ui.setStatus("plannotator", undefined);
        ctx.ui.notify("Plannotator: disabled. Full access restored.", "info");
      }
    },
  });

  pi.registerCommand("plannotator-review", {
    description:
      "Open code review UI for current changes or a PR URL; pass --git to force git",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) return;
      ctx.ui.notify("Opening code review...", "info");
      const reviewArgs = ["review"];
      if (args?.includes("--git")) reviewArgs.push("--git");
      const urlMatch = args?.match(/https?:\/\/\S+/);
      if (urlMatch) reviewArgs.push(urlMatch[0]);
      try {
        await runPlannotator(reviewArgs);
        ctx.ui.notify("Code review closed.", "info");
      } catch {
        ctx.ui.notify(PLANNOTATOR_RUN_ERROR, "error");
      }
    },
  });

  pi.registerCommand("plannotator-annotate", {
    description: "Open a file, URL, or folder in the annotation UI",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) return;
      const filePath = args?.trim();
      if (!filePath) {
        ctx.ui.notify(
          "Usage: /plannotator-annotate <file.md | https://... | folder/>",
          "error",
        );
        return;
      }
      ctx.ui.notify(`Opening annotation UI for ${filePath}...`, "info");
      try {
        const stdout = await runPlannotator(["annotate", filePath, "--json"]);
        const decision = parseDecision(stdout);
        if (decision?.feedback) {
          pi.sendUserMessage(decision.feedback, { deliverAs: "followUp" });
        } else {
          ctx.ui.notify("Annotation closed.", "info");
        }
      } catch {
        ctx.ui.notify(PLANNOTATOR_RUN_ERROR, "error");
      }
    },
  });

  pi.registerCommand("plannotator-last", {
    description: "Annotate the last assistant message",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      ctx.ui.notify("Opening annotation UI for last message...", "info");
      try {
        const stdout = lastAssistantText
          ? await runPlannotator(["annotate-last", "--stdin", "--json"], lastAssistantText)
          : await runPlannotator(["annotate-last", "--json"]);
        const decision = parseDecision(stdout);
        if (decision?.feedback) {
          pi.sendUserMessage(decision.feedback, { deliverAs: "followUp" });
        } else {
          ctx.ui.notify("Annotation closed.", "info");
        }
      } catch {
        ctx.ui.notify(PLANNOTATOR_RUN_ERROR, "error");
      }
    },
  });

  // ── plannotator_submit_plan Tool ──────────────────────────────────

  pi.registerTool({
    name: "plannotator_submit_plan",
    label: "Submit Plan",
    description:
      "Submit your plan for user review. Call this while in plan mode, after writing your plan to a markdown file. " +
      "The user reviews it in the browser and can approve, deny with feedback, or annotate it. " +
      "If denied, edit the same file in place, then call this again with the same path.",
    parameters: z.object({
      filePath: z.string().describe(
        "Path to the markdown plan file, relative to the working directory. Must end in .md or .mdx and resolve inside cwd.",
      ),
    }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (phase !== "planning") {
        return {
          content: [
            {
              type: "text" as const,
              text: "Error: Not in plan mode. Use /plannotator to enter planning mode first.",
            },
          ],
        };
      }

      const inputPath = (params as { filePath?: string })?.filePath?.trim();
      if (!inputPath) {
        return {
          content: [
            {
              type: "text" as const,
              text: "Error: plannotator_submit_plan requires a filePath argument.",
            },
          ],
        };
      }

      if (!isMarkdownInCwd(inputPath, ctx.cwd)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Error: plan file must be a markdown file (.md or .mdx) inside the working directory. Rejected: ${inputPath}`,
            },
          ],
        };
      }

      const fullPath = resolve(ctx.cwd, inputPath);
      let isRegularFile = false;
      try {
        isRegularFile = statSync(fullPath).isFile();
      } catch {}
      if (!isRegularFile) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Error: ${inputPath} does not exist or is not a regular file. Write your plan first, then call plannotator_submit_plan.`,
            },
          ],
        };
      }

      lastSubmittedPath = inputPath;

      // Non-interactive: auto-approve
      if (!ctx.hasUI) {
        phase = "executing";
        lastAssistantText = "";
        ctx.ui.setStatus("plannotator", undefined);
        return {
          content: [
            {
              type: "text" as const,
              text: "Plan auto-approved (non-interactive session). Proceed with implementation.",
            },
          ],
          details: { approved: true },
        };
      }

      // Open plan review in browser via CLI — pass the file path directly
      ctx.ui.notify("Opening plan review in browser...", "info");
      let stdout: string;
      try {
        stdout = await runPlannotator(["annotate", fullPath, "--gate", "--json"]);
      } catch {
        return {
          content: [
            { type: "text" as const, text: PLANNOTATOR_RUN_ERROR },
          ],
        };
      }
      const decision = parseDecision(stdout);

      if (!decision) {
        return {
          content: [
            {
              type: "text" as const,
              text: "Plan review was closed without a decision. Please call plannotator_submit_plan again to resubmit.",
            },
          ],
        };
      }

      if (decision.decision === "approved") {
        phase = "executing";
        lastAssistantText = "";
        ctx.ui.setStatus("plannotator", undefined);
        const notes = decision.feedback
          ? `\n\nNotes from reviewer:\n${decision.feedback}`
          : "";
        return {
          content: [
            {
              type: "text" as const,
              text: `Plan approved. You now have full tool access. Execute the plan from ${inputPath}.${notes}`,
            },
          ],
          details: { approved: true, feedback: decision.feedback },
        };
      }

      // Denied or annotated — feedback goes back to the agent
      const feedback = decision.feedback || "Plan rejected. Please revise.";
      return {
        content: [
          {
            type: "text" as const,
            text: `Plan not approved. Feedback:\n\n${feedback}\n\nEdit the plan file and call plannotator_submit_plan again with the same path.`,
          },
        ],
        details: { approved: false, feedback },
      };
    },
  });

  // ── Write gating during planning ──────────────────────────────────

  pi.on("tool_call", async (event, ctx) => {
    if (phase !== "planning") return;
    if (event.toolName !== "write" && event.toolName !== "edit") return;

    const inputPath = event.input?.path;
    if (typeof inputPath !== "string" || !isMarkdownInCwd(inputPath, ctx.cwd)) {
      const verb = event.toolName === "write" ? "writes" : "edits";
      return {
        block: true,
        reason: `Plannotator: during planning, ${verb} are limited to markdown files (.md, .mdx) inside the working directory. Blocked: ${inputPath}`,
      };
    }
  });

  // ── Phase prompts ─────────────────────────────────────────────────

  pi.on("before_agent_start", async () => {
    if (phase === "planning") {
      return {
        message: {
          customType: "plannotator-context",
          content: PLANNING_PROMPT,
          display: false,
        },
      };
    }
    if (phase === "executing" && lastSubmittedPath) {
      return {
        message: {
          customType: "plannotator-context",
          content: `[PLANNOTATOR - EXECUTING]\nFull tool access enabled. Execute the plan from ${lastSubmittedPath}.`,
          display: false,
        },
      };
    }
  });

  // ── Capture last assistant message for /plannotator-last ──────────

  pi.on("turn_end", async (event) => {
    const msg = (event as { message?: { content?: unknown } }).message;
    if (!msg) return;
    const content = msg.content;
    if (typeof content === "string") {
      lastAssistantText = content;
    } else if (Array.isArray(content)) {
      lastAssistantText = content
        .filter((c: { type?: string }) => c.type === "text")
        .map((c: { text?: string }) => c.text ?? "")
        .join("\n");
    }
  });

  // ── Restore state on session start ────────────────────────────────

  pi.on("session_start", async () => {
    lastAssistantText = "";
    if (pi.getFlag("plan") === true) {
      phase = "planning";
    }
  });
}
