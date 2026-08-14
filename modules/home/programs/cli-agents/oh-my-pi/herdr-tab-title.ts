import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const herdr = process.env.HERDR_BIN_PATH ?? "herdr";
const paneId = process.env.HERDR_PANE_ID;

function renameTab(title: string | undefined): void {
	const label = title?.trim();
	if (!paneId || !label) return;

	const child = spawn(herdr, ["pane", "get", paneId], { stdio: ["ignore", "pipe", "ignore"] });
	let output = "";
	child.stdout?.on("data", (chunk) => {
		output += chunk;
	});
	child.on("close", (status) => {
		if (status !== 0) return;
		try {
			const pane = JSON.parse(output)?.result?.pane;
			if (pane?.tab_id) spawn(herdr, ["tab", "rename", pane.tab_id, label], { stdio: "ignore" });
		} catch {
			// Herdr may be restarting; the next title change retries the update.
		}
	});
}

export default function herdrTabTitle(pi: ExtensionAPI): void {
	if (process.env.HERDR_ENV !== "1" || !paneId) return;

	pi.on("session_start", (_event, ctx) => {
		renameTab(ctx.sessionManager.getSessionName());
		ctx.sessionManager.onSessionNameChanged(() => {
			renameTab(ctx.sessionManager.getSessionName());
		});
	});
}
