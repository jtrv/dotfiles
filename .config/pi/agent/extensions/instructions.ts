import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Pi-only instructions. AGENTS.md is shared by every harness and is discovered
// by Pi itself; this is the Pi counterpart of the Claude-only half of CLAUDE.md,
// which Pi has no import mechanism for.
const FILE = join(homedir(), ".config/agents/pi.md");

export default function (pi: ExtensionAPI) {
	let text = "";

	pi.on("session_start", () => {
		try {
			text = readFileSync(FILE, "utf8").trim();
		} catch {
			text = "";
		}
	});

	pi.on("before_agent_start", (event) => {
		if (!text) return;
		const base = event.systemPrompt ? `${event.systemPrompt}\n\n` : "";
		return { systemPrompt: `${base}${text}` };
	});
}
