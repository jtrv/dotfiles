import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let skill = "";

  pi.on("session_start", () => {
    skill = "";
    if (process.env.CHOLO_OFF === "1") return;
    try {
      skill = readFileSync(join(homedir(), ".config/agents/skills/cholo/SKILL.md"), "utf8").replace(
        /^---\r?\n[\s\S]*?\r?\n---(?:\r?\n|$)/,
        "",
      );
    } catch {
      return;
    }
  });

  pi.on("before_agent_start", (event) => {
    if (process.env.CHOLO_OFF === "1" || !skill) return;
    return { systemPrompt: event.systemPrompt ? `${event.systemPrompt}\n\n${skill}` : skill };
  });
}
