// Adapted from https://github.com/pasky/pi-amplike (MIT).

import { complete, type Message } from "@mariozechner/pi-ai";
import type { ExtensionAPI, SessionEntry } from "@mariozechner/pi-coding-agent";
import {
	SessionManager,
	convertToLlm,
	getMarkdownTheme,
	serializeConversation,
} from "@mariozechner/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui";
import { existsSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";
import { Type } from "typebox";

const QUERY_SYSTEM_PROMPT = `You are a session context assistant. Given the conversation history from a pi coding session and a question, provide a concise answer based on the session contents.

Focus on:
- Specific facts, decisions, and outcomes
- File paths and code changes mentioned
- Key context the user is asking about

Be concise and direct. If the information isn't in the session, say so.`;

const errorResult = (text: string) => ({
	content: [{ type: "text" as const, text }],
	details: { error: true },
});

function isInsideRoot(rootDir: string, targetPath: string) {
	const relative = path.relative(rootDir, targetPath);
	return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

type ResolvedSessionPath = { path: string } | { error: string };

function resolveAllowedSessionPath(sessionPath: string): ResolvedSessionPath {
	try {
		const sessionRoot = realpathSync(path.join(homedir(), ".pi", "agent", "sessions"));
		const resolvedSessionPath = realpathSync(sessionPath);
		if (!isInsideRoot(sessionRoot, resolvedSessionPath)) {
			return { error: `Session path must be inside ${sessionRoot}: ${sessionPath}` };
		}

		return { path: resolvedSessionPath };
	} catch (error) {
		return { error: `Error resolving session path: ${error}` };
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "session_query",
		label: (params) => `Session Query: ${params.question}`,
		description:
			"Query a previous pi session file for context, decisions, or information. Use when you need to look up what happened in a parent session or any other session.",
		renderResult: (result, _options, theme) => {
			const container = new Container();
			const text = result.content?.[0]?.text;
			if (!text) return container;

			const match = text.match(/\*\*Query:\*\* (.+?)\n\n---\n\n([\s\S]+)/);
			if (!match) {
				container.addChild(new Text(theme.fg("toolOutput", text), 0, 0));
				return container;
			}

			const [, query, answer] = match;
			container.addChild(new Text(theme.bold("Query: ") + theme.fg("accent", query), 0, 0));
			container.addChild(new Spacer(1));
			container.addChild(new Markdown(answer.trim(), 0, 0, getMarkdownTheme(), {
				color: (value: string) => theme.fg("toolOutput", value),
			}));
			return container;
		},
		parameters: Type.Object({
			sessionPath: Type.String({
				description: "Full path to the session file (e.g., /home/user/.pi/agent/sessions/.../session.jsonl)",
			}),
			question: Type.String({
				description: "What you want to know about that session (e.g., 'What files were modified?' or 'What approach was chosen?')",
			}),
		}),

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const { sessionPath, question } = params;

			if (!sessionPath.endsWith(".jsonl")) {
				return errorResult(`Error: Invalid session path. Expected a .jsonl file, got: ${sessionPath}`);
			}

			if (!existsSync(sessionPath)) {
				return errorResult(`Error: Session file not found: ${sessionPath}`);
			}

			onUpdate?.({
				content: [{ type: "text", text: `Query: ${question}` }],
				details: { status: "loading", question },
			});

			const resolvedSession = resolveAllowedSessionPath(sessionPath);
			if ("error" in resolvedSession) return errorResult(resolvedSession.error);

			let sessionManager: SessionManager;
			try {
				sessionManager = SessionManager.open(resolvedSession.path);
			} catch (error) {
				return errorResult(`Error loading session: ${error}`);
			}

			const branch = sessionManager.getBranch();
			const messages = branch
				.filter((entry): entry is Extract<SessionEntry, { type: "message" }> => entry.type === "message")
				.map((entry) => entry.message);

			if (messages.length === 0) {
				return {
					content: [{ type: "text" as const, text: "Session is empty - no messages found." }],
					details: { empty: true },
				};
			}

			let queryModel = ctx.model;
			const modelChanges = branch.filter(
				(entry): entry is Extract<SessionEntry, { type: "model_change" }> => entry.type === "model_change",
			);

			const lastModelChange = modelChanges.at(-1);
			if (lastModelChange) {
				queryModel = ctx.modelRegistry.find(lastModelChange.provider, lastModelChange.modelId) ?? queryModel;
			}

			if (!queryModel) {
				return errorResult("Error: No model available to analyze the session.");
			}

			try {
				const auth = await ctx.modelRegistry.getApiKeyAndHeaders(queryModel);
				if (!auth.ok) return errorResult(`Error: ${auth.error}`);

				const conversationText = serializeConversation(convertToLlm(messages));
				const userMessage: Message = {
					role: "user",
					content: [
						{
							type: "text",
							text: `## Session Conversation\n\n${conversationText}\n\n## Question\n\n${question}`,
						},
					],
					timestamp: Date.now(),
				};

				const response = await complete(
					queryModel,
					{ systemPrompt: QUERY_SYSTEM_PROMPT, messages: [userMessage] },
					{ apiKey: auth.apiKey, headers: auth.headers, signal },
				);

				if (response.stopReason === "aborted") {
					return {
						content: [{ type: "text" as const, text: "Query was cancelled." }],
						details: { cancelled: true },
					};
				}

				const answer = response.content
					.filter((part): part is { type: "text"; text: string } => part.type === "text")
					.map((part) => part.text)
					.join("\n");

				return {
					content: [{ type: "text" as const, text: `**Query:** ${question}\n\n---\n\n${answer}` }],
					details: {
						sessionPath,
						question,
						messageCount: messages.length,
					},
				};
			} catch (error) {
				return errorResult(`Error querying session: ${error}`);
			}
		},
	});
}
