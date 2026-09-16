import { spawn } from "node:child_process";
import { randomBytes } from "node:crypto";
import { mkdtemp, open, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { isAbsolute, join } from "node:path";
import { AGY_TASK_BYTES, AGY_CWD_NOTICE, AGY_BYPASS_NOTICE, agyBypass, checkAgyGate, geminiDir } from "./agy.ts";
import { MARK, retryCleanup, supervise, type CleanupFailure, type CleanupHooks, type SupervisionOptions } from "./supervise.ts";
export { MARK, terminate } from "./supervise.ts";

export type Runner = "pi" | "codex" | "agy";
export type Task = {
	runner: Runner;
	task: string;
	cwd?: string;
	model?: string;
	mode?: "read-only" | "write";
	timeout_s?: number;
	worktree?: boolean;
};
export type Prepared = Task & { cwd: string; timeout_s: number; model: string };
export const CAP = 32 * 1024;
// Gemini only: Claude and GPT are reached through their own harnesses, and agy exists here as
// the third-family reviewer.
export const AGY_MODELS = [
	"auto",
	"gemini-3.8-flash-high",
	"gemini-3.8-flash-medium",
	"gemini-3.8-flash-low",
	"gemini-3.1-pro-high",
	"gemini-3.1-pro-low",
];
const MAX_CHILDREN = 2;
let active = 0;

export function capped(text: string, limit = CAP) {
	const bytes = Buffer.from(text);
	return {
		text: new TextDecoder("utf-8", { fatal: false }).decode(bytes.subarray(0, limit), {
			stream: bytes.length > limit,
		}),
		truncated: bytes.length > limit,
	};
}

export function buildArgs(input: Task, cwd: string, output: string) {
	const mode = input.mode ?? "read-only";
	if (mode !== "read-only" && mode !== "write") throw new Error("Invalid mode");
	if (input.runner === "codex") {
		const model = input.model ?? "gpt-5.6-terra";
		if (!["gpt-5.6-luna", "gpt-5.6-terra", "gpt-5.6-sol", "gpt-6-astra"].includes(model))
			throw new Error("Invalid Codex model");
		return {
			model,
			args: [
				"exec",
				"--skip-git-repo-check",
				"-m",
				model,
				"-C",
				cwd,
				"--sandbox",
				mode === "write" ? "workspace-write" : "read-only",
				"--ephemeral",
				"--json",
				"--output-last-message",
				output,
				"-",
			],
		};
	}
	if (input.runner === "agy") {
		const model = input.model ?? "auto";
		if (!AGY_MODELS.includes(model)) throw new Error("Invalid agy model");
		// Headless agy soft-denies any tool it cannot prompt for and then prints nothing at all, so
		// permissions are skipped and hooks/agy-pretool.sh enforces the mode from PI_DELEGATE_MODE.
		// The prompt rides on -p= because a bare -p swallows the next flag as the prompt.
		return {
			model,
			args: [
				`--gemini_dir=${geminiDir()}`,
				"--sandbox",
				"--dangerously-skip-permissions",
				"--output-format=stream-json",
				`--print-timeout=${input.timeout_s ?? 600}s`,
				...(model === "auto" ? [] : [`--model=${model}`]),
				`-p=${input.task}`,
			],
		};
	}
	if (input.runner !== "pi") throw new Error("Invalid runner");
	const model = input.model ?? "openai-codex/gpt-5.6-sol";
	const match = /^([^/\s]+)\/(\S+)$/.exec(model);
	if (!match) throw new Error("Pi model must be provider/model");
	return {
		model,
		args: [
			"-p",
			"--no-session",
			"--no-extensions",
			"--no-skills",
			"--no-prompt-templates",
			"--provider",
			match[1]!,
			"--model",
			match[2]!,
			"--mode",
			"json",
			...(mode === "read-only" ? ["--tools", "read,grep,find,ls"] : []),
		],
	};
}

function childEnv() {
	// Allowlist preserves auth/config lookup without inheriting parent session or prompt variables.
	const names = [
		"PATH",
		"HOME",
		"USER",
		"LOGNAME",
		"SHELL",
		"LANG",
		"LC_ALL",
		"TERM",
		"TMPDIR",
		"XDG_CONFIG_HOME",
		"XDG_CACHE_HOME",
		"XDG_DATA_HOME",
		"XDG_STATE_HOME",
		"CODEX_HOME",
		"CLAUDE_CONFIG_DIR",
		"PI_CODING_AGENT_DIR",
		"CONTEXT_MODE_DIR",
		"HTTP_PROXY",
		"HTTPS_PROXY",
		"NO_PROXY",
		"SSL_CERT_FILE",
		"SSL_CERT_DIR",
		"NODE_EXTRA_CA_CERTS",
	];
	return {
		...Object.fromEntries(names.flatMap((key) => (process.env[key] === undefined ? [] : [[key, process.env[key]]]))),
		// Signing needs gpg-agent and a display for pinentry, neither of which a headless child has;
		// worker commits stay unsigned and the user's own config keeps signing everything else.
		GIT_CONFIG_COUNT: "1",
		GIT_CONFIG_KEY_0: "commit.gpgsign",
		GIT_CONFIG_VALUE_0: "false",
	};
}

export type Progress = { turns: number; tools: string[] };
export type Hooks = CleanupHooks & { onSpawn?: (model: string) => void; onProgress?: (progress: Progress) => void; sweep?: SupervisionOptions["sweep"]; remove?: (dir: string) => Promise<void> };
const LINE_LIMIT = 8 * 1024 * 1024;

export function lineSplitter(onLine: (line: string) => void, onOversize: () => void, limit = LINE_LIMIT) {
	let pending = "";
	let skipping = false;
	const emit = (line: string) => {
		if (skipping) skipping = false;
		else if (line.length > limit) onOversize();
		else onLine(line);
	};
	return {
		push(chunk: string) {
			pending += chunk;
			let end;
			while ((end = pending.indexOf("\n")) >= 0) {
				emit(pending.slice(0, end));
				pending = pending.slice(end + 1);
			}
			if (pending.length > limit) {
				if (!skipping) onOversize();
				skipping = true;
				pending = "";
			}
		},
		end() {
			if (pending) emit(pending);
			pending = "";
		},
	};
}

type Event = {
	type?: string;
	toolCallId?: string;
	toolName?: string;
	item?: { id?: string; type?: string; command?: string };
	event?: string;
	step_update?: { step_index?: number; state?: string; step_type?: string; tool_name?: string; tool_info?: { parameters?: Record<string, unknown> } };
	result?: { status?: string; response?: string; error?: string };
};

export function trackProgress(runner: Runner, event: Event, state: { turns: number; tools: Map<string, string> }) {
	if (runner === "agy") {
		const step = event.event === "step_update" ? event.step_update : undefined;
		if (!step) return false;
		const key = String(step.step_index);
		if (step.step_type === "agent_response" && step.state === "DONE") state.turns++;
		else if (step.step_type === "tool" && step.state === "ACTIVE") {
			const arg = Object.values(step.tool_info?.parameters ?? {}).find((v) => typeof v === "string") as string | undefined;
			state.tools.set(key, `${step.tool_name ?? "tool"}${arg ? ` ${arg}` : ""}`.slice(0, 80));
		} else if (step.step_type === "tool") state.tools.delete(key);
		else return false;
		return true;
	}
	const t = event.type;
	if (t === (runner === "pi" ? "turn_start" : "turn.started")) state.turns++;
	else if (runner === "pi" && event.toolCallId && t === "tool_execution_start")
		state.tools.set(event.toolCallId, event.toolName ?? "tool");
	else if (runner === "pi" && event.toolCallId && t === "tool_execution_end") state.tools.delete(event.toolCallId);
	else if (runner === "codex" && event.item?.id && t === "item.started" && event.item.type !== "agent_message")
		state.tools.set(event.item.id, (event.item.command ?? event.item.type ?? "item").slice(0, 80));
	else if (runner === "codex" && event.item?.id && t === "item.completed") return state.tools.delete(event.item.id);
	else return false;
	return true;
}

export async function checkCwd(cwd: string) {
	if (!isAbsolute(cwd) || !(await stat(cwd).catch(() => undefined))?.isDirectory())
		throw new Error("cwd must be an absolute existing directory");
	return cwd;
}

export async function prepare(input: Task, defaultCwd: string): Promise<Prepared> {
	const cwd = await checkCwd(input.cwd ?? defaultCwd);
	const timeout = input.timeout_s ?? 600;
	if (!Number.isFinite(timeout) || timeout <= 0 || timeout > 1800)
		throw new Error("timeout_s must be > 0 and <= 1800");
	if (!input.task) throw new Error("task must not be empty");
	if (input.runner === "agy") {
		if (Buffer.byteLength(input.task, "utf8") > AGY_TASK_BYTES)
			throw new Error(`agy task exceeds ${AGY_TASK_BYTES} UTF-8 bytes; task is passed in process-visible argv; nothing reserved`);
		if (input.worktree) throw new Error("agy worktree is unsupported: command cwd cannot be fixed to the worktree");
		if ((input.mode ?? "read-only") === "read-only") await checkAgyGate();
	}
	if (input.worktree && input.mode !== "write") throw new Error("worktree requires mode write");
	return { ...input, cwd, timeout_s: timeout, model: buildArgs(input, cwd, "").model };
}

// Synchronous so a batch takes all its slots or none; spawnChild releases one slot each.
export function reserve(count: number) {
	if (active + count > MAX_CHILDREN)
		throw new Error(
			`delegate concurrency limit: ${active} of ${MAX_CHILDREN} children active, ${count} requested; nothing started`,
		);
	active += count;
}

export const release = () => {
	active--;
};

export async function runDelegate(input: Task, defaultCwd: string, signal?: AbortSignal, hooks: Hooks = {}) {
	const prepared = await prepare(input, defaultCwd);
	reserve(1);
	return spawnChild(prepared, signal, hooks);
}

export async function spawnChild(input: Prepared, signal?: AbortSignal, hooks: Hooks = {}): Promise<ChildResult> {
	const started = Date.now();
	const { cwd, timeout_s: timeout } = input;
	let dir: string | undefined;
	try {
		if (input.runner === "agy" && (input.mode ?? "read-only") === "read-only") await checkAgyGate();
		dir = await mkdtemp(join(tmpdir(), "pi-delegate-"));
		const output = join(dir, "final.txt");
		const { model, args } = buildArgs(input, cwd, output);
		let final = { text: "", truncated: false };
		let error = "";
		let stderr = "";
		let sandbox_bypass = false;
		const token = randomBytes(16).toString("hex");
		const exit_code = await (async () => {
			const child = spawn(input.runner, args, {
				cwd,
				env: { ...childEnv(), [MARK]: token, PI_DELEGATE_MODE: input.mode ?? "read-only" },
				shell: false,
				detached: true,
				stdio: ["pipe", "pipe", "pipe"],
			});
			const supervision = supervise(child, token, timeout, signal, {
				...hooks,
				onStop: (reason) => { error = reason === "cancelled" ? "Delegation aborted" : `Delegation timed out after ${timeout}s`; },
				onError: (cause) => { error = cause.message; },
			});
			const progress = { turns: 0, tools: new Map<string, string>() };
			const line = (text: string) => {
				let event;
				try {
					event = JSON.parse(text) as Event & {
						message?: {
							role?: string;
							stopReason?: string;
							errorMessage?: string;
							content?: { type?: string; text?: string }[];
						};
					};
				} catch {
					return;
				}
				if (event && trackProgress(input.runner, event, progress))
					hooks.onProgress?.({ turns: progress.turns, tools: [...progress.tools.values()] });
				if (input.runner === "agy") {
					if (event && agyBypass(event)) sandbox_bypass = true;
					if (event?.event !== "result" || !event.result) return;
					final = capped(event.result.response ?? "");
					if (event.result.status !== "SUCCESS") error = event.result.error ?? `agy ${event.result.status}`;
					return;
				}
				if (input.runner !== "pi" || event?.type !== "message_end" || event.message?.role !== "assistant")
					return;
				const message = event.message;
				if (message.stopReason === "toolUse") {
					final = { text: "", truncated: false };
					return;
				}
				final = capped(
					(message.content ?? [])
						.filter((part) => part.type === "text")
						.map((part) => part.text ?? "")
						.join("\n"),
				);
				if (message.stopReason === "error" || message.stopReason === "aborted")
					error = message.errorMessage ?? `Pi ${message.stopReason}`;
			};
			// Codex events embed command output, so an oversized one is only dropped; Pi's
			// final answer arrives as one event, so losing one would misreport the result.
			const lines = lineSplitter(line, () => {
				if (input.runner !== "pi") return;
				error = "Pi event exceeds 8 MiB safety limit";
				supervision.kill();
			});
			child.stdout.setEncoding("utf8");
			child.stdout.on("data", (chunk: string) => lines.push(chunk));
			child.on("spawn", () => hooks.onSpawn?.(model));
			child.stderr.on("data", (chunk: Buffer) => {
				stderr = capped(stderr + chunk.toString()).text;
			});
			child.stdin.on("error", (cause: Error) => {
				error ||= `stdin: ${cause.message}`;
			});
			child.stdin.end(input.runner === "agy" ? undefined : input.task);
			const { code } = await supervision.done;
			lines.end();
			return code;
		})();
		if (input.runner === "codex") {
			try {
				const file = await open(output, "r");
				try {
					const buffer = new Uint8Array(CAP + 1);
					const { bytesRead } = await file.read(buffer, 0, buffer.length, 0);
					final = capped(new TextDecoder().decode(buffer.subarray(0, bytesRead)));
				} finally {
					await file.close();
				}
			} catch (cause) {
				error ||= `No final message: ${String(cause)}`;
			}
		}
		error ||=
			exit_code !== 0
				? `Child exited ${exit_code}: ${stderr}`
				: !final.text.trim()
					? `No final message: ${stderr}`
					: "";
		return {
			final_text: final.text,
			exit_code,
			runner: input.runner,
			model,
			cwd,
			duration_ms: Date.now() - started,
			truncated: final.truncated,
			status: error ? "failed" : "answered",
			...(error ? { error } : {}),
			...(input.runner === "agy" ? { sandbox_bypass } : {}),
			...((final.truncated || input.runner === "agy") ? { notice: [
				...(final.truncated ? ["Final text truncated to 32 KiB"] : []),
				...(input.runner === "agy" ? [AGY_CWD_NOTICE] : []),
				...(sandbox_bypass ? [AGY_BYPASS_NOTICE] : []),
			].join("; ") } : {}),
		};
	} finally {
		if (dir) {
			const path = dir;
			await retryCleanup(async () => {
				try {
					await (hooks.remove ?? ((target) => rm(target, { recursive: true, force: true })))(path);
					return { unkilled_pids: [], cleanup_error: "" };
				} catch (cause) {
					return { unkilled_pids: [], cleanup_error: `Temporary directory cleanup failed (${path}): ${String(cause)}` };
				}
			}, hooks).done;
		}
		release();
	}
}

type ChildResult = {
	final_text: string; exit_code: number | null; runner: Runner; model: string; cwd: string;
	duration_ms: number; truncated: boolean; status: string; error?: string; notice?: string; sandbox_bypass?: boolean;
} & Partial<CleanupFailure>;
export type Result = ChildResult;
