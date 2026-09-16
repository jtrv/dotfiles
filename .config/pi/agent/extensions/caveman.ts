import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SKILL = join(homedir(), ".config/agents/skills/caveman/SKILL.md");
// Same tracker Claude runs on UserPromptSubmit; it owns the flag file that the
// shared statusline.sh reads, so both harnesses show and persist one level.
const TRACK = join(homedir(), ".config/claude/hooks/caveman-track.sh");
const FLAG = join(process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude"), ".caveman-active");

const LEVELS = ["lite", "full", "ultra", "wenyan-lite", "wenyan-full", "wenyan-ultra"];

function track(prompt: string): Promise<void> {
	return new Promise((resolve) => {
		const child = execFile("bash", [TRACK], { timeout: 5000 }, () => resolve());
		child.stdin?.end(JSON.stringify({ prompt }));
	});
}

function level(): string {
	try {
		return readFileSync(FLAG, "utf8").trim() || "lite";
	} catch {
		return "lite";
	}
}

export default function (pi: ExtensionAPI) {
	// A fresh session is caveman lite, as on Claude. The tracker deletes the
	// flag for both "off" and "never set", so "off" has to be held here.
	let active = true;
	let skill = "";

	pi.on("session_start", () => {
		active = true;
		skill = readFileSync(SKILL, "utf8");
	});

	pi.registerCommand("caveman", {
		description: "Set caveman level: lite|full|ultra|wenyan-* or off",
		handler: async (args, ctx) => {
			const arg = String(args ?? "").trim().toLowerCase();
			await track(`/caveman${arg ? ` ${arg}` : ""}`);
			active = arg !== "off";
			if (arg && arg !== "off" && !LEVELS.includes(arg)) {
				ctx.ui.notify(`Unknown level "${arg}"; expected ${LEVELS.join("|")}|off`, "warning");
				return;
			}
			ctx.ui.notify(active ? `Caveman level: ${level()}` : "Caveman off", "info");
		},
	});

	pi.on("input", async (event) => {
		if (event.source === "extension") return;
		const text = event.text.trim().toLowerCase();
		if (text === "stop caveman" || text === "normal mode") {
			active = false;
			await track(text);
		}
	});

	pi.on("before_agent_start", (event) => {
		if (!active || !skill) return;
		const base = event.systemPrompt ? `${event.systemPrompt}\n\n` : "";
		const def = `SESSION DEFAULT: caveman level = ${level()}. Begin every response at that level unless the user switches via /caveman.`;
		return { systemPrompt: `${base}${skill}\n\n${def}` };
	});
}
