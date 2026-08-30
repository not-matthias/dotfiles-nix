import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

let active = false;

export default function askOpenQuestionExtension(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "ask_open_question",
		label: "Open Question",
		description:
			"Ask the interactive user one open-ended question and return their free-form answer. Use this only when predefined options would constrain the answer; use ask for 2-5 materially different choices.",
		strict: true,
		loadMode: "essential",
		approval: "read",
		parameters: pi.zod.object({
			question: pi.zod.string().min(1).describe("The open-ended question to show the user"),
		}),

		async execute(_toolCallId, { question }, signal, _onUpdate, context) {
			if (!context.hasUI) {
				context.abort();
				throw new Error("ask_open_question requires interactive mode");
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
