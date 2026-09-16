import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const SCRIPT = join(homedir(), ".config/claude/statusline/statusline.sh");

export default function (pi: ExtensionAPI) {
	let line = "";
	let refresh: (() => void) | undefined;

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((tui, _theme, footerData) => {
			let running = false;

			// render() must be synchronous and return string[], so the subprocess can
			// never run inside it. Refresh out of band, cache the rendered line, and
			// repaint only when it actually changed.
			refresh = () => {
				if (running) return;
				running = true;
				const usage = ctx.getContextUsage();
				const payload = JSON.stringify({
					model: { display_name: ctx.model?.id ?? "pi" },
					cwd: ctx.cwd,
					workspace: { current_dir: ctx.cwd },
					context_window: { used_percentage: usage?.percent ?? null },
				});
				const child = execFile("bash", [SCRIPT], { timeout: 5000 }, (err, stdout) => {
					running = false;
					if (err) return;
					// starship prefixes its prompt with an erase-display sequence. Harmless
					// in a shell, but inside Pi's footer it would wipe the frame being
					// composed, so drop erase codes while keeping the SGR colours.
					const next = (stdout.split("\n")[0] ?? "").replace(/\x1b\[[0-9]*[JK]/g, "");
					if (next !== line) {
						line = next;
						tui.requestRender();
					}
				});
				child.stdin?.end(payload);
			};

			refresh();
			const unsubscribe = footerData.onBranchChange(refresh);

			return {
				dispose() {
					unsubscribe();
					refresh = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					return line ? [truncateToWidth(line, width)] : [];
				},
			};
		});
	});

	for (const event of ["turn_end", "model_select"] as const) {
		pi.on(event, () => refresh?.());
	}
}
