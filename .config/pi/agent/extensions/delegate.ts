import { randomBytes } from "node:crypto";
import { realpath } from "node:fs/promises";
import { dirname } from "node:path";
import { rmSync } from "node:fs";
import { setTimeout as sleep } from "node:timers/promises";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { CAP, capped, prepare, release, reserve, spawnChild, type Prepared, type Progress, type Result, type Task, type Hooks } from "./delegate/child.ts";
import type { CleanupFailure } from "./delegate/supervise.ts";
import { LOG_CAP, logPath, MAX_SHELLS, MAX_TIMEOUT_S, NEEDLE_MAX, prepareShell, reserveShell, runShell, tail, type ShellInput, type ShellResult } from "./delegate/shell.ts";
import { cwdHolders, listWorktrees, locate, NOTICE, provision, pruneEmpty, removeWorktree, resolveWorktree, worktreePath, type Base } from "./delegate/worktree.ts";

export { buildArgs, lineSplitter, runDelegate, trackProgress, type Progress } from "./delegate/child.ts";

// Same schema pi-ai's StringEnum emits; not imported from there because only Pi's
// loader can resolve that package, and the test runs without it.
function stringEnum<const T extends readonly string[]>(values: T, options: Record<string, unknown> = {}) {
	return Type.Unsafe<T[number]>({ type: "string", enum: [...values], ...options });
}

const taskFields = {
	runner: stringEnum(["pi", "codex", "agy"]),
	cwd: Type.Optional(Type.String({ description: "Absolute existing directory; defaults to ctx.cwd" })),
	model: Type.Optional(
		Type.String({
			description:
				"Pi: provider/model (default openai-codex/gpt-6-sol). Codex: gpt-6-luna | gpt-6-sol | gpt-6-astra (default gpt-6-sol). agy (Gemini): gemini-3.8-flash-high | gemini-3.8-flash-medium | gemini-3.8-flash-low | gemini-3.1-pro-high | gemini-3.1-pro-low (default auto).",
		}),
	),
	mode: Type.Optional(stringEnum(["read-only", "write"], { default: "read-only" })),
	timeout_s: Type.Optional(Type.Number({ exclusiveMinimum: 0, maximum: 1800, default: 600 })),
	worktree: Type.Optional(
		Type.Boolean({
			description:
				"Write mode only: run in a new detached git worktree of cwd's repository at HEAD, same subdirectory. Kept afterwards; remove via delegate_jobs remove_worktree",
		}),
	),
};

// task and tasks are two optional fields rather than a oneOf: top-level unions trip some
// providers' tool-schema validators, so exactly-one is enforced at runtime.
export const parameters = Type.Object(
	{
		...taskFields,
		runner: Type.Optional(taskFields.runner),
		task: Type.Optional(Type.String({ minLength: 1 })),
		tasks: Type.Optional(
			Type.Array(
				Type.Object(
					{ ...taskFields, runner: Type.Optional(taskFields.runner), task: Type.String({ minLength: 1 }) },
					{ additionalProperties: false },
				),
				{
					minItems: 1,
					maxItems: 2,
					description:
						"Batch of independent children instead of task; each gets only its own task. Unset fields fall back to the top-level ones. All slots are reserved or none start.",
				},
			),
		),
		background: Type.Optional(
			Type.Boolean({
				description:
					"Return { job_id } (batch: { batch_id, jobs }) once started; the result arrives later as a delegate-result message and stays available via delegate_jobs",
			}),
		),
	},
	{ additionalProperties: false },
);

export const jobParameters = Type.Object(
	{
		action: stringEnum(["list", "result", "cancel", "wait", "tail", "list_worktrees", "remove_worktree"]),
		job_id: Type.Optional(Type.String({ description: "Job or batch id" })),
		timeout_s: Type.Optional(Type.Number({ exclusiveMinimum: 0, maximum: 1800, default: 600 })),
		lines: Type.Optional(Type.Integer({ minimum: 1, maximum: 500, default: 40, description: "tail: lines from the end of a shell job's log" })),
		path: Type.Optional(Type.String({ description: "remove_worktree: a worktree under the pi-delegate worktree root, instead of job_id" })),
		force: Type.Optional(Type.Boolean({ description: "remove_worktree: discard uncommitted changes" })),
	},
	{ additionalProperties: false },
);

export const shellParameters = Type.Object(
	{
		command: Type.String({ minLength: 1, description: "Run with bash -c" }),
		cwd: Type.Optional(Type.String({ description: "Absolute existing directory; defaults to ctx.cwd" })),
		timeout_s: Type.Optional(Type.Number({ exclusiveMinimum: 0, maximum: MAX_TIMEOUT_S, default: 1800 })),
		notify_on: Type.Optional(
			Type.String({
				minLength: 1,
				maxLength: NEEDLE_MAX,
				description: "Literal substring, not a regex: the first output line containing it is delivered once as a message while the job runs",
			}),
		),
		notify_on_exit: Type.Optional(
			Type.Boolean({
				default: true,
				description: "Deliver exit status, duration and the last 20 log lines when it ends, unless cancelled or already fetched via delegate_jobs result or wait",
			}),
		),
	},
	{ additionalProperties: false },
);

type Message = { customType: string; content: string; display: boolean; details: Record<string, unknown> };
type State = "starting" | "running" | "cleanup_failed" | "done" | "failed" | "cancelled";
type Notify = "none" | "pending" | "sent" | "collected";
type Worktree = { worktree_path: string; base_sha: string; repo_root: string };
type Shell = { log: string; notify_on?: string; notify_on_exit: boolean; match?: string; matchNotify: Notify };
type Job = {
	id: string;
	admitted: boolean;
	task: string;
	runner: string;
	model: string;
	cwd: string;
	mode: string;
	state: State;
	cleanup?: CleanupFailure;
	retry?: () => Promise<boolean>;
	stalled: Promise<void>;
	report: () => void;
	started: number;
	finished?: number;
	progress: Progress;
	result?: (Result | ShellResult) & Partial<Worktree & { job_id: string; worktree_notice: string }>;
	worktree?: Worktree;
	shell?: Shell;
	notify: Notify;
	controller: AbortController;
	generation: number;
	batch?: string;
	spawned: boolean;
	ready: Promise<boolean>;
	done: Promise<unknown>;
};
type Batch = {
	id: string;
	jobs: Job[];
	state: State;
	started: number;
	finished?: number;
	notify: Notify;
	generation: number;
	cancelled: boolean;
	done: Promise<void>;
};
const RETAINED = 20;
export const BACKLOG = 48;
const UPDATE_MS = 500;

export const summary = (p: Progress) =>
	[`turn ${p.turns}`, ...(p.tools.length ? [`running ${p.tools.join(", ")}`] : [])].join("; ");

export function createJobs(deps: {
	send: (message: Message, options: { deliverAs: "followUp"; triggerTurn: true }) => void;
	isIdle: () => boolean;
	status: (text: string | undefined) => void;
	childHooks?: Pick<Hooks, "sweep" | "remove">;
	shellHooks?: Pick<Parameters<typeof runShell>[3], "sweep" | "write">;
}) {
	const jobs = new Map<string, Job>();
	const batches = new Map<string, Batch>();
	let generation = 0;
	let closed = false;
	const live = (job: Job) => job.state === "starting" || job.state === "running" || job.state === "cleanup_failed";
	const progressStops = new Set<() => void>();
	const cleanupState = () => {
		let report!: () => void;
		const stalled = new Promise<void>((resolve) => { report = resolve; });
		return { stalled, report };
	};
	const cleanupHooks = (job: Job) => ({
		onRetry: (retry: () => Promise<boolean>) => { job.retry = retry; },
		onCleanup: (failure: CleanupFailure) => {
			job.cleanup = failure;
			job.state = "cleanup_failed";
			job.report();
			refresh();
		},
	});
	const refresh = () => {
		if (closed) return;
		const running = [...jobs.values()].filter(live).length;
		try {
			deps.status(running ? `delegate: ${running} running` : undefined);
		} catch {}
	};
	const view = (job: Job, withResult = false) => ({
		job_id: job.id,
		kind: job.shell ? "shell" : "delegate",
		state: job.state,
		...(live(job) && job.cleanup ? job.cleanup : {}),
		...(job.shell
			? { command: job.task, log: job.shell.log, ...(job.shell.match === undefined ? {} : { match: job.shell.match }) }
			: { runner: job.runner, model: job.model, mode: job.mode, task: job.task, progress: summary(job.progress) }),
		cwd: job.cwd,
		elapsed_ms: (job.finished ?? Date.now()) - job.started,
		...(job.worktree ? { worktree_path: job.worktree.worktree_path } : {}),
		...(withResult && job.result ? { result: job.result } : {}),
	});
	const batchView = (batch: Batch, withResult = false) => ({
		batch_id: batch.id,
		state: batch.jobs.some((job) => job.state === "cleanup_failed") ? "cleanup_failed" as const : batch.state,
		elapsed_ms: (batch.finished ?? Date.now()) - batch.started,
		jobs: batch.jobs.map((job) => view(job, withResult)),
	});
	const get = (id: string) => {
		const entry = batches.get(id) ?? jobs.get(id);
		if (!entry) throw new Error(`Unknown delegate job: ${id}`);
		return entry;
	};
	const section = (job: Job, head: string, limit: number) => {
		const result = job.result as Result;
		return capped(
			[
				`${head} ${job.id} ${job.state}: ${job.task}`,
				`runner=${result.runner} model=${result.model} cwd=${result.cwd}`,
				...(job.worktree
					? [`worktree_path=${job.worktree.worktree_path} base_sha=${job.worktree.base_sha} repo_root=${job.worktree.repo_root}`, NOTICE]
					: []),
				...(result.error ? [`error: ${result.error}`] : []),
				...(result.notice ? [`notice: ${result.notice}`] : []),
				result.final_text,
			].join("\n"),
			limit,
		).text;
	};
	const shellExit = (job: Job) => {
		const result = job.result as ShellResult;
		return capped(
			[
				`Background shell job ${job.id} ${job.state}: ${job.task}`,
				`exit_code=${result.exit_code} signal=${result.signal} status=${result.status} duration_ms=${result.duration_ms} cwd=${result.cwd}`,
				`log=${result.log}${result.log_truncated ? " (truncated)" : ""}`,
				...(result.error ? [`error: ${result.error}`] : []),
				...(result.log_error ? [`log_error: output capture failed: ${result.log_error}`] : []),
				"last lines:",
				result.tail,
			].join("\n"),
		).text;
	};
	const message = (entry: Job | Batch, event: "match" | "exit") =>
		"jobs" in entry
			? {
					customType: "delegate-result",
					content: [
						`Background delegate batch ${entry.id} ${entry.state}: ${entry.jobs.length} tasks`,
						...entry.jobs.map((job, i) => section(job, `[${i + 1}] job`, CAP / entry.jobs.length)),
					].join("\n\n"),
					details: { batch_id: entry.id, status: entry.state, job_ids: entry.jobs.map((job) => job.id) },
				}
			: !entry.shell
				? { customType: "delegate-result", content: section(entry, "Background delegate job", CAP), details: { job_id: entry.id, status: entry.state } }
				: {
						customType: "shell-bg",
						content:
							event === "match"
								? capped(`Background shell job ${entry.id} output matched ${JSON.stringify(entry.shell.notify_on)}: ${entry.task}\n${entry.shell.match}`).text
								: shellExit(entry),
						details: { job_id: entry.id, event, status: entry.state },
					};
	// A job's match always goes out before its exit; one send makes Pi busy, so the exit
	// follows on the next idle.
	const flush = () => {
		for (const entry of [...jobs.values(), ...batches.values()]) {
			for (const event of ["match", "exit"] as const) {
				const state = event === "exit" ? entry.notify : "jobs" in entry ? undefined : entry.shell?.matchNotify;
				if (closed || state !== "pending") continue;
				try {
					if (!deps.isIdle()) return;
				} catch {
					return;
				}
				try {
					deps.send({ display: true, ...message(entry, event) }, { deliverAs: "followUp", triggerTurn: true });
					if (event === "exit") entry.notify = "sent";
					else (entry as Job).shell!.matchNotify = "sent";
					evict();
				} catch {
					break;
				}
			}
		}
	};
	const dropLog = (job: Job) => {
		try {
			if (job.shell) rmSync(job.shell.log, { force: true });
			return true;
		} catch { return false; }
	};
	const evict = () => {
		const retainedJobs = [...jobs.values()].filter((job) => job.admitted);
		const retainedBatches = [...batches.values()].filter((batch) => batch.jobs.every((job) => job.admitted));
		let count = retainedJobs.length + retainedBatches.length;
		const top = [...retainedJobs.filter((job) => !job.batch), ...retainedBatches];
		const finished = top.filter(
			(entry) => entry.finished !== undefined && entry.notify !== "pending" &&
				("jobs" in entry ? entry.jobs.every((job) => !live(job)) : !live(entry) && entry.shell?.matchNotify !== "pending"),
		);
		for (const entry of finished) {
			if (count <= RETAINED) break;
			const children = "jobs" in entry ? entry.jobs : [entry];
			if (!children.every(dropLog)) continue;
			count -= children.length + Number("jobs" in entry);
			batches.delete(entry.id);
			for (const job of children) {
				jobs.delete(job.id);
			}
		}
	};
	const admit = (count: number) => {
		if (jobs.size + batches.size + count > BACKLOG)
			throw new Error(`delegate backlog limit: ${jobs.size + batches.size} of ${BACKLOG} entries retained; collect or deliver pending results before starting more jobs`);
	};
	const failure = (job: Job, error: unknown): Result => ({
		final_text: "",
		exit_code: null,
		runner: job.runner as Task["runner"],
		model: job.model,
		cwd: job.cwd,
		duration_ms: 0,
		truncated: false,
		status: "failed",
		error: error instanceof Error ? error.message : String(error),
	});
	const setup = async (task: Prepared & { base?: Base }, job: Job) => {
		if (!task.base || !job.worktree) return task;
		try {
			const cwd = await provision(task.base, job.worktree.worktree_path);
			if (job.controller.signal.aborted) throw new Error("Delegation aborted during worktree setup");
			return { ...task, cwd };
		} catch (error) {
			release();
			throw error;
		}
	};
	const start = (task: Prepared & { base?: Base }, background: boolean, onProgress: () => void, admitted: boolean) => {
		const controller = new AbortController();
		let spawned!: () => void;
		const spawn = new Promise<boolean>((resolve) => (spawned = () => resolve(true)));
		const id = randomBytes(4).toString("hex");
		const job: Job = {
			id,
			admitted,
			...(task.base
				? {
						worktree: {
							worktree_path: worktreePath(task.base.repo_root, id),
							base_sha: task.base.base_sha,
							repo_root: task.base.repo_root,
						},
					}
				: {}),
			task: task.task.split("\n")[0]!.slice(0, 80),
			runner: task.runner,
			model: task.model,
			cwd: task.cwd,
			mode: task.mode ?? "read-only",
			state: "starting",
			...cleanupState(),
			started: Date.now(),
			progress: { turns: 0, tools: [] },
			notify: "none",
			controller,
			generation,
			spawned: false,
			ready: spawn,
			done: Promise.resolve()
				.then(() => setup(task, job))
				.then((ready) =>
					spawnChild(ready, controller.signal, {
						...deps.childHooks,
						...cleanupHooks(job),
						onSpawn: (model) => {
							job.spawned = true;
							job.model = model;
							job.state = "running";
							refresh();
							spawned();
						},
						onProgress: (progress) => {
							if (job.finished || closed) return;
							job.progress = progress;
							onProgress();
						},
					}),
				)
				.catch((error: unknown) => failure(job, error))
				.then((result) => {
					job.finished = Date.now();
					job.result = { job_id: job.id, ...result, ...(job.worktree ? { ...job.worktree, worktree_notice: NOTICE } : {}) };
					job.state = controller.signal.aborted ? "cancelled" : result.status === "failed" ? "failed" : "done";
					if (background && job.spawned && job.state !== "cancelled" && job.generation === generation)
						job.notify = "pending";
					evict();
					refresh();
					flush();
					return result;
				}),
		};
		job.ready = Promise.race([spawn, job.done.then(() => false), job.stalled.then(() => false)]);
		jobs.set(job.id, job);
		return job;
	};
	const group = (children: Job[], background: boolean) => {
		const batch: Batch = {
			id: randomBytes(4).toString("hex"),
			jobs: children,
			state: "running",
			started: Date.now(),
			notify: "none",
			generation,
			cancelled: false,
			done: Promise.all(children.map((job) => job.done)).then(() => {
				const states = children.map((job) => job.state);
				batch.finished = Date.now();
				batch.state =
					batch.cancelled || states.every((s) => s === "cancelled")
						? "cancelled"
						: states.every((s) => s === "done")
							? "done"
							: "failed";
				if (background && batch.state !== "cancelled" && children.some((job) => job.spawned) && batch.generation === generation)
					batch.notify = "pending";
				evict();
				flush();
			}),
		};
		for (const job of children) job.batch = batch.id;
		batches.set(batch.id, batch);
		return batch;
	};
	const open = async (tasks: Task[], cwd: string, background: boolean, grouped: boolean, onUpdate?: (jobs: Job[]) => void) => {
		if (closed) throw new Error("delegate: session is shutting down");
		const pins = new Map<string, string>();
		const prepared = await Promise.all(
			tasks.map((task, i) =>
				prepare(task, cwd)
					.then(async (ready) => (ready.worktree ? { ...ready, base: await locate(ready.cwd, pins) } : ready))
					.catch((error: Error) => {
					throw grouped ? new Error(`tasks[${i}]: ${error.message}`) : error;
				}),
			),
		);
		if (closed) throw new Error("delegate: session is shutting down");
		admit(prepared.length + Number(grouped));
		reserve(prepared.length);
		let updated = 0;
		let timer: ReturnType<typeof setTimeout> | undefined;
		let stopped = false;
		const children: Job[] = [];
		const stopProgress = () => {
			stopped = true;
			clearTimeout(timer);
			progressStops.delete(stopProgress);
		};
		progressStops.add(stopProgress);
		const emit = () => {
			timer = undefined;
			if (stopped || closed) return;
			updated = Date.now();
			onUpdate?.(children);
		};
		const progress = () => {
			if (!onUpdate || stopped || closed) return;
			const remaining = UPDATE_MS - (Date.now() - updated);
			if (remaining <= 0) { clearTimeout(timer); emit(); }
			else timer ??= setTimeout(emit, remaining);
		};
		for (const task of prepared) children.push(start(task, background && !grouped, progress, !background));
		void Promise.all(children.map((job) => job.done)).then(stopProgress);
		return { children, batch: grouped ? group(children, background) : undefined, stopProgress };
	};
	const cancelJob = async (job: Job) => {
		const stuck = job.state === "cleanup_failed";
		if (stuck) Object.assign(job, cleanupState());
		job.controller.abort();
		if (stuck && job.retry && !(await job.retry())) return;
		await Promise.race([job.done, job.stalled]);
	};
	const cancel = async (id: string) => {
		const entry = get(id);
		if (!("jobs" in entry)) {
			await cancelJob(entry);
			return view(entry);
		}
		entry.cancelled = true;
		await Promise.all(entry.jobs.map(cancelJob));
		if (entry.jobs.every((job) => !live(job))) await entry.done;
		return batchView(entry);
	};
	const cancelAll = () => Promise.all([...jobs.values()].filter(live).map((job) => cancel(job.id)));
	const result = (id: string) => {
		const entry = get(id);
		if (entry.notify === "pending") entry.notify = "collected";
		if ("shell" in entry && entry.shell?.matchNotify === "pending") entry.shell.matchNotify = "collected";
		const snapshot = "jobs" in entry ? batchView(entry, true) : view(entry, true);
		evict();
		return snapshot;
	};
	const shell = async (input: ShellInput, cwd: string) => {
		if (closed) throw new Error("delegate: session is shutting down");
		const prepared = await prepareShell(input, cwd);
		if (closed) throw new Error("delegate: session is shutting down");
		admit(1);
		reserveShell();
		const controller = new AbortController();
		const id = randomBytes(4).toString("hex");
		let spawned!: () => void;
		const spawn = new Promise<boolean>((resolve) => (spawned = () => resolve(true)));
		const state: Shell = { log: logPath(id), notify_on: prepared.notify_on, notify_on_exit: prepared.notify_on_exit, matchNotify: "none" };
		const job: Job = {
			id,
			admitted: false,
			task: prepared.command.split("\n")[0]!.slice(0, 80),
			runner: "shell",
			model: "",
			cwd: prepared.cwd,
			mode: "",
			state: "starting",
			...cleanupState(),
			started: Date.now(),
			progress: { turns: 0, tools: [] },
			notify: "none",
			controller,
			generation,
			spawned: false,
			shell: state,
			ready: spawn,
			done: Promise.resolve().then(() => runShell(prepared, id, controller.signal, {
				...deps.shellHooks,
				...cleanupHooks(job),
				onSpawn: () => {
					job.spawned = true;
					job.state = "running";
					refresh();
					spawned();
				},
				onMatch: (line) => {
					state.match = line;
					if (closed || controller.signal.aborted || job.generation !== generation) return;
					state.matchNotify = "pending";
					flush();
				},
			}))
				.catch((error: unknown) => ({ status: "failed" as const, error: error instanceof Error ? error.message : String(error) }))
				.then((outcome) => {
					const result = outcome as ShellResult;
					job.finished = Date.now();
					job.result = { job_id: id, ...result };
					job.state = controller.signal.aborted
						? "cancelled"
						: result.status === "exited" && result.exit_code === 0 && !result.error
							? "done"
							: "failed";
					if (job.state === "cancelled" && state.matchNotify === "pending") state.matchNotify = "none";
					if (state.notify_on_exit && job.spawned && job.state !== "cancelled" && job.generation === generation) job.notify = "pending";
					evict();
					refresh();
					flush();
					return result;
				}),
		};
		job.ready = Promise.race([spawn, job.done.then(() => false), job.stalled.then(() => false)]);
		jobs.set(id, job);
		if (!(await job.ready)) {
			jobs.delete(id);
			dropLog(job);
			throw new Error(JSON.stringify(await job.done));
		}
		job.admitted = true;
		evict();
		return { job_id: id, status: job.state, log: state.log };
	};
	const owners = async () =>
		new Map(
			await Promise.all(
				[...jobs.values()]
					.filter((job) => job.worktree)
					.map(async (job) => [await realpath(job.worktree!.worktree_path).catch(() => job.worktree!.worktree_path), job] as const),
			),
		);
	return {
		flush,
		list: () => [
			...[...jobs.values()].filter((job) => !job.batch).map((job) => view(job)),
			...[...batches.values()].map((batch) => batchView(batch)),
		],
		result,
		cancel,
		shell,
		async tail(id: string, lines = 40) {
			const job = jobs.get(id);
			if (!job?.shell) throw new Error(job ? `delegate job ${id} is not a shell job` : `Unknown delegate job: ${id}`);
			if (!Number.isInteger(lines) || lines < 1 || lines > 500) throw new Error("lines must be an integer from 1 to 500");
			return { job_id: id, state: job.state, log: job.shell.log, text: await tail(job.shell.log, lines) };
		},
		async listWorktrees() {
			const owned = await owners();
			return (await listWorktrees()).map((entry) => {
				const job = owned.get(entry.path);
				return { ...entry, job_id: job?.id ?? null, live_job: job ? live(job) : false };
			});
		},
		async removeWorktree(id: string | undefined, path: string | undefined, force = false) {
			if ((id === undefined) === (path === undefined)) throw new Error("remove_worktree takes exactly one of job_id or path");
			if (id !== undefined) {
				const job = jobs.get(id);
				if (!job) throw new Error(batches.has(id) ? "remove_worktree takes a job id, not a batch id" : `Unknown delegate job: ${id}`);
				if (!job.worktree) throw new Error(`delegate job ${id} has no worktree`);
				path = job.worktree.worktree_path;
			}
			const target = await resolveWorktree(path!);
			const job = (await owners()).get(target.path);
			if (job && live(job)) throw new Error(`delegate job ${job.id} is ${job.state}; its worktree can be removed once it finishes`);
			if (job?.result?.unkilled_pids?.length)
				throw new Error(`delegate job ${job.id} left surviving pids ${job.result.unkilled_pids.join(" ")}; refusing to remove its worktree`);
			const holders = await cwdHolders(target.path);
			if (holders.length) throw new Error(`processes ${holders.join(" ")} have their cwd inside ${target.path}; refusing to remove it`);
			return { ...(job ? { job_id: job.id } : {}), ...(await removeWorktree(target.common_git_dir, target.path, force)) };
		},
		async run(tasks: Task[], cwd: string, grouped: boolean, signal?: AbortSignal, onUpdate?: (jobs: Job[]) => void) {
			const { children, batch, stopProgress } = await open(tasks, cwd, false, grouped, onUpdate);
			const abort = () => children.forEach((job) => job.controller.abort());
			signal?.addEventListener("abort", abort, { once: true });
			if (signal?.aborted) abort();
			try {
				await Promise.all(children.map((job) => Promise.race([job.done, job.stalled])));
				if (children.every((job) => !live(job))) await batch?.done;
			} finally {
				signal?.removeEventListener("abort", abort);
				stopProgress();
			}
			return batch ? batchView(batch, true) : children[0]!.result ?? view(children[0]!, true);
		},
		async launch(tasks: Task[], cwd: string, grouped: boolean) {
			const { children, batch } = await open(tasks, cwd, true, grouped);
			const ready = await Promise.all(children.map((job) => job.ready));
			if (ready.some(Boolean) || children.some((job) => job.state === "cleanup_failed")) {
				for (const job of children) job.admitted = true;
				evict();
				const handles = children.map((job) => ({ job_id: job.id, status: job.state }));
				return batch ? { batch_id: batch.id, jobs: handles } : handles[0]!;
			}
			await batch?.done;
			const failed = batch ? batchView(batch, true) : await children[0]!.done;
			if (batch) batches.delete(batch.id);
			for (const job of children) jobs.delete(job.id);
			throw new Error(JSON.stringify(failed));
		},
		async wait(id: string, timeout_s = 600, signal?: AbortSignal) {
			const entry = get(id);
			const stop = new AbortController();
			const abort = () => stop.abort();
			signal?.addEventListener("abort", abort, { once: true });
			if (signal?.aborted) abort();
			try {
				await Promise.race([
					entry.done,
					sleep(timeout_s * 1000, undefined, { signal: stop.signal }).catch(() => {}),
				]);
			} finally {
				stop.abort();
				signal?.removeEventListener("abort", abort);
			}
			if (signal?.aborted) throw new Error("delegate_jobs wait aborted");
			return result(id);
		},
		async reset() {
			generation++;
			for (const stop of progressStops) stop();
			for (const entry of [...jobs.values(), ...batches.values()]) {
				if (entry.notify === "pending") entry.notify = "none";
				if ("shell" in entry && entry.shell?.matchNotify === "pending") entry.shell.matchNotify = "none";
			}
			await cancelAll();
		},
		async close() {
			closed = true;
			for (const stop of progressStops) stop();
			try {
				deps.status(undefined);
			} catch {}
			await cancelAll();
			if ([...jobs.values()].some(live)) throw new Error(`delegate cleanup incomplete: ${JSON.stringify([...jobs.values()].filter(live).map((job) => view(job)))}`);
			for (const job of jobs.values()) dropLog(job);
			await pruneEmpty(dirname(logPath("x")));
		},
	};
}

export default function (pi: ExtensionAPI) {
	let ctx: ExtensionContext | undefined;
	const jobs = createJobs({
		send: (message, options) => pi.sendMessage(message, options),
		isIdle: () => ctx?.isIdle() ?? false,
		status: (text) => {
			if (ctx?.hasUI) ctx.ui.setStatus("delegate", text);
		},
	});
	// Compaction events fire before Pi clears its compacting flag, so re-check on a later tick.
	const flushLater = (_event: unknown, next: ExtensionContext) => {
		ctx = next;
		setTimeout(jobs.flush, 0);
	};
	pi.on("agent_settled", (_event, next) => {
		ctx = next;
		jobs.flush();
	});
	pi.on("session_compact", flushLater);
	pi.on("session_compact_failed", flushLater);
	pi.on("session_shutdown", () => jobs.close());
	pi.on("session_tree", () => jobs.reset());
	pi.registerTool({
		name: "delegate",
		label: "Delegate",
		description:
			"Launch a fresh Pi, Codex or agy (Gemini) child receiving only the task, never parent conversation, reasoning, history, fork or resume state; supply a self-contained task and do not work around this boundary. Give task, or tasks for up to two independent children run in parallel. Defaults to read-only, 600s; rejects a third concurrent child, background jobs included. AGENTS.md rules remain enabled; this is not filesystem read isolation.",
		parameters,
		async execute(_id, params, signal, onUpdate, next) {
			ctx = next;
			const { tasks, background, ...top } = params;
			if ((params.task === undefined) === (tasks === undefined))
				throw new Error("delegate: supply exactly one of task or tasks");
			if (tasks && (tasks.length < 1 || tasks.length > 2)) throw new Error("delegate: tasks must hold 1 or 2 tasks");
			const grouped = tasks !== undefined;
			const list = (tasks ?? [{}]).map((task) => ({ ...top, ...task }) as Task);
			if (background) {
				const handle = await jobs.launch(list, next.cwd, grouped);
				return { content: [{ type: "text", text: JSON.stringify(handle) }], details: handle };
			}
			const result = await jobs.run(list, next.cwd, grouped, signal, (children) =>
				onUpdate?.(
					grouped
						? {
								content: [
									{ type: "text", text: children.map((job, i) => `[${i + 1}] ${summary(job.progress)}`).join(" | ") },
								],
								details: { jobs: children.map((job) => ({ job_id: job.id, ...job.progress })) },
							}
						: { content: [{ type: "text", text: summary(children[0]!.progress) }], details: children[0]!.progress },
				),
			);
			if ("status" in result ? result.status === "failed" : "jobs" in result ? result.jobs.every((job) => job.state !== "done") : result.state === "cleanup_failed")
				throw new Error(JSON.stringify(result));
			return { content: [{ type: "text", text: JSON.stringify(result) }], details: result };
		},
	});
	pi.registerTool({
		name: "shell_bg",
		label: "Background shell",
		description: `Run a shell command in the background with bash -c; returns { job_id, status, log } once started. Not a model child: it inherits the parent's full environment and takes no delegate slot (at most ${MAX_SHELLS} running). Output goes to a log capped at ${LOG_CAP / 1024 / 1024} MiB. Its process tree is killed when the command exits, times out or is cancelled. Manage it with delegate_jobs list, tail, result, wait, cancel.`,
		parameters: shellParameters,
		async execute(_id, params, _signal, _onUpdate, next) {
			ctx = next;
			const handle = await jobs.shell(params, next.cwd);
			return { content: [{ type: "text", text: JSON.stringify(handle) }], details: handle };
		},
	});
	pi.registerTool({
		name: "delegate_jobs",
		label: "Delegate jobs",
		description:
			"Delegate and shell_bg jobs of this session: list; result (retained result of a finished job or batch); cancel (kills its process trees); wait (until done or timeout_s, then result); tail (last lines of a shell job's log); list_worktrees (all pi-delegate worktrees, from any session); remove_worktree (by job_id or path; refuses while its job runs, a process has its cwd inside, or it has uncommitted changes unless force).",
		parameters: jobParameters,
		async execute(_id, params, signal, _onUpdate, next) {
			ctx = next;
			const id = params.job_id ?? "";
			const out =
				params.action === "list"
					? jobs.list()
					: params.action === "result"
						? jobs.result(id)
						: params.action === "cancel"
							? await jobs.cancel(id)
							: params.action === "tail"
								? await jobs.tail(id, params.lines)
								: params.action === "list_worktrees"
									? await jobs.listWorktrees()
									: params.action === "remove_worktree"
										? await jobs.removeWorktree(params.job_id, params.path, params.force)
										: await jobs.wait(id, params.timeout_s, signal);
			return { content: [{ type: "text", text: JSON.stringify(out) }], details: out };
		},
	});
	pi.registerCommand("delegate", {
		description: "List delegate and shell jobs, or /delegate cancel <id>",
		handler: async (args, next) => {
			ctx = next;
			const [verb, id] = args.trim().split(/\s+/);
			const line = (j: {
				job_id: string;
				state: string;
				runner?: string;
				elapsed_ms: number;
				progress?: string;
				command?: string;
				worktree_path?: string;
				cleanup_error?: string;
				unkilled_pids?: number[];
			}) =>
				`${j.job_id} ${j.state} ${j.runner ?? "shell"} ${Math.round(j.elapsed_ms / 1000)}s ${j.progress ?? j.command}${j.worktree_path ? ` worktree=${j.worktree_path}` : ""}${j.cleanup_error ? ` pids=${j.unkilled_pids?.join(" ")} cleanup_error=${j.cleanup_error}` : ""}`;
			try {
				const text =
					verb === "cancel"
						? JSON.stringify(await jobs.cancel(id ?? ""))
						: jobs
								.list()
								.map((entry) =>
									"batch_id" in entry
										? [`batch ${entry.batch_id} ${entry.state}`, ...entry.jobs.map((j) => `  ${line(j)}`)].join("\n")
										: line(entry),
								)
								.join("\n") || "No delegate jobs";
				next.ui.notify(text, "info");
			} catch (error) {
				next.ui.notify(String(error), "error");
			}
		},
	});
}
