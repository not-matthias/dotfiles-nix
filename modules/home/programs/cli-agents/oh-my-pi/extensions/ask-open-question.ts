import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

let active = false;

export default function askOpenQuestionExtension(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "ask_open_question",
		label: "Open Question",
		description:
			"Interactive sessions only. Ask one open-ended question when predefined options would constrain the answer; use ask for 2-5 materially different choices. In headless contexts, route necessary questions to an interactive parent or report the blocker.",
		strict: true,
		loadMode: "essential",
		approval: "read",
		parameters: pi.zod.object({
			question: pi.zod.string().min(1).describe("The open-ended question to show the user"),
		}),

		async execute(_toolCallId, { question }, signal, _onUpdate, context) {
			if (!context.hasUI) {
				throw new Error(
					"Interactive input is unavailable. Route this question to an interactive parent or report the blocker; do not invent an answer.",
				);
			}
			if (active) throw new Error("ask_open_question is already waiting for an answer");

			active = true;
			try {
				const answer = await context.ui.editor(question, undefined, { signal }, { promptStyle: true });
				if (answer === undefined) {
					context.abort();
					throw new Error("Open question was cancelled by the user");
				}

				return {
					content: [{ type: "text", text: `User answer:\n${answer}` }],
					details: { question, answer },
				};
			} catch (error) {
				if (error instanceof Error && error.name === "AbortError") {
					context.abort();
					throw new Error("Open question input was cancelled");
				}
				throw error;
			} finally {
				active = false;
			}
		},
	});
}
