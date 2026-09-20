import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const finishingPrompt = `Before finishing, review only changes attributable to the current user task, including changes already committed during this task. Use the conversation and diff evidence to establish ownership; do not treat all dirty or staged content as yours.

If this was a read-only task or you made no in-scope changes, finish without cleanup edits or extra checks.

Otherwise, read skill://deslop and apply it yourself. Make only local, high-confidence, behavior-preserving simplifications. Preserve unrelated user hunks even in files you edited. If ownership or semantic equivalence is uncertain, flag the candidate instead of changing it. Recommend larger redesigns and public API changes rather than applying them.

After cleanup edits, run applicable formatting and verification under the project's instructions. Do not repeat checks solely for this pass if you made no cleanup edits. Briefly report meaningful cuts, checks actually run, and unresolved failures; if nothing needed changing, keep the result short.

Do not delegate this pass, create or amend commits, push, update dependencies, or generate documentation. Leave cleanup edits uncommitted and report them. Do not repeat cleanup on the cleanup.`;

export default function deslop(pi: ExtensionAPI): void {
	let pendingSessionId: string | undefined;

	pi.on("message_start", ({ message }, ctx) => {
		const userInput =
			(message.role === "user" && message.attribution !== "agent") ||
			(message.role === "custom" && message.attribution === "user" && message.display !== false);
		if (userInput) pendingSessionId = ctx.sessionManager.getSessionId();
	});

	pi.on("session_switch", () => {
		pendingSessionId = undefined;
	});

	pi.on("agent_end", ({ willContinue }) => {
		// Explicit aborts settle without emitting session_stop.
		if (!willContinue) pendingSessionId = undefined;
	});

	pi.on("session_stop", (event) => {
		if (event.signal.aborted || pendingSessionId !== event.session_id) return;
		pendingSessionId = undefined;

		const last = event.last_assistant_message;
		if (last?.role !== "assistant" || last.stopReason !== "stop") return;

		return { continue: true, additionalContext: finishingPrompt };
	});
}
