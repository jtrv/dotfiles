import type { ChildProcess } from "node:child_process";
import { readFileSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import { setTimeout as sleep } from "node:timers/promises";

export const MARK = "PI_DELEGATE_RUN";
export type CleanupFailure = { unkilled_pids: number[]; cleanup_error: string };
export type CleanupHooks = {
	onCleanup?: (failure: CleanupFailure) => void;
	onRetry?: (retry: () => Promise<boolean>) => void;
};
type Proc = { start: string; ppid: number; dead: boolean };
type Reader = (path: string) => Promise<string>;
const parse = (text: string): Proc => {
	const fields = text.slice(text.lastIndexOf(")") + 2).split(" ");
	if (!fields[19]) throw new Error("Invalid proc stat");
	return { start: fields[19], ppid: Number(fields[1]), dead: fields[0] === "Z" || fields[0] === "X" };
};
const gone = (error: unknown) => (error as NodeJS.ErrnoException).code === "ENOENT";
const read: Reader = (path) => readFile(path, "utf8");

export function seedRoot(pid: number, known: Map<number, string | null>) {
	try {
		const proc = parse(readFileSync(`/proc/${pid}/stat`, "utf8"));
		if (!proc.dead) known.set(pid, proc.start);
	} catch (error) {
		if (!gone(error)) known.set(pid, null);
	}
}

export async function tree(token: string, known: Map<number, string | null>, reader: Reader = read, list = () => readdir("/proc")) {
	const names = new Set((await list()).filter((name) => /^\d+$/.test(name)));
	for (const pid of known.keys()) names.add(String(pid));
	const queue = [...names];
	const table = new Map<number, Proc>();
	const marked = new Set<number>();
	const errors: string[] = [];
	await Promise.all(Array.from({ length: Math.min(16, queue.length) }, async () => {
		for (let name = queue.pop(); name !== undefined; name = queue.pop()) {
			const pid = Number(name);
			try {
				const proc = parse(await reader(`/proc/${pid}/stat`));
				if (proc.dead) { known.delete(pid); continue; }
				if (known.has(pid) && known.get(pid) !== null && known.get(pid) !== proc.start) known.delete(pid);
				if (known.get(pid) === null) {
					errors.push(`${pid}: root start identity unavailable`);
					continue;
				}
				table.set(pid, proc);
				try {
					const env = await reader(`/proc/${pid}/environ`);
					if (`\0${env}`.includes(`\0${MARK}=${token}\0`)) marked.add(pid);
				} catch (error) {
					if (known.has(pid) && !gone(error)) errors.push(`${pid}: ${String(error)}`);
				}
			} catch (error) {
				if (gone(error)) known.delete(pid);
				else if (known.has(pid)) errors.push(`${pid}: ${String(error)}`);
			}
		}
	}));
	for (const pid of marked) known.set(pid, table.get(pid)!.start);
	let size;
	do {
		size = known.size;
		for (const [pid, proc] of table) if (known.get(proc.ppid) != null) known.set(pid, proc.start);
	} while (known.size > size);
	return { pids: [...known.keys()], errors };
}

function send(root: number, known: Map<number, string | null>, signal: NodeJS.Signals) {
	for (const [pid, start] of known) {
		try {
			if (start === null || parse(readFileSync(`/proc/${pid}/stat`, "utf8")).start !== start) continue;
			if (pid === root) {
				try { process.kill(-root, signal); } catch {}
			}
			process.kill(pid, signal);
		} catch {}
	}
}

// Pi's detached bash cleanup needs SIGTERM before forced termination.
export async function terminate(root: number, token: string, known: Map<number, string | null>) {
	const termed = new Set<number>();
	let observation = await tree(token, known);
	const grace = Date.now() + 2000;
	while (known.size && Date.now() < grace) {
		const fresh = new Map([...known].filter(([pid]) => !termed.has(pid)));
		send(root, fresh, "SIGTERM");
		for (const pid of fresh.keys()) termed.add(pid);
		await sleep(50);
		observation = await tree(token, known);
	}
	const force = Date.now() + 1000;
	while (known.size && Date.now() < force) {
		send(root, known, "SIGSTOP");
		await tree(token, known);
		send(root, known, "SIGKILL");
		await sleep(50);
		observation = await tree(token, known);
	}
	return {
		unkilled_pids: observation.pids,
		cleanup_error: observation.errors.join("; ") || (known.size ? `Surviving processes: ${observation.pids.join(" ")}` : ""),
	};
}

export function retryCleanup(attempt: () => Promise<CleanupFailure>, hooks: CleanupHooks = {}) {
	let resolve!: () => void;
	const done = new Promise<void>((settle) => { resolve = settle; });
	let finished = false;
	let flight: Promise<boolean> | undefined;
	let timer: ReturnType<typeof setTimeout> | undefined;
	let delay = 250;
	const retry = (): Promise<boolean> => {
		if (finished) return Promise.resolve(true);
		if (flight) return flight;
		clearTimeout(timer);
		flight = Promise.resolve().then(attempt).catch((error: unknown) => ({ unkilled_pids: [], cleanup_error: String(error) })).then((failure) => {
			if (failure.unkilled_pids.length || failure.cleanup_error) {
				hooks.onCleanup?.(failure);
				timer = setTimeout(() => { void retry(); }, delay);
				delay = Math.min(delay * 2, 10_000);
				return false;
			}
			finished = true;
			resolve();
			return true;
		}).finally(() => { flight = undefined; });
		return flight;
	};
	hooks.onRetry?.(retry);
	void retry();
	return { done, retry };
}

export type SupervisionOptions = CleanupHooks & {
	sweep?: typeof terminate;
	onStop: (reason: "cancelled" | "timed_out") => void;
	onError: (error: Error) => void;
};

export function supervise(child: ChildProcess, token: string, timeout: number, signal: AbortSignal | undefined, hooks: SupervisionOptions) {
	const known = new Map<number, string | null>();
	if (child.pid) seedRoot(child.pid, known);
	let cleanup: ReturnType<typeof retryCleanup> | undefined;
	let timer: ReturnType<typeof setTimeout>;
	const stopTimer = () => clearTimeout(timer);
	const kill = () => {
		stopTimer();
		cleanup ??= retryCleanup(async () => {
			try {
				return child.pid ? await (hooks.sweep ?? terminate)(child.pid, token, known) : { unkilled_pids: [], cleanup_error: "" };
			} catch (error) {
				return { unkilled_pids: [...known.keys()], cleanup_error: `Process sweep failed: ${String(error)}` };
			}
		}, hooks);
		return cleanup;
	};
	const abort = () => { hooks.onStop("cancelled"); kill(); };
	timer = setTimeout(() => { hooks.onStop("timed_out"); kill(); }, timeout * 1000);
	signal?.addEventListener("abort", abort, { once: true });
	const closed = new Promise<{ code: number | null; sig: NodeJS.Signals | null }>((resolve) => {
		child.once("error", hooks.onError);
		child.once("exit", kill);
		child.once("close", (code, sig) => {
			kill();
			resolve({ code, sig });
		});
	});
	if (signal?.aborted) abort();
	return {
		kill,
		done: closed.then(async (exit) => {
			await kill().done;
			signal?.removeEventListener("abort", abort);
			return exit;
		}),
	};
}
