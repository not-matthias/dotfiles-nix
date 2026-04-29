import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { writeSync } from "node:fs";

/**
 * Adds `--dump-system-prompt` to Pi.
 */
export default function dumpSystemPrompt(pi: ExtensionAPI) {
	pi.registerFlag("dump-system-prompt", {
		description: "Print the assembled system prompt and exit before calling the model",
		type: "boolean",
		default: false,
	});

	let dumped = false;

	const dumpAndExit = (prompt: string) => {
		if (dumped) return;
		dumped = true;

		// Use fd 1 directly. In print/JSON integrations Pi may wrap process.stdout,
		// but fd 1 remains the caller's stdout and is redirect-friendly.
		writeSync(1, prompt.endsWith("\n") ? prompt : `${prompt}\n`);
		process.exit(0);
	};

	const enabled = () => pi.getFlag("dump-system-prompt") === true;

	pi.on("session_start", () => {
		if (!enabled()) return;

		// If Pi already has an initial prompt, let that prompt start the turn.
		if (hasInitialPrompt()) return;

		runSyntheticDumpTurn();
	});

	pi.on("context", (_event, ctx) => {
		if (!enabled()) return;

		// context runs after the full before_agent_start chain and is awaited while
		// building the request context, so we exit before any provider/model call.
		dumpAndExit(ctx.getSystemPrompt());
	});
}

function runSyntheticDumpTurn(): never {
	const childArgs = [process.argv[1], ...process.argv.slice(2), "-p", "dump"];
	const result = spawnSync(process.execPath, childArgs, {
		cwd: process.cwd(),
		env: { ...process.env, PI_NOCHIO_SYNTHETIC_DUMP: "1" },
		encoding: "utf8",
		maxBuffer: 1024 * 1024 * 100,
	});

	if (result.stdout) writeSync(1, result.stdout);

	if (result.error) {
		writeSync(2, `pi-nochio: failed to run synthetic dump turn: ${result.error.message}\n`);
		process.exit(1);
	}

	if ((result.status ?? 1) !== 0) {
		if (result.stderr) writeSync(2, result.stderr);
		process.exit(result.status ?? 1);
	}

	process.exit(0);
}

function hasInitialPrompt(): boolean {
	const args = process.argv.slice(2);
	const flagsWithRequiredValue = new Set([
		"--provider",
		"--model",
		"--api-key",
		"--system-prompt",
		"--append-system-prompt",
		"--mode",
		"--session",
		"--fork",
		"--session-dir",
		"--models",
		"--tools",
		"-t",
		"--extension",
		"-e",
		"--skill",
		"--prompt-template",
		"--theme",
		"--export",
	]);

	for (let i = 0; i < args.length; i++) {
		const arg = args[i];

		if (arg === "--dump-system-prompt") continue;
		if ((arg === "--print" || arg === "-p") && !process.stdin.isTTY) return true;
		if (arg.startsWith("@")) return true;

		if (arg === "--list-models") {
			// Optional search arg; either way Pi exits before a prompt would run.
			return true;
		}

		if (flagsWithRequiredValue.has(arg)) {
			i++;
			continue;
		}

		if (arg.startsWith("--") && arg.includes("=")) continue;
		if (arg.startsWith("-")) continue;

		return true;
	}

	return false;
}
