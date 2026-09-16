import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOOK = join(homedir(), ".config/agents/hooks/block-secrets.sh");

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", (event) => {
		const res = spawnSync("bash", [HOOK], {
			input: JSON.stringify({ tool_name: event.toolName, tool_input: event.input }),
			encoding: "utf8",
			timeout: 5000,
		});

		// Fail open on a spawn failure, matching Claude Code's PreToolUse contract:
		// a hook that cannot run is an environment fault, and denying every tool call
		// would brick the session rather than protect it.
		if (res.error || res.status === null) return;
		if (res.status === 2) {
			return { block: true, reason: res.stderr.trim() || "blocked by block-secrets" };
		}

		let out: { permissionDecision?: string; permissionDecisionReason?: string } | undefined;
		try {
			out = JSON.parse(res.stdout || "{}").hookSpecificOutput;
		} catch {
			return;
		}
		if (out?.permissionDecision === "deny") {
			return { block: true, reason: out.permissionDecisionReason ?? "blocked by block-secrets" };
		}
	});
}
