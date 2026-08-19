// @ts-nocheck
/**
 * Atuin extension for omp (oh-my-pi).
 *
 * Tracks bash commands executed by omp in Atuin history with author `omp`.
 *
 * Adapted from Atuin's pi extension (contrib/pi/atuin.ts) — omp is a pi fork
 * with the same event API, but uses `~/.omp/agent/extensions/` and a distinct
 * author tag so commands are attributable to omp, not pi. Uses
 * node:child_process spawnSync instead of pi.exec() because no omp extension
 * has been verified to use pi.exec(), while spawn is proven (plannotator).
 */

import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const ATUIN_AUTHOR = "omp";
const ATUIN_TIMEOUT_MS = 10_000;

function startHistory(cwd: string, command: string): string | undefined {
	try {
		const result = spawnSync(
			"atuin",
			["history", "start", "--author", ATUIN_AUTHOR, "--", command],
			{ cwd, timeout: ATUIN_TIMEOUT_MS, encoding: "utf-8" },
		);

		if (result.status !== 0) return undefined;

		const id = result.stdout.trim();
		return id.length > 0 ? id : undefined;
	} catch {
		return undefined;
	}
}

function endHistory(cwd: string, historyId: string, exitCode: number): void {
	try {
		spawnSync(
			"atuin",
			["history", "end", historyId, "--exit", String(exitCode)],
			{ cwd, timeout: ATUIN_TIMEOUT_MS, encoding: "utf-8" },
		);
	} catch {
		// Ignore Atuin failures so command execution is never blocked.
	}
}

// The bash tool reports failures by appending a status line to the result
// text rather than exposing a numeric exit code, so recover it from there.
function exitCodeFromResult(result: unknown, isError: boolean): number {
	if (!isError) return 0;

	const content = (result as { content?: unknown } | undefined)?.content;
	const text = Array.isArray(content)
		? content
				.map((part) => {
					const t = (part as { text?: unknown } | undefined)?.text;
					return typeof t === "string" ? t : "";
				})
				.join("\n")
		: "";

	const exited = text.match(/Command exited with code (\d+)\s*$/);
	if (exited) return Number(exited[1]);
	if (/Command aborted\s*$/.test(text)) return 130;
	if (/Command timed out after \S+ seconds\s*$/.test(text)) return 124;
	return 1;
}

export default function atuinOmpExtension(pi: ExtensionAPI) {
	// Atuin history IDs for in-flight bash tool calls, keyed by tool call ID.
	const pending = new Map<string, string>();

	// Observe bash executions through events instead of registering a bash
	// tool: registering one conflicts with other extensions that provide
	// their own bash tool (sandboxes, RTK, remote runners), while events
	// fire no matter which extension's bash tool ends up executing the
	// command.
	pi.on("tool_call", (event, ctx) => {
		if (event.toolName !== "bash") return;

		const command = event.input?.command;
		if (typeof command !== "string" || command.length === 0) return;

		const historyId = startHistory(ctx.cwd, command);
		if (historyId) pending.set(event.toolCallId, historyId);
	});

	// tool_execution_end also fires when another extension blocks the call,
	// unlike tool_result, so entries started above are always closed.
	pi.on("tool_execution_end", (event, ctx) => {
		const historyId = pending.get(event.toolCallId);
		if (!historyId) return;
		pending.delete(event.toolCallId);

		endHistory(ctx.cwd, historyId, exitCodeFromResult(event.result, event.isError));
	});
}
