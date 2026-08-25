// Native Helix bridge for oh-my-pi.
//
// This extension is separate from the omp.nvim bridge. It exposes an omp
// session to the Steelix client and streams chat events over JSONL.
//
// Client frames:
//   {"type":"ping"}
//   {"type":"prompt","text":"...","submit":true}
//
// Server frames:
//   status: ready | prompt_accepted | turn_started | turn_ended
//   pong
//   chat_user, chat_delta, chat_tool, chat_message_end

import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import { createHash } from "node:crypto";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const DIR = path.join(os.homedir(), ".omp", "run", "omp-helix");
const HASH_LEN = 16;
const SOCKET_MODE = 0o600;

interface BridgeClient {
	write(data: string): void;
}

interface SocketServer {
	close(): void;
}

interface SessionCtx {
	ui?: {
		getEditorText(): string;
		setEditorText(text: string): void;
	};
	hasUI?: boolean;
}

interface PromptFrame {
	type: "prompt";
	text: string;
	submit?: boolean;
}

function isPromptFrame(value: unknown): value is PromptFrame {
	if (typeof value !== "object" || value === null) return false;
	if (!("type" in value) || !("text" in value)) return false;
	return value.type === "prompt" && typeof (value as PromptFrame).text === "string";
}

function socketPathFor(cwd: string): string {
	const hash = createHash("sha256").update(cwd).digest("hex").slice(0, HASH_LEN);
	return path.join(DIR, `omp-helix-${hash}.sock`);
}

function isOccupied(socketPath: string): Promise<boolean> {
	const { promise, resolve } = Promise.withResolvers<boolean>();
	const probe = net.createConnection(socketPath);
	probe.once("connect", () => {
		probe.destroy();
		resolve(true);
	});
	probe.once("error", () => resolve(false));
	return promise;
}

export default async function ompHelixBridge(pi: ExtensionAPI): Promise<void> {
	fs.mkdirSync(DIR, { recursive: true });
	const socketPath = socketPathFor(process.cwd());

	if (fs.existsSync(socketPath) && (await isOccupied(socketPath))) {
		console.error(`[omp-helix] bridge disabled: another omp owns ${socketPath}`);
		return;
	}
	if (fs.existsSync(socketPath)) {
		try {
			fs.unlinkSync(socketPath);
		} catch {
			// A stale socket is best-effort cleanup.
		}
	}

	const clients = new Set<BridgeClient>();
	const clientBuffers = new WeakMap<BridgeClient, string>();
	let sessionCtx: SessionCtx | undefined;
	const pendingCompose: string[] = [];

	const broadcast = (frame: object): void => {
		const line = `${JSON.stringify(frame)}\n`;
		for (const client of clients) {
			try {
				client.write(line);
			} catch {
				// The close/error handlers remove dead clients.
			}
		}
	};

	const compose = (text: string): void => {
		if (!sessionCtx) {
			pendingCompose.push(text);
			return;
		}
		if (!sessionCtx.hasUI || !sessionCtx.ui) {
			pi.sendUserMessage(text);
			return;
		}
		const current = sessionCtx.ui.getEditorText();
		sessionCtx.ui.setEditorText(current ? `${current}\n${text}` : text);
	};

	const handleLine = (client: BridgeClient, line: string): void => {
		if (!line.trim()) return;
		let frame: unknown;
		try {
			frame = JSON.parse(line);
		} catch {
			return;
		}

		if (isPromptFrame(frame)) {
			if (frame.submit === false) {
				compose(frame.text);
			} else {
				pi.sendUserMessage(frame.text);
			}
			client.write(`${JSON.stringify({ type: "status", event: "prompt_accepted" })}\n`);
			return;
		}
		if (typeof frame === "object" && frame !== null && "type" in frame && frame.type === "ping") {
			client.write(`${JSON.stringify({ type: "pong" })}\n`);
		}
	};

	let server: SocketServer;
	try {
		server = Bun.listen({
			unix: socketPath,
			socket: {
				open(client: BridgeClient) {
					clients.add(client);
					clientBuffers.set(client, "");
					client.write(`${JSON.stringify({ type: "status", event: "ready" })}\n`);
				},
				data(client: BridgeClient, buffer: Uint8Array) {
					const combined = (clientBuffers.get(client) ?? "") + Buffer.from(buffer).toString();
					const lines = combined.split("\n");
					clientBuffers.set(client, lines.pop() ?? "");
					for (const line of lines) handleLine(client, line);
				},
				close(client: BridgeClient) {
					clients.delete(client);
					clientBuffers.delete(client);
				},
				error(client: BridgeClient, error: unknown) {
					clients.delete(client);
					clientBuffers.delete(client);
					console.error(`[omp-helix] socket error: ${String(error)}`);
				},
			},
		});
	} catch (error) {
		console.error(`[omp-helix] cannot bind ${socketPath}: ${String(error)}`);
		return;
	}

	try {
		fs.chmodSync(socketPath, SOCKET_MODE);
	} catch {
		// The directory is private by default; failure is non-fatal.
	}

	pi.on("session_start", (_event, ctx) => {
		sessionCtx = ctx as SessionCtx;
		while (pendingCompose.length > 0) compose(pendingCompose.shift()!);
	});
	pi.on("before_agent_start", (event) => {
		broadcast({ type: "chat_user", text: event.prompt });
	});
	pi.on("agent_start", () => broadcast({ type: "status", event: "turn_started" }));
	pi.on("agent_end", () => broadcast({ type: "status", event: "turn_ended" }));
	pi.on("message_update", (event) => {
		const update = event.assistantMessageEvent;
		if (update?.type === "text_delta" && update.delta) {
			broadcast({ type: "chat_delta", text: update.delta });
		}
	});
	pi.on("tool_execution_start", (event) => {
		broadcast({ type: "chat_tool", name: event.toolName });
	});
	pi.on("message_end", (event) => {
		if (event.message?.role === "assistant") {
			broadcast({ type: "chat_message_end" });
		}
	});

	process.on("exit", () => {
		try {
			server.close();
			if (fs.existsSync(socketPath)) fs.unlinkSync(socketPath);
		} catch {
			// Best-effort cleanup on process exit.
		}
	});
}
