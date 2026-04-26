// Adapted from https://github.com/pasky/pi-amplike (MIT).

import { complete, type Message } from "@mariozechner/pi-ai";
import type {
	ExtensionAPI,
	ExtensionCommandContext,
	ExtensionContext,
	SessionEntry,
} from "@mariozechner/pi-coding-agent";
import { BorderedLoader, convertToLlm, serializeConversation } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";

type ThinkingLevel = ReturnType<ExtensionAPI["getThinkingLevel"]>;
type SessionMessage = Extract<SessionEntry, { type: "message" }>["message"];

type HandoffSelection = {
	provider: string;
	modelId: string;
	thinkingLevel: ThinkingLevel;
};

type PendingHandoff = {
	prompt: string;
	parentSession: string | undefined;
	restore?: HandoffSelection;
};

type PendingHandoffGlobal = Omit<PendingHandoff, "parentSession"> | null;

const HANDOFF_GLOBAL_KEY = Symbol.for("pi-session-handoff-pending");

function getPendingHandoffGlobal(): PendingHandoffGlobal {
	return (globalThis as Record<symbol, PendingHandoffGlobal>)[HANDOFF_GLOBAL_KEY] ?? null;
}

function setPendingHandoffGlobal(data: PendingHandoffGlobal) {
	if (data) {
		(globalThis as Record<symbol, PendingHandoffGlobal>)[HANDOFF_GLOBAL_KEY] = data;
		return;
	}

	delete (globalThis as Record<symbol, PendingHandoffGlobal>)[HANDOFF_GLOBAL_KEY];
}

const CONTEXT_SUMMARY_SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes relevant context from the conversation (decisions made, approaches taken, key findings)
2. Lists any relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained - the new thread should be able to proceed without the old conversation

Format your response as a prompt the user can send to start the new thread. Be concise but include all necessary context. Do not include any preamble like "Here's the prompt" - just output the prompt itself.

Example output format:
## Context
We've been working on X. Key decisions:
- Decision 1
- Decision 2

Files involved:
- path/to/file1.ts
- path/to/file2.ts

## Task
[Clear description of what to do next based on user's goal]`;

async function generateContextSummary(
	model: NonNullable<ExtensionContext["model"]>,
	apiKey: string | undefined,
	headers: Record<string, string> | undefined,
	messages: SessionMessage[],
	goal: string,
	signal?: AbortSignal,
): Promise<string | null> {
	const conversationText = serializeConversation(convertToLlm(messages));
	const userMessage: Message = {
		role: "user",
		content: [
			{
				type: "text",
				text: `## Conversation History\n\n${conversationText}\n\n## User's Goal for New Thread\n\n${goal}`,
			},
		],
		timestamp: Date.now(),
	};

	const response = await complete(
		model,
		{ systemPrompt: CONTEXT_SUMMARY_SYSTEM_PROMPT, messages: [userMessage] },
		{ apiKey, headers, signal },
	);

	if (response.stopReason === "aborted") return null;

	return response.content
		.filter((part): part is { type: "text"; text: string } => part.type === "text")
		.map((part) => part.text)
		.join("\n");
}

function getCurrentSelection(pi: ExtensionAPI, ctx: ExtensionContext): HandoffSelection | undefined {
	if (!ctx.model) return undefined;

	return {
		provider: ctx.model.provider,
		modelId: ctx.model.id,
		thinkingLevel: pi.getThinkingLevel(),
	};
}

async function restoreSelection(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	restore: HandoffSelection | undefined,
): Promise<void> {
	if (!restore) return;

	const model = ctx.modelRegistry.find(restore.provider, restore.modelId);
	if (!model) {
		if (ctx.hasUI) {
			ctx.ui.notify(`Handoff: could not restore ${restore.provider}/${restore.modelId}; using current session model`, "warning");
		}
		return;
	}

	const ok = await pi.setModel(model);
	if (!ok && ctx.hasUI) {
		ctx.ui.notify(`Handoff: no API key for ${restore.provider}/${restore.modelId}; using current session model`, "warning");
	}

	pi.setThinkingLevel(restore.thinkingLevel);
}

async function buildHandoffPrompt(
	ctx: ExtensionContext,
	goal: string,
	messages: SessionMessage[],
	parentSession: string | undefined,
): Promise<string | null> {
	const summary = await ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
		const loader = new BorderedLoader(tui, theme, "Generating handoff prompt...");
		loader.onAbort = () => done(null);

		const generate = async () => {
			const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model!);
			if (!auth.ok) return null;
			return generateContextSummary(ctx.model!, auth.apiKey, auth.headers, messages, goal, loader.signal);
		};

		generate()
			.then(done)
			.catch((error) => {
				console.error("Handoff generation failed:", error);
				done(null);
			});

		return loader;
	});

	if (summary === null) return null;
	if (!parentSession) return `${goal}\n\n${summary}`;

	return [
		goal,
		`**Parent session:** \`${parentSession}\``,
		"Use the session_query tool with the parent session path if you need more details from the previous session.",
		summary,
	].join("\n\n");
}

async function performHandoff(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	goal: string,
	setPendingHandoff: (handoff: PendingHandoff | null) => void,
	fromTool = false,
): Promise<string | undefined> {
	if (!ctx.hasUI) return "Handoff requires interactive mode.";
	if (!ctx.model) return "No model selected.";

	const messages = ctx.sessionManager
		.getBranch()
		.filter((entry): entry is Extract<SessionEntry, { type: "message" }> => entry.type === "message")
		.map((entry) => entry.message);

	if (messages.length === 0) return "No conversation to hand off.";

	const parentSession = ctx.sessionManager.getSessionFile();
	const prompt = await buildHandoffPrompt(ctx, goal, messages, parentSession);
	if (prompt === null) return "Handoff cancelled.";

	const restore = getCurrentSelection(pi, ctx);

	if (!fromTool && "newSession" in ctx) {
		const cmdCtx = ctx as ExtensionCommandContext;
		setPendingHandoffGlobal({ prompt, restore });
		const result = await cmdCtx.newSession({ parentSession });
		if (result.cancelled) setPendingHandoffGlobal(null);
		return undefined;
	}

	setPendingHandoff({ prompt, parentSession, restore });
	return undefined;
}

export default function (pi: ExtensionAPI) {
	let pendingHandoff: PendingHandoff | null = null;
	let handoffTimestamp: number | null = null;

	pi.on("agent_end", (_event, ctx) => {
		if (!pendingHandoff) return;

		const { prompt, parentSession, restore } = pendingHandoff;
		pendingHandoff = null;
		handoffTimestamp = Date.now();

		(ctx.sessionManager as unknown as { newSession: (options: { parentSession?: string }) => void }).newSession({ parentSession });

		setTimeout(async () => {
			await restoreSelection(pi, ctx, restore);
			pi.sendUserMessage(prompt);
		}, 0);
	});

	pi.on("context", (event) => {
		if (handoffTimestamp === null) return;

		const newMessages = event.messages.filter((message: { timestamp?: number }) => {
			return typeof message.timestamp === "number" && message.timestamp >= handoffTimestamp!;
		});
		if (newMessages.length > 0) return { messages: newMessages };
	});

	pi.on("session_start", async (event, ctx) => {
		handoffTimestamp = null;
		if (event.reason !== "new") return;

		const pending = getPendingHandoffGlobal();
		if (!pending) return;

		setPendingHandoffGlobal(null);
		await restoreSelection(pi, ctx, pending.restore);
		pi.sendUserMessage(pending.prompt);
	});

	pi.registerCommand("handoff", {
		description: "Transfer context to a new focused session",
		handler: async (args, ctx) => {
			const goal = args.trim();
			if (!goal) {
				ctx.ui.notify("Usage: /handoff <goal>", "error");
				return;
			}

			const error = await performHandoff(pi, ctx, goal, (handoff) => {
				pendingHandoff = handoff;
			});
			if (error) ctx.ui.notify(error, "error");
		},
	});

	pi.registerTool({
		name: "handoff",
		label: "Handoff",
		description:
			"Transfer context to a new focused session. Only use this when the user explicitly asks for a handoff. Provide a goal describing what the new session should focus on.",
		parameters: Type.Object({
			goal: Type.String({ description: "The goal or task for the new session" }),
		}),

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const error = await performHandoff(pi, ctx, params.goal, (handoff) => {
				pendingHandoff = handoff;
			}, true);

			return {
				content: [{ type: "text", text: error ?? "Handoff initiated. The session will switch after the current turn completes." }],
			};
		},

		renderCall(args, theme) {
			const goal = typeof args.goal === "string" ? args.goal : "";
			const goalLines = goal.split("\n");
			const preview = goalLines.length > 5
				? `${goalLines.slice(0, 5).join("\n")}\n${theme.fg("dim", `… (${goalLines.length - 5} more lines)`)}`
				: goal;

			return new Text(`${theme.fg("toolTitle", theme.bold("Handoff "))}${theme.fg("muted", preview)}`, 0, 0);
		},
	});
}
