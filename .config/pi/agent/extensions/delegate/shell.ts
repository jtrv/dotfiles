import { spawn } from "node:child_process";
import { randomBytes } from "node:crypto";
import { closeSync, openSync, writeSync } from "node:fs";
import { mkdir, open } from "node:fs/promises";
import { dirname, join } from "node:path";
import { checkCwd, MARK } from "./child.ts";
import { supervise, type CleanupFailure, type CleanupHooks, type SupervisionOptions } from "./supervise.ts";
import { stateRoot } from "./worktree.ts";

export type ShellInput = { command: string; cwd?: string; timeout_s?: number; notify_on?: string; notify_on_exit?: boolean };
export type PreparedShell = Required<Omit<ShellInput, "notify_on">> & { notify_on?: string };
// 4 running trees cover server + watcher + test + build at once and bound a looping model's fan-out.
export const MAX_SHELLS = 4;
export const MAX_TIMEOUT_S = 86_400;
// The registry's 48-entry admission bound caps retained logs at 384 MiB.
export const LOG_CAP = 8 * 1024 * 1024;
// Longer lines are checked in overlapping pieces, so a match is never lost and the reported
// line still fits one 32 KiB message.
export const LINE_MAX = 16 * 1024;
export const NEEDLE_MAX = 1024;
const TAIL_WINDOW = 64 * 1024;
let active = 0;

export const logPath = (id: string) => join(stateRoot(), "logs", `${id}.log`);

export async function prepareShell(input: ShellInput, defaultCwd: string): Promise<PreparedShell> {
	const cwd = await checkCwd(input.cwd ?? defaultCwd);
	const timeout_s = input.timeout_s ?? 1800;
	if (!Number.isFinite(timeout_s) || timeout_s <= 0 || timeout_s > MAX_TIMEOUT_S)
		throw new Error(`timeout_s must be > 0 and <= ${MAX_TIMEOUT_S}`);
	if (!input.command) throw new Error("command must not be empty");
	const needle = input.notify_on;
	if (needle !== undefined && (!needle || needle.length > NEEDLE_MAX || needle.includes("\n")))
		throw new Error(`notify_on must be 1-${NEEDLE_MAX} characters without a newline`);
	return { command: input.command, cwd, timeout_s, notify_on: needle, notify_on_exit: input.notify_on_exit ?? true };
}

export function reserveShell() {
	if (active >= MAX_SHELLS) throw new Error(`shell_bg limit: ${active} of ${MAX_SHELLS} shell jobs running; nothing started`);
	active++;
}

export function lineMatcher(needle: string, onMatch: (line: string) => void, limit = LINE_MAX) {
	let pending = "";
	let found = false;
	const check = (line: string) => {
		const at = line.indexOf(needle);
		if (at < 0) return;
		found = true;
		const end = at + needle.length;
		onMatch(line.length <= limit ? line : line.slice(Math.max(0, end - limit), Math.max(limit, end)));
	};
	return {
		push(text: string) {
			let start = 0;
			let end;
			while (!found && (end = text.indexOf("\n", start)) >= 0) {
				check(pending + text.slice(start, end));
				pending = "";
				start = end + 1;
			}
			if (found) return;
			pending += text.slice(start);
			if (pending.length <= limit) return;
			check(pending);
			pending = pending.slice(pending.length - needle.length + 1);
		},
		end() {
			if (!found && pending) check(pending);
			pending = "";
		},
	};
}

export async function tail(path: string, lines: number, window = TAIL_WINDOW) {
	const file = await open(path, "r");
	try {
		const { size } = await file.stat();
		const start = Math.max(0, size - window);
		const buffer = new Uint8Array(size - start);
		await file.read(buffer, 0, buffer.length, start);
		const all = new TextDecoder().decode(buffer).split("\n");
		if (all.at(-1) === "") all.pop();
		if (start > 0 && all.length > 1) all.shift();
		return all.slice(-lines).join("\n");
	} finally {
		await file.close();
	}
}

export async function runShell(input: PreparedShell, id: string, signal: AbortSignal, hooks: CleanupHooks & { onSpawn: () => void; onMatch: (line: string) => void; sweep?: SupervisionOptions["sweep"]; write?: typeof writeSync }) {
	const started = Date.now();
	const log = logPath(id);
	let fd: number | undefined;
	try {
		await mkdir(dirname(log), { recursive: true });
		fd = openSync(log, "wx", 0o600);
		let written = 0;
		let truncated = false;
		let logError = "";
		let error = "";
		let match: string | undefined;
		let status: "exited" | "timed_out" | "cancelled" | "failed" = "exited";
		const token = randomBytes(16).toString("hex");
		const decoder = new TextDecoder();
		const matcher = input.notify_on
			? lineMatcher(input.notify_on, (line) => {
					match = line;
					hooks.onMatch(line);
				})
			: undefined;
		const { code, sig } = await (async () => {
			// The exec'd inner bash gets the command verbatim with stderr on the same pipe, so
			// output keeps kernel order and error line numbers stay those of the command.
			const child = spawn("bash", ["-c", 'exec bash -c "$1" 2>&1', "shell_bg", input.command], {
				cwd: input.cwd,
				env: { ...process.env, [MARK]: token },
				detached: true,
				stdio: ["ignore", "pipe", "pipe"],
			});
			const supervision = supervise(child, token, input.timeout_s, signal, {
				...hooks,
				onStop: (reason) => { status = reason; },
				onError: (cause) => { error = cause.message; },
			});
			const output = (chunk: Uint8Array) => {
				const room = LOG_CAP - written;
				if (chunk.length > room) truncated = true;
				if (room > 0 && !logError)
					try {
						written += (hooks.write ?? writeSync)(fd!, chunk, 0, Math.min(room, chunk.length));
					} catch (cause) {
						logError = (cause as Error).message;
					}
				matcher?.push(decoder.decode(chunk, { stream: true }));
			};
			child.stdout.on("data", output);
			child.stderr.on("data", output);
			child.on("spawn", hooks.onSpawn);
			const exit = await supervision.done;
			matcher?.push(decoder.decode());
			matcher?.end();
			return exit;
		})();
		return {
			status: error && status === "exited" ? ("failed" as const) : status,
			exit_code: code,
			signal: sig,
			command: input.command,
			cwd: input.cwd,
			duration_ms: Date.now() - started,
			log,
			log_bytes: written,
			log_truncated: truncated,
			...(match === undefined ? {} : { match }),
			tail: await tail(log, 20, 8 * 1024).catch(() => ""),
			...(error ? { error } : {}),
			...(logError ? { log_error: logError } : {}),
		};
	} finally {
		if (fd !== undefined) closeSync(fd);
		active--;
	}
}

export type ShellResult = Awaited<ReturnType<typeof runShell>> & Partial<CleanupFailure>;
