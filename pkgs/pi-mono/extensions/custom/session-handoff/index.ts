import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

import handoff from "./handoff.js";
import sessionQuery from "./session-query.js";

export default function (pi: ExtensionAPI) {
	sessionQuery(pi);
	handoff(pi);
}
