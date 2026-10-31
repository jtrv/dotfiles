import { readFile, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, isAbsolute, join } from "node:path";

export const AGY_TASK_BYTES = 96 * 1024;
export const AGY_CWD_NOTICE = "agy commands run outside delegate cwd in its conversation scratch directory; cwd is the launch directory only";
export const AGY_BYPASS_NOTICE = "agy reported BypassSandbox: true; this tool call requested execution outside the sandbox";
export const geminiDir = () => join(process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"), "gemini");

export async function checkAgyGate(dir = geminiDir()) {
	const config = join(dir, "config", "hooks.json");
	try {
		const value: unknown = JSON.parse(await readFile(config, "utf8"));
		if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("expected hook groups");
		for (const group of Object.values(value)) {
			if (!group || typeof group !== "object" || !("PreToolUse" in group) || !Array.isArray(group.PreToolUse)) continue;
			for (const entry of group.PreToolUse) {
				if (!entry || entry.matcher !== "*" || !Array.isArray(entry.hooks)) continue;
				for (const hook of entry.hooks) {
					if (typeof hook?.command !== "string") continue;
					const match = /^(?:(?:bash|\/bin\/bash|\/usr\/bin\/bash)\s+)?("[^"$\x60]+"|'[^']+'|[^\s"';&|<>$\x60]+)$/.exec(hook.command.trim());
					if (!match) continue;
					const token = match[1]!;
					const quoted = token.startsWith('"') || token.startsWith("'");
					const path = quoted ? token.slice(1, -1) : token.startsWith("~/") ? join(homedir(), token.slice(2)) : token;
					if (isAbsolute(path) && basename(path) === "agy-pretool.sh" && (await stat(path)).isFile()) return;
				}
			}
		}
		throw new Error("no wildcard PreToolUse command directly runs an existing agy-pretool.sh");
	} catch (cause) {
		throw new Error(`agy read-only preflight failed (${config}): ${String(cause)}; nothing launched`);
	}
}

export function agyBypass(event: { event?: string; step_update?: { step_type?: string; tool_info?: { parameters?: Record<string, unknown> } } }) {
	return event.event === "step_update" && event.step_update?.step_type === "tool" &&
		event.step_update.tool_info?.parameters?.BypassSandbox === true;
}
