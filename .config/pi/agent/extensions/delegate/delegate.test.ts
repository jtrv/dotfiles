import { test } from "node:test";
import assert from "node:assert/strict";
import { setTimeout as sleep } from "node:timers/promises";
import { existsSync, writeSync, writeFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { chmod, mkdir, mkdtemp, readdir, stat, symlink, writeFile, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { lineMatcher } from "./shell.ts";
import { git, pruneEmpty, locate, provision, worktreePath, listWorktrees, removeWorktree } from "./worktree.ts";
import { AGY_TASK_BYTES, checkAgyGate, geminiDir } from "./agy.ts";
import { prepare, reserve, release } from "./child.ts";
import { seedRoot, terminate, tree } from "./supervise.ts";
import extension, { BACKLOG, createJobs, buildArgs, lineSplitter, runDelegate, trackProgress, type Progress } from "../delegate.ts";

// Recorded from `codex exec --json` (gpt-5.6-luna, task "run echo hi, reply JSON-OK") on this
// machine; thread id and token usage removed.
const codexEvents = `{"type":"thread.started"}
{"type":"turn.started"}
{"type":"item.started","item":{"id":"item_0","type":"command_execution","command":"/usr/sbin/bash -lc 'echo hi'","aggregated_output":"","exit_code":null,"status":"in_progress"}}
{"type":"item.completed","item":{"id":"item_0","type":"command_execution","command":"/usr/sbin/bash -lc 'echo hi'","aggregated_output":"hi\\n","exit_code":0,"status":"completed"}}
{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"JSON-OK"}}
{"type":"turn.completed"}
`;

// Recorded from \`agy --output-format=stream-json\` (task "read sub/a.txt, run echo TOOL-RAN") on
// this machine; conversation ids, usage and text deltas removed.
const agyEvents = `{"event":"init","conversation_id":"c","init":{"cwd":"/tmp","tools":["run_command","view_file"],"permission_mode":"always-proceed"}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":0,"state":"DONE","step_type":"user_input"}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":1,"state":"DONE","step_type":"agent_response"}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":2,"state":"ACTIVE","step_type":"tool","tool_name":"view_file","tool_info":{"name":"view_file","parameters":{"AbsolutePath":"/tmp/ws/sub/a.txt"}}}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":2,"state":"DONE","step_type":"tool","tool_name":"view_file","duration_seconds":0.01,"tool_info":{"name":"view_file","parameters":{"AbsolutePath":"/tmp/ws/sub/a.txt"}}}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":3,"state":"ACTIVE","step_type":"tool","tool_name":"run_command","tool_info":{"name":"run_command","parameters":{"CommandLine":"echo TOOL-RAN"}}}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":3,"state":"ERROR","step_type":"tool","tool_name":"run_command","tool_info":{"name":"run_command","parameters":{"CommandLine":"echo TOOL-RAN"}}}}
{"event":"step_update","step_update":{"conversation_id":"c","step_index":4,"state":"DONE","step_type":"agent_response","text_delta":"DONE alpha beta TOOL-RAN\\n"}}
{"event":"result","result":{"conversation_id":"c","status":"SUCCESS","response":"DONE alpha beta TOOL-RAN\\n","duration_seconds":20.5,"num_turns":1}}
`;

const script = `#!${process.execPath}
import { spawn } from 'node:child_process';
import { existsSync, writeFileSync, readFileSync } from 'node:fs';
const args = process.argv.slice(2);
const agy = args.includes('--output-format=stream-json');
const task = agy ? args.find((arg) => arg.startsWith('-p=')).slice(3) : readFileSync(0, 'utf8');
writeFileSync('received.json', JSON.stringify({ task, args, inherited: process.env.PARENT_SESSION, mode: process.env.PI_DELEGATE_MODE, git: [process.env.GIT_CONFIG_COUNT, process.env.GIT_CONFIG_KEY_0, process.env.GIT_CONFIG_VALUE_0] }));
writeFileSync('stdin-' + process.pid, task);
const detached = (code, env) => {
 const child = spawn(process.execPath, ['-e', code], { detached: true, stdio: 'ignore', env });
 writeFileSync('grandchild', String(child.pid));
 return child;
};
const answer = (text) => agy
 ? JSON.stringify({ event: 'result', result: { status: 'SUCCESS', response: text } })
 : JSON.stringify({ type: 'message_end', message: { role: 'assistant', stopReason: 'stop', content: [{ type: 'text', text }] } });
if (task === 'sleep') {
 const child = spawn('sleep', ['60'], { stdio: 'ignore' });
 writeFileSync('grandchild', String(child.pid));
 setInterval(() => {}, 1000);
} else if (task === 'stubborn') {
 detached("process.on('SIGTERM', () => {}); require('fs').writeFileSync('ready', ''); setInterval(() => {}, 1000);", {});
 setInterval(() => {}, 1000);
} else if (task === 'polite') {
 detached("process.on('SIGTERM', () => { require('fs').writeFileSync('termed', 'SIGTERM'); process.exit(0); }); require('fs').writeFileSync('ready', ''); setInterval(() => {}, 1000);", {});
 setInterval(() => {}, 1000);
} else if (task === 'orphan') {
 detached("setInterval(() => {}, 1000);", process.env).unref();
 writeFileSync(1, answer('done'));
} else if (task === 'pipe-orphan') {
 const child = spawn('sleep', ['30'], { detached: true, stdio: ['ignore', 1, 2] });
 writeFileSync('pipe-orphan.pid', String(child.pid));
 child.unref();
 if (args[0] === 'exec') writeFileSync(args[args.indexOf('--output-last-message') + 1], 'pipe-answer');
 else writeFileSync(1, answer('pipe-answer'));
} else if (task === 'trailing') {
 process.stdout.write('{"type":"turn_start"}\\n{"type":"tool_execution_start","toolCallId":"a","toolName":"long-tool"}\\n');
 setTimeout(() => writeFileSync(1, answer('trailing-answer')), 1000);
} else if (task === 'slow') {
 setTimeout(() => writeFileSync(1, answer('slow')), 300);
} else if (task === 'progress') {
 process.stdout.write('{"type":"turn_start"}\\n{"type":"tool_execution_start","toolCallId":"a","toolName":"read"}\\n{"type":"tool_exec');
 setTimeout(() => process.stdout.write('ution_start","toolCallId":"b","toolName":"bash"}\\nnot json\\n{"type":"tool_execution_end","toolCallId":"a"}\\n{"type":"tool_execution_end","toolCallId":"b"}\\n' + answer('progressed')), 50);
} else if (task.startsWith('ordered-first ')) {
 const timer = setInterval(() => {
  if (!existsSync('second-answer')) return;
  clearInterval(timer);
  writeFileSync('first-saw-second', 'yes');
  writeFileSync(1, answer('FIRST'));
 }, 10);
} else if (task.startsWith('ordered-second ')) {
 writeFileSync(args[args.indexOf('--output-last-message') + 1], 'SECOND');
 writeFileSync('second-answer', 'ready');
} else if (task === 'bypass') {
 process.stdout.write(JSON.stringify({ event: 'step_update', step_update: { step_type: 'tool', state: 'ACTIVE', tool_info: { parameters: { BypassSandbox: true } } } }) + '\\n');
 writeFileSync(1, answer('bypassed'));
} else if (task.startsWith('after ')) {
 const [, ms, text] = /^after (\\d+) (\\S+)/.exec(task);
 setTimeout(() => args[0] === 'exec' ? writeFileSync(args[args.indexOf('--output-last-message') + 1], text) : writeFileSync(1, answer(text)), Number(ms));
} else if (task === 'codexjson') {
 writeFileSync(args[args.indexOf('--output-last-message') + 1], 'JSON-OK');
 process.stdout.write(${JSON.stringify(codexEvents)});
} else {
 if (task === 'empty') process.exit(0);
 const text = task === 'large' ? '界'.repeat(20000) : task === 'cwd' ? process.cwd() : task;
 if (args[0] === 'exec') writeFileSync(args[args.indexOf('--output-last-message') + 1], text);
 else if (agy) writeFileSync(1, task === 'auth' ? JSON.stringify({ event: 'result', result: { status: 'ERROR', error: 'auth failed', response: '' } }) : answer(text));
 else writeFileSync(1, JSON.stringify({ type: 'message_end', message: { role: 'assistant', stopReason: task === 'auth' ? 'error' : 'stop', errorMessage: 'auth failed', content: [{ type: 'text', text }] } }));
 if (task === 'fail') process.exitCode = 7;
}
`;

async function withFakes(body: (dir: string) => Promise<void>) {
	const dir = await mkdtemp(join(tmpdir(), "delegate-test-"));
	const oldPath = process.env.PATH;
	const oldConfig = process.env.XDG_CONFIG_HOME;
	try {
		for (const runner of ["pi", "codex", "agy"] as const) await writeFile(join(dir, runner), script, { mode: 0o755 });
		process.env.PATH = `${dir}:${oldPath}`;
		process.env.XDG_CONFIG_HOME = join(dir, "config-home");
		await mkdir(join(process.env.XDG_CONFIG_HOME, "gemini", "config"), { recursive: true });
		const hook = join(dir, "agy-pretool.sh");
		await writeFile(hook, "#!/bin/sh\nexit 0\n", { mode: 0o755 });
		await writeFile(join(process.env.XDG_CONFIG_HOME, "gemini", "config", "hooks.json"), JSON.stringify({ gate: { PreToolUse: [{ matcher: "*", hooks: [{ command: `bash ${hook}` }] }] } }));
		process.env.PARENT_SESSION = "must-not-inherit";
		await body(dir);
	} finally {
		process.env.PATH = oldPath;
		if (oldConfig === undefined) delete process.env.XDG_CONFIG_HOME;
		else process.env.XDG_CONFIG_HOME = oldConfig;
		delete process.env.PARENT_SESSION;
		await rm(dir, { recursive: true, force: true });
	}
}

async function until(check: () => boolean | Promise<boolean>) {
	for (let i = 0; i < 150; i++) {
		if (await check()) return;
		await sleep(20);
	}
	assert.fail("condition did not become true within 3 seconds");
}

const alive = async (pid: number) => {
	try {
		return (await readFile(`/proc/${pid}/stat`, "utf8")).split(") ")[1]!.split(" ")[0] !== "Z";
	} catch {
		return false;
	}
};
const ready = async (dir: string) => {
	for (let i = 0; i < 100 && !existsSync(join(dir, "ready")); i++) await sleep(20);
	return Number(await readFile(join(dir, "grandchild"), "utf8"));
};

function harness(dir: string, shutdowns: (() => Promise<void>)[], hooks: { isIdle: () => boolean; send?: () => void }) {
	const handlers = new Map<string, (event: unknown, ctx: unknown) => unknown>();
	const tools = new Map<string, { execute: (...args: unknown[]) => Promise<{ details: any }> }>();
	const commands = new Map<string, { handler: (args: string, ctx: unknown) => Promise<void> }>();
	const sent: { message: any; options: any }[] = [];
	const status: (string | undefined)[] = [];
	const notes: string[] = [];
	const ctx = {
		cwd: dir,
		hasUI: true,
		isIdle: hooks.isIdle,
		ui: { setStatus: (_key: string, text?: string) => status.push(text), notify: (text: string) => notes.push(text) },
	};
	extension({
		on: (name: string, handler: never) => handlers.set(name, handler),
		registerTool: (tool: never) => tools.set((tool as { name: string }).name, tool),
		registerCommand: (name: string, command: never) => commands.set(name, command),
		sendMessage: (message: unknown, options: unknown) => {
			hooks.send?.();
			sent.push({ message, options });
		},
	} as never);
	const call = async (name: string, params: object, signal?: AbortSignal, onUpdate?: unknown) =>
		(await tools.get(name)!.execute("call", params, signal, onUpdate, ctx)).details;
	const emit = async (name: string) => {
		await handlers.get(name)!({}, ctx);
		await sleep(10);
	};
	const find = (id: string) => call("delegate_jobs", { action: "list" }).then((list) => list.find((job: any) => job.job_id === id));
	const state = (id: string) => find(id).then((job) => job?.state);
	shutdowns.push(() => emit("session_shutdown"));
	const reach = async (id: string, want: string) => {
		for (let i = 0; i < 250 && (await state(id)) !== want; i++) await sleep(20);
		assert.equal(await state(id), want);
	};
	return { call, emit, sent, status, notes, commands, ctx, find, state, reach };
}

	test("stdin, flags, final capture, failures, caps, process trees and concurrency", { timeout: 60_000 }, () =>
		withFakes(async (dir) => {
			for (const runner of ["pi", "codex", "agy"] as const) {
				const task = "literal ' \" $(touch PWNED); `id` & | > <\nlast line\n";
				const result = await runDelegate({ runner, task }, dir);
				assert.equal(result.status, "answered");
				assert.equal(result.final_text, task);
				const received = JSON.parse(await readFile(join(dir, "received.json"), "utf8"));
				assert.equal(received.task, task);
				assert.equal(received.inherited, undefined);
				assert.equal(received.mode, "read-only");
				assert.deepEqual(received.git, ["1", "commit.gpgsign", "false"]);
				// agy takes the prompt as an argument; the others must never see it there.
				assert.equal(received.args.includes(task), false);
				assert.equal(received.args.includes(`-p=${task}`), runner === "agy");
				const expected = {
					pi: ["-p", "--no-session", "--no-extensions", "--no-skills", "--no-prompt-templates", "--provider", "openai-codex", "--model", "gpt-5.6-sol", "--mode", "json", "--tools", "read,grep,find,ls"],
					codex: ["exec", "--skip-git-repo-check", "-m", "gpt-5.6-terra", "-C", dir, "--sandbox", "read-only", "--ephemeral", "--json", "--output-last-message", received.args.at(-2), "-"],
					agy: [`--gemini_dir=${process.env.XDG_CONFIG_HOME}/gemini`, "--sandbox", "--dangerously-skip-permissions", "--output-format=stream-json", "--print-timeout=600s", `-p=${task}`],
				};
				assert.deepEqual(received.args, expected[runner]);
				assert.ok(!received.args.includes("sh"));
				assert.ok(received.args?.includes({ pi: "--no-extensions", codex: "--ephemeral", agy: "--sandbox" }[runner]));
				if (runner !== "agy") assert.ok(received.args?.includes(runner === "pi" ? "read,grep,find,ls" : "read-only"));
				const large = await runDelegate({ runner, task: "large" }, dir);
				assert.equal(large.truncated, true);
				assert.ok(Buffer.byteLength(large.final_text) <= 32768);
				assert.ok(!large.final_text.includes("�"));
				assert.equal((await runDelegate({ runner, task: "fail" }, dir)).status, "failed");
				assert.equal((await runDelegate({ runner, task: "empty" }, dir)).status, "failed");
			}
			assert.equal((await runDelegate({ runner: "pi", task: "auth" }, dir)).status, "failed");
			assert.match((await runDelegate({ runner: "agy", task: "auth" }, dir)).error ?? "", /auth failed/);
			assert.throws(() => buildArgs({ runner: "agy", task: "x", model: "claude-opus-4-6-thinking" }, dir, ""), /Invalid agy model/);
			assert.ok(buildArgs({ runner: "agy", task: "x", model: "gemini-3.1-pro-high", timeout_s: 90 }, dir, "").args.includes("--print-timeout=90s"));
			for (const cancel of [false, true]) {
				const controller = new AbortController();
				const launchDir = await mkdtemp(join(dir, "sleep-"));
				const job = runDelegate({ runner: "pi", task: "sleep", timeout_s: 5 }, launchDir, controller.signal);
				await until(() => existsSync(join(launchDir, "grandchild")));
				const pid = Number(await readFile(join(launchDir, "grandchild"), "utf8"));
				assert.equal(await alive(pid), true);
				const identity = (await readFile(`/proc/${pid}/stat`, "utf8")).split(") ")[1]!.split(" ")[19];
				if (cancel) controller.abort();
				assert.ok((await job).error?.includes(cancel ? "aborted" : "timed out"));
				const after = await readFile(`/proc/${pid}/stat`, "utf8").catch(() => "");
				assert.ok(!after || after.split(") ")[1]!.split(" ")[19] !== identity || after.split(") ")[1]!.startsWith("Z "));
				await sleep(50);
				let state = "gone";
				try {
					state = (await readFile(`/proc/${pid}/stat`, "utf8")).split(") ")[1]!.split(" ")[0]!;
				} catch {}
				assert.ok(["gone", "Z"]?.includes(state));
			}
			for (const cancel of [false, true]) {
				await rm(join(dir, "ready"), { force: true });
				const controller = new AbortController();
				const job = runDelegate(
					{ runner: "pi", task: "stubborn", timeout_s: cancel ? 30 : 0.5 },
					dir,
					controller.signal,
				);
				const pid = await ready(dir);
				assert.ok(await alive(pid));
				if (cancel) controller.abort();
				const result = await job;
				assert.ok(result.error?.includes(cancel ? "aborted" : "timed out"));
				assert.equal(await alive(pid), false);
				assert.equal(result.unkilled_pids, undefined);
			}
			await rm(join(dir, "ready"), { force: true });
			const polite = runDelegate({ runner: "pi", task: "polite", timeout_s: 30 }, dir, AbortSignal.timeout(500));
			const politePid = await ready(dir);
			assert.ok((await polite).error?.includes("aborted"));
			assert.equal(await readFile(join(dir, "termed"), "utf8"), "SIGTERM");
			assert.equal(await alive(politePid), false);
			const orphan = await runDelegate({ runner: "pi", task: "orphan" }, dir);
			assert.equal(orphan.status, "answered");
			assert.equal(await alive(Number(await readFile(join(dir, "grandchild"), "utf8"))), false);
			const jobs = [1, 2].map(() => runDelegate({ runner: "pi", task: "sleep", timeout_s: 0.3 }, dir));
			await sleep(100);
			await assert.rejects(runDelegate({ runner: "pi", task: "third" }, dir), /concurrency limit/);
			await Promise.all(jobs);
			assert.throws(() => buildArgs({ runner: "codex", task: "x", model: "bad" }, dir, "out"), /Invalid Codex model/);
		}),
	);

	test("event line splitting and progress tracking", () => {
		const seen: string[] = [];
		let oversize = 0;
		const lines = lineSplitter((line) => seen.push(line), () => oversize++, 10);
		lines.push('{"a"');
		lines.push(":1}\nb\nc");
		lines.push("0123456789ABC");
		lines.push("DEF\nd\n0123456789ABCDEF\ne");
		lines.end();
		assert.deepEqual(seen, ['{"a":1}', "b", "d", "e"]);
		assert.equal(oversize, 2);
		const pi = { turns: 0, tools: new Map<string, string>() };
		for (const event of [
			{ type: "turn_start" },
			{ type: "tool_execution_start", toolCallId: "1", toolName: "read" },
			{ type: "tool_execution_start", toolCallId: "2", toolName: "bash" },
			{ type: "tool_execution_end", toolCallId: "1" },
			{ type: "message_update" },
		])
			trackProgress("pi", event, pi);
		assert.deepEqual([pi.turns, [...pi.tools.values()]], [1, ["bash"]]);
		const codex = { turns: 0, tools: new Map<string, string>() };
		const snapshots = codexEvents
			.trim()
			.split("\n")
			.map((line) => (trackProgress("codex", JSON.parse(line), codex), [...codex.tools.values()]));
		assert.deepEqual(snapshots[2], ["/usr/sbin/bash -lc 'echo hi'"]);
		assert.deepEqual([codex.turns, codex.tools.size], [1, 0]);
		const agy = { turns: 0, tools: new Map<string, string>() };
		const agySnapshots = agyEvents
			.trim()
			.split("\n")
			.map((line) => (trackProgress("agy", JSON.parse(line), agy), [...agy.tools.values()]));
		assert.deepEqual(agySnapshots[3], ["view_file /tmp/ws/sub/a.txt"]);
		assert.deepEqual(agySnapshots[5], ["run_command echo TOOL-RAN"]);
		assert.deepEqual([agy.turns, agy.tools.size], [2, 0]);
	});

	test("background jobs, batches, progress, delivery, capacity and lifecycle", { timeout: 60_000 }, () =>
		withFakes(async (dir) => {
			const rejections: unknown[] = [];
			const onRejection = (reason: unknown) => rejections.push(reason);
			process.on("unhandledRejection", onRejection);
			const shutdowns: (() => Promise<void>)[] = [];
			try {
				let idle = false;
				let throwSend = false;
				const instance = () =>
					harness(dir, shutdowns, {
						isIdle: () => idle,
						send: () => {
							if (throwSend) throw new Error("send failed");
						},
					});
				const a = instance();

				const handle = await a.call("delegate", { runner: "pi", task: "quick\nsecond line", background: true });
				assert.deepEqual(Object.keys(handle), ["job_id", "status"]);
				assert.equal(handle.status, "running");
				await a.reach(handle.job_id, "done");
				await a.emit("session_compact");
				await a.emit("agent_settled");
				assert.equal(a.sent.length, 0);
				assert.deepEqual(a.status.at(-2), "delegate: 1 running");
				assert.equal(a.status.at(-1), undefined);
				idle = true;
				throwSend = true;
				await a.emit("agent_settled");
				throwSend = false;
				assert.equal(a.sent.length, 0);
				await a.emit("session_compact_failed");
				await a.emit("agent_settled");
				assert.equal(a.sent.length, 1);
				const [{ message, options }] = a.sent;
				assert.deepEqual(options, { deliverAs: "followUp", triggerTurn: true });
				assert.equal(message.customType, "delegate-result");
				assert.equal(message.display, true);
				assert.deepEqual(message.details, { job_id: handle.job_id, status: "done" });
				assert.match(message.content, new RegExp(`job ${handle.job_id} done: quick\n`));
				assert.match(message.content, /quick\nsecond line$/);
				idle = false;

				const path = process.env.PATH;
				process.env.PATH = join(dir, "missing");
				try {
					for (let i = 0; i < 3; i++)
						await assert.rejects(a.call("delegate", { runner: "codex", task: "x", background: true }), /ENOENT|not found/);
				} finally {
					process.env.PATH = path;
				}
				assert.equal((await a.call("delegate_jobs", { action: "list" })).length, 1);

				await rm(join(dir, "ready"), { force: true });
				const stubborn = await a.call("delegate", { runner: "pi", task: "stubborn", background: true, timeout_s: 30 });
				const stubbornPid = await ready(dir);
				const second = await a.call("delegate", { runner: "pi", task: "sleep", background: true, timeout_s: 30 });
				await assert.rejects(a.call("delegate", { runner: "pi", task: "third" }), /concurrency limit/);
				await a.call("delegate_jobs", { action: "cancel", job_id: second.job_id });
				const cancelling = a.call("delegate_jobs", { action: "cancel", job_id: stubborn.job_id });
				await sleep(300);
				assert.ok(await alive(stubbornPid));
				const slow = await a.call("delegate", { runner: "pi", task: "slow", background: true });
				await assert.rejects(a.call("delegate", { runner: "pi", task: "third" }), /concurrency limit/);
				const cancelled = await cancelling;
				assert.equal(cancelled.state, "cancelled");
				assert.equal(await alive(stubbornPid), false);
				const waited = await a.call("delegate_jobs", { action: "wait", job_id: slow.job_id });
				assert.equal(waited.state, "done");
				assert.equal(waited.result.final_text, "slow");
				const failed = await a.call("delegate", { runner: "pi", task: "fail", background: true });
				await a.reach(failed.job_id, "failed");
				const retained = await a.call("delegate_jobs", { action: "result", job_id: failed.job_id });
				assert.equal(retained.state, "failed");
				assert.equal(retained.result.status, "failed");
				assert.match(retained.result.error, /exited 7/);
				idle = true;
				await a.emit("agent_settled");
				assert.equal(a.sent.length, 1);
				idle = false;

				const sleeper = await a.call("delegate", { runner: "pi", task: "sleep", background: true, timeout_s: 30 });
				assert.equal((await a.call("delegate_jobs", { action: "wait", job_id: sleeper.job_id, timeout_s: 0.1 })).state, "running");
				const started = Date.now();
				await assert.rejects(
					a.call("delegate_jobs", { action: "wait", job_id: sleeper.job_id }, AbortSignal.timeout(100)),
					/aborted/,
				);
				assert.ok(Date.now() - started < 1000);
				await a.commands.get("delegate")!.handler("", a.ctx);
				assert.match(a.notes.at(-1)!, new RegExp(`${sleeper.job_id} running pi \\d+s turn 0`));
				await a.commands.get("delegate")!.handler(`cancel ${sleeper.job_id}`, a.ctx);
				assert.equal(await a.state(sleeper.job_id), "cancelled");

				const updates: Progress[] = [];
				const foreground = await a.call("delegate", { runner: "pi", task: "progress" }, undefined, (update: any) =>
					updates.push(update.details),
				);
				assert.equal(foreground.final_text, "progressed");
				assert.match(foreground.job_id, /^[0-9a-f]{8}$/);
				assert.deepEqual(updates[0], { turns: 1, tools: [] });
				const stoppedUpdates = updates.length;
				await sleep(600);
				assert.equal(updates.length, stoppedUpdates);
				const seen: Progress[] = [];
				const progressed = await runDelegate({ runner: "pi", task: "progress" }, dir, undefined, {
					onProgress: (p) => seen.push(p),
				});
				assert.equal(progressed.final_text, "progressed");
				assert.deepEqual(seen.map((p) => p.tools), [[], ["read"], ["read", "bash"], ["bash"], []]);
				const codexSeen: Progress[] = [];
				const codex = await runDelegate({ runner: "codex", task: "codexjson" }, dir, undefined, {
					onProgress: (p) => codexSeen.push(p),
				});
				assert.equal(codex.final_text, "JSON-OK");
				assert.deepEqual(codexSeen.at(-2), { turns: 1, tools: ["/usr/sbin/bash -lc 'echo hi'"] });
				assert.deepEqual(codexSeen.at(-1), { turns: 1, tools: [] });

				for (const event of ["session_shutdown", "session_tree"]) {
					const b = instance();
					const pending = await b.call("delegate", { runner: "pi", task: "quick", background: true });
					await b.reach(pending.job_id, "done");
					await rm(join(dir, "ready"), { force: true });
					const running = await b.call("delegate", { runner: "pi", task: "stubborn", background: true, timeout_s: 30 });
					const pid = await ready(dir);
					await b.emit(event);
					assert.equal(await alive(pid), false);
					assert.equal(await b.state(running.job_id), "cancelled");
					assert.equal(b.status.at(-1), undefined);
					idle = true;
					await b.emit("agent_settled");
					assert.equal(b.sent.length, 0);
					idle = false;
					if (event === "session_shutdown") {
						await assert.rejects(b.call("delegate", { runner: "pi", task: "quick", background: true }), /shutting down/);
					} else {
						const after = await b.call("delegate", { runner: "pi", task: "quick", background: true });
						await b.reach(after.job_id, "done");
						idle = true;
						await b.emit("agent_settled");
						idle = false;
						assert.deepEqual(b.sent.map((s) => s.message.details.job_id), [after.job_id]);
					}
				}
				const c = instance();
				const sub = async (name: string) => {
					await mkdir(join(dir, name), { recursive: true });
					return join(dir, name);
				};
				const list = () => c.call("delegate_jobs", { action: "list" });
				const ids = async () => (await list()).map((entry: any) => entry.job_id ?? entry.batch_id);
				const stdins = async (path: string) =>
					Promise.all(
						(await readdir(path)).filter((name) => name.startsWith("stdin-")).map((name) => readFile(join(path, name), "utf8")),
					);
				const [validate, order, d1, d2, third, admission, onlyPi] = await Promise.all(
					["validate", "order", "d1", "d2", "third", "admission", "onlypi"].map(sub),
				);

				await assert.rejects(c.call("delegate", { runner: "pi", task: "x", tasks: [{ task: "y" }] }), /exactly one of task or tasks/);
				await assert.rejects(c.call("delegate", { runner: "pi", cwd: validate }), /exactly one of task or tasks/);
				await assert.rejects(
					c.call("delegate", { runner: "pi", cwd: validate, tasks: [{ task: "a" }, { task: "b" }, { task: "c" }] }),
					/1 or 2 tasks/,
				);
				await assert.rejects(
					c.call("delegate", { runner: "pi", cwd: validate, tasks: [{ task: "a" }, { task: "b", cwd: join(dir, "nope") }] }),
					/tasks\[1\]: cwd must be/,
				);
				await assert.rejects(
					c.call("delegate", { cwd: validate, background: true, tasks: [{ task: "a", runner: "pi" }, { task: "b" }] }),
					/tasks\[1\]: Invalid runner/,
				);
				assert.deepEqual(await stdins(validate), []);
				assert.deepEqual(await list(), []);

				const first = "ordered-first FIRST ' \" $(touch PWNED) `id`\nline two\n";
				const secondTask = "ordered-second SECOND & | > <\n";
				const ordered = await c.call("delegate", {
					runner: "pi",
					cwd: order,
					tasks: [{ task: first }, { task: secondTask, runner: "codex", model: "gpt-5.6-luna" }],
				});
				assert.deepEqual(
					ordered.jobs.map((job: any) => [job.runner, job.state, job.result.model, job.result.final_text]),
					[
						["pi", "done", "openai-codex/gpt-5.6-sol", "FIRST"],
						["codex", "done", "gpt-5.6-luna", "SECOND"],
					],
				);
				assert.equal(await readFile(join(order, "first-saw-second"), "utf8"), "yes");
				assert.ok(ordered.jobs.every((job: any) => job.result.job_id === job.job_id));
				assert.deepEqual((await stdins(order)).sort(), [first, secondTask].sort());

				const batchUpdates: any[] = [];
				await c.call("delegate", { runner: "pi", cwd: order, tasks: [{ task: "progress" }, { task: "slow" }] }, undefined, (update: any) =>
					batchUpdates.push(update),
				);
				assert.ok(batchUpdates.length >= 1);
				assert.equal(batchUpdates[0].content[0].text, "[1] turn 1 | [2] turn 0");
				assert.deepEqual(batchUpdates[0].details.jobs.map((job: any) => job.turns), [1, 0]);

				const mixed = await c.call("delegate", { runner: "pi", cwd: order, tasks: [{ task: "fail" }, { task: "after 100 KEPT" }] });
				assert.equal(mixed.state, "failed");
				assert.deepEqual(mixed.jobs.map((job: any) => [job.state, job.result.final_text]), [["failed", "fail"], ["done", "KEPT"]]);
				const timedOut = await c.call("delegate", {
					runner: "pi",
					cwd: order,
					tasks: [{ task: "after 100 KEPT" }, { task: "sleep", timeout_s: 0.3 }],
				});
				assert.deepEqual(timedOut.jobs.map((job: any) => job.state), ["done", "failed"]);
				assert.match(timedOut.jobs[1].result.error, /timed out/);

				const hold = await c.call("delegate", { runner: "pi", cwd: admission, task: "sleep", background: true, timeout_s: 30 });
				const held = await ids();
				const heldStdins = (await stdins(admission)).length;
				for (const background of [true, false])
					await assert.rejects(
						c.call("delegate", { runner: "pi", cwd: admission, background, tasks: [{ task: "after 10 A" }, { task: "after 10 B" }] }),
						/concurrency limit: 1 of 2 children active, 2 requested; nothing started/,
					);
				assert.deepEqual(await ids(), held);
				assert.equal((await stdins(admission)).length, heldStdins);
				assert.equal((await c.call("delegate", { runner: "pi", cwd: admission, task: "after 10 LONE" })).final_text, "LONE");
				await c.call("delegate_jobs", { action: "cancel", job_id: hold.job_id });

				const pair = await c.call("delegate", {
					runner: "pi",
					background: true,
					timeout_s: 30,
					tasks: [{ task: "stubborn", cwd: d1 }, { task: "stubborn", cwd: d2 }],
				});
				assert.deepEqual(Object.keys(pair), ["batch_id", "jobs"]);
				assert.deepEqual(pair.jobs.map((job: any) => job.status), ["running", "running"]);
				const pids = [await ready(d1), await ready(d2)];
				for (const background of [false, true])
					await assert.rejects(c.call("delegate", { runner: "pi", cwd: third, task: "third", background }), /concurrency limit/);
				assert.deepEqual(await stdins(third), []);
				const listed = (await list()).find((entry: any) => entry.batch_id === pair.batch_id);
				assert.deepEqual(listed.jobs.map((job: any) => job.job_id), pair.jobs.map((job: any) => job.job_id));
				const cancellingPair = c.call("delegate_jobs", { action: "cancel", job_id: pair.batch_id });
				await sleep(300);
				assert.deepEqual([await alive(pids[0]!), await alive(pids[1]!)], [true, true]);
				const cancelledPair = await cancellingPair;
				assert.deepEqual([await alive(pids[0]!), await alive(pids[1]!)], [false, false]);
				assert.equal(cancelledPair.state, "cancelled");
				assert.deepEqual(cancelledPair.jobs.map((job: any) => job.state), ["cancelled", "cancelled"]);

				const halves = await c.call("delegate", {
					runner: "pi",
					background: true,
					tasks: [{ task: "sleep", cwd: d1, timeout_s: 30 }, { task: "after 300 SURVIVOR", cwd: d2 }],
				});
				assert.equal((await c.call("delegate_jobs", { action: "cancel", job_id: halves.jobs[0].job_id })).state, "cancelled");
				const survived = await c.call("delegate_jobs", { action: "wait", job_id: halves.batch_id });
				assert.equal(survived.state, "failed");
				assert.deepEqual(survived.jobs.map((job: any) => [job.state, job.result.final_text]), [["cancelled", ""], ["done", "SURVIVOR"]]);

				const delivered = await c.call("delegate", {
					runner: "pi",
					cwd: d1,
					background: true,
					tasks: [{ task: "after 200 ONE" }, { task: "after 20 TWO" }],
				});
				const batchState = async (id: string) => (await list()).find((entry: any) => entry.batch_id === id)?.state;
				for (let i = 0; i < 250 && (await batchState(delivered.batch_id)) === "running"; i++) await sleep(20);
				await c.emit("agent_settled");
				assert.equal(c.sent.length, 0);
				idle = true;
				await c.emit("agent_settled");
				await c.emit("agent_settled");
				idle = false;
				assert.equal(c.sent.length, 1);
				assert.deepEqual(c.sent[0]!.message.details, {
					batch_id: delivered.batch_id,
					status: "done",
					job_ids: delivered.jobs.map((job: any) => job.job_id),
				});
				assert.match(
					c.sent[0]!.message.content,
					/^Background delegate batch \w+ done: 2 tasks\n\n\[1\] job \w+ done: after 200 ONE\n.*\nONE\n\n\[2\] job \w+ done: after 20 TWO\n.*\nTWO$/,
				);

				await writeFile(join(onlyPi, "pi"), script, { mode: 0o755 });
				const savedPath = process.env.PATH;
				process.env.PATH = onlyPi;
				try {
					const partial = await c.call("delegate", {
						cwd: d1,
						background: true,
						tasks: [{ task: "after 200 LIVE", runner: "pi" }, { task: "x", runner: "codex" }],
					});
					assert.deepEqual(partial.jobs.map((job: any) => job.status), ["running", "failed"]);
					const settled = await c.call("delegate_jobs", { action: "wait", job_id: partial.batch_id });
					assert.deepEqual(settled.jobs.map((job: any) => job.state), ["done", "failed"]);
					assert.equal(settled.jobs[0].result.final_text, "LIVE");
					assert.match(settled.jobs[1].result.error, /ENOENT|not found/);
					const before = await ids();
					await assert.rejects(
						c.call("delegate", { runner: "codex", cwd: d1, background: true, tasks: [{ task: "x" }, { task: "y" }] }),
						/ENOENT|not found/,
					);
					assert.deepEqual(await ids(), before);
				} finally {
					process.env.PATH = savedPath;
				}
				const savedTmp = process.env.TMPDIR;
				process.env.TMPDIR = join(dir, "missing");
				try {
					await assert.rejects(
						c.call("delegate", { runner: "pi", cwd: d1, tasks: [{ task: "after 20 A" }, { task: "after 20 B" }] }),
						(error: Error) => {
							const noTmp = JSON.parse(error.message);
							assert.deepEqual(noTmp.jobs.map((job: any) => job.state), ["failed", "failed"]);
							assert.match(noTmp.jobs[0].result.error, /ENOENT|no such file/i);
							return true;
						},
					);
				} finally {
					if (savedTmp === undefined) delete process.env.TMPDIR;
					else process.env.TMPDIR = savedTmp;
				}
				const refill = await c.call("delegate", { runner: "pi", cwd: d1, tasks: [{ task: "after 20 R1" }, { task: "after 20 R2" }] });
				assert.deepEqual(refill.jobs.map((job: any) => job.result.final_text), ["R1", "R2"]);
				assert.equal(c.sent.length, 1);

				const savedState = process.env.XDG_STATE_HOME;
				process.env.XDG_STATE_HOME = join(dir, "state");
				try {
					const repo = join(dir, "repo");
					const sub = join(repo, "sub");
					await mkdir(sub, { recursive: true });
					await writeFile(join(sub, "tracked.txt"), "base\n");
					await git(["-C", repo, "init", "-q"]);
					await git(["-C", repo, "add", "."]);
					await git(["-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false", "commit", "-qm", "base"]);
					await writeFile(join(sub, "tracked.txt"), "dirty\n");
					await writeFile(join(repo, "untracked.txt"), "parent only\n");
					const head = (await git(["-C", repo, "rev-parse", "HEAD"])).trim();
					const status = () => git(["-C", repo, "status", "--porcelain"]);
					const before = await status();
					const worktrees = () => git(["-C", repo, "worktree", "list", "--porcelain"]);

					await assert.rejects(c.call("delegate", { runner: "pi", cwd: sub, worktree: true, task: "x" }), /worktree requires mode write/);
					const known = await ids();
					await assert.rejects(
						c.call("delegate", { runner: "pi", mode: "write", cwd: validate, worktree: true, task: "x" }),
						/not a git repository/,
					);
					await assert.rejects(
						c.call("delegate", { runner: "pi", mode: "write", cwd: validate, tasks: [{ task: "a", cwd: sub }, { task: "b", worktree: true }] }),
						/tasks\[1\]: git .*not a git repository/,
					);
					assert.deepEqual(await ids(), known);
					assert.deepEqual([await stdins(validate), await stdins(sub)], [[], []]);
					assert.equal(existsSync(join(dir, "state")), false);

					const isolated = await c.call("delegate", {
						mode: "write",
						cwd: sub,
						worktree: true,
						tasks: [{ task: "cwd", runner: "pi" }, { task: "cwd", runner: "codex", model: "gpt-5.6-luna" }],
					});
					assert.equal(isolated.state, "done");
					const paths = isolated.jobs.map((job: any) => job.result.worktree_path);
					assert.notEqual(paths[0], paths[1]);
					for (const job of isolated.jobs) {
						const r = job.result;
						const inner = join(r.worktree_path, "sub");
						assert.deepEqual([r.job_id, r.worktree_path], [job.job_id, job.worktree_path]);
						assert.deepEqual([r.base_sha, r.repo_root, r.cwd, r.final_text], [head, repo, inner, inner]);
						assert.match(r.worktree_notice, /excludes the parent's uncommitted and untracked changes/);
						assert.equal(dirname(dirname(r.worktree_path)), join(dir, "state", "pi-delegate", "worktrees"));
						assert.equal((await git(["-C", r.worktree_path, "rev-parse", "HEAD"])).trim(), head);
						assert.equal(await readFile(join(inner, "tracked.txt"), "utf8"), "base\n");
						assert.equal(existsSync(join(r.worktree_path, "untracked.txt")), false);
						assert.equal((await stdins(inner)).length, 1);
					}
					assert.equal(await status(), before);
					assert.equal(await readFile(join(sub, "tracked.txt"), "utf8"), "dirty\n");
					assert.deepEqual(await stdins(sub), []);

					const halfFailed = await c.call("delegate", {
						runner: "pi",
						mode: "write",
						cwd: sub,
						worktree: true,
						tasks: [{ task: "fail" }, { task: "after 20 FINE" }],
					});
					assert.deepEqual(halfFailed.jobs.map((job: any) => job.state), ["failed", "done"]);
					for (const job of halfFailed.jobs) assert.ok(existsSync(join(job.result.worktree_path, "sub", "received.json")));

					const aborted = await c
						.call(
							"delegate",
							{ runner: "pi", mode: "write", cwd: sub, worktree: true, tasks: [{ task: "after 20 A" }, { task: "after 20 B" }] },
							AbortSignal.abort(),
						)
						.then(
							() => assert.fail("aborted setup must reject"),
							(error: Error) => JSON.parse(error.message),
						);
					for (const job of aborted.jobs) {
						assert.equal(job.state, "cancelled");
						assert.match(job.result.error, /aborted during worktree setup/);
						assert.deepEqual(await readdir(join(job.result.worktree_path, "sub")), ["tracked.txt"]);
					}

					const locked = dirname(paths[0]);
					await chmod(locked, 0o555);
					try {
						await assert.rejects(
							c.call("delegate", { runner: "pi", mode: "write", cwd: sub, worktree: true, task: "after 20 NO" }),
							(error: Error) => {
								const refused = JSON.parse(error.message);
								assert.match(refused.error, /worktree add/);
								assert.equal(existsSync(refused.worktree_path), false);
								return true;
							},
						);
					} finally {
						await chmod(locked, 0o755);
					}
					assert.deepEqual(await stdins(sub), []);
					assert.deepEqual(
						(await c.call("delegate", { runner: "pi", cwd: d1, tasks: [{ task: "after 20 S1" }, { task: "after 20 S2" }] })).jobs.map(
							(job: any) => job.result.final_text,
						),
						["S1", "S2"],
					);

					const writer = await c.call("delegate", { runner: "pi", mode: "write", cwd: sub, worktree: true, task: "sleep", background: true, timeout_s: 30 });
					await c.reach(writer.job_id, "running");
					const kept = (await list()).find((entry: any) => entry.job_id === writer.job_id).worktree_path;
					await assert.rejects(c.call("delegate_jobs", { action: "remove_worktree", job_id: writer.job_id }), /once it finishes/);
					await assert.rejects(c.call("delegate_jobs", { action: "remove_worktree", job_id: isolated.batch_id }), /not a batch id/);
					await c.commands.get("delegate")!.handler("", c.ctx);
					assert.ok(c.notes.at(-1)!.includes(`${writer.job_id} running pi`) && c.notes.at(-1)!.includes(`worktree=${kept}`));
					for (let i = 0; i < 100 && !existsSync(join(kept, "sub", "grandchild")); i++) await sleep(20);
					await c.call("delegate_jobs", { action: "cancel", job_id: writer.job_id });
					await assert.rejects(c.call("delegate_jobs", { action: "remove_worktree", job_id: writer.job_id }), /has changes; pass force/);
					assert.ok(existsSync(kept));
					await rm(aborted.jobs[0].result.worktree_path, { recursive: true, force: true });
					assert.match(await worktrees(), /prunable/);
					const removed = await c.call("delegate_jobs", { action: "remove_worktree", job_id: writer.job_id, force: true });
					assert.deepEqual([removed.removed, removed.forced], [kept, true]);
					assert.equal(existsSync(kept), false);
					const remaining = await worktrees();
					assert.ok(!remaining.includes(kept) && !remaining.includes(aborted.jobs[0].result.worktree_path));
					for (const path of [...paths, ...halfFailed.jobs.map((job: any) => job.result.worktree_path)]) assert.ok(existsSync(path));
					assert.equal(await status(), before);

					const root = join(dir, "state", "pi-delegate", "worktrees");
					const group = dirname(paths[0]);
					const clean = aborted.jobs[1].result.worktree_path;
					const remove = (params: object) => c.call("delegate_jobs", { action: "remove_worktree", ...params });
					const holder = await c.call("delegate", { runner: "pi", mode: "write", cwd: sub, worktree: true, task: "sleep", background: true, timeout_s: 30 });
					await c.reach(holder.job_id, "running");
					const held = (await c.find(holder.job_id)).worktree_path;
					const trees = new Map((await c.call("delegate_jobs", { action: "list_worktrees" })).map((entry: any) => [entry.path, entry]));
					assert.deepEqual(
						[...trees.keys()].sort(),
						[...paths, ...halfFailed.jobs.map((job: any) => job.result.worktree_path), clean, held].sort(),
					);
					for (const entry of trees.values() as Iterable<any>) assert.deepEqual([entry.common_git_dir, entry.main_worktree, entry.head], [join(repo, ".git"), repo, head]);
					const tree = (path: string) => trees.get(path) as any;
					assert.deepEqual([tree(clean).dirty, tree(paths[0]).dirty], [false, true]);
					assert.deepEqual([tree(held).job_id, tree(held).live_job, tree(paths[0]).job_id, tree(paths[0]).live_job], [holder.job_id, true, isolated.jobs[0].job_id, false]);

					const outside = join(dir, "outside-wt");
					await git(["-C", repo, "worktree", "add", "--detach", outside, head]);
					await symlink(outside, join(group, "escape"));
					for (const path of [outside, join(group, "escape"), `${root}/../../../repo`])
						await assert.rejects(remove({ path, force: true }), /is not inside the worktree root/);
					await assert.rejects(remove({ path: group, force: true }), /not a worktree root|not a git repository/);
					await assert.rejects(remove({ path: clean, job_id: holder.job_id }), /exactly one of job_id or path/);
					await assert.rejects(remove({ path: held, force: true }), /once it finishes/);
					const squatter = spawn("sleep", ["30"], { cwd: join(clean, "sub"), stdio: "ignore" });
					try {
						for (let i = 0; i < 100 && !squatter.pid; i++) await sleep(10);
						await sleep(50);
						await assert.rejects(remove({ path: clean }), new RegExp(`processes .*${squatter.pid}.* have their cwd inside`));
					} finally {
						squatter.kill("SIGKILL");
					}
					for (let i = 0; i < 100 && (await alive(squatter.pid!)); i++) await sleep(10);
					assert.deepEqual(await remove({ path: clean }), { job_id: aborted.jobs[1].job_id, removed: clean, common_git_dir: join(repo, ".git"), forced: false, discarded: "" });
					assert.equal(existsSync(clean), false);
					await assert.rejects(remove({ path: paths[0] }), /has changes; pass force/);
					const forced = await remove({ path: paths[0], force: true });
					assert.deepEqual([forced.job_id, forced.removed, forced.forced], [isolated.jobs[0].job_id, paths[0], true]);
					const after = await worktrees();
					assert.ok(!after.includes(paths[0]) && !after.includes(clean) && after.includes(outside) && after.includes(held));
					assert.ok(existsSync(join(outside, "sub", "tracked.txt")));
					await c.call("delegate_jobs", { action: "cancel", job_id: holder.job_id });
					assert.equal(await status(), before);
				} finally {
					if (savedState === undefined) delete process.env.XDG_STATE_HOME;
					else process.env.XDG_STATE_HOME = savedState;
				}

				await sleep(50);
				assert.deepEqual(rejections, []);
			} finally {
				await Promise.all(shutdowns.map((shutdown) => shutdown()));
				process.off("unhandledRejection", onRejection);
			}
		}),
	);

	test("empty state directories are pruned up to the state home and no further", async () => {
		const dir = await mkdtemp(join(tmpdir(), "delegate-prune-"));
		const saved = process.env.XDG_STATE_HOME;
		process.env.XDG_STATE_HOME = dir;
		try {
			const root = join(dir, "pi-delegate");
			await mkdir(join(root, "worktrees", "repo-abc"), { recursive: true });
			await mkdir(join(root, "logs"), { recursive: true });
			await writeFile(join(root, "logs", "keep.log"), "x");
			await pruneEmpty(join(root, "worktrees", "repo-abc"));
			assert.deepEqual([existsSync(join(root, "worktrees")), existsSync(join(root, "logs", "keep.log"))], [false, true]);
			await pruneEmpty(join(root, "logs"));
			assert.equal(existsSync(join(root, "logs")), true);
			await rm(join(root, "logs", "keep.log"));
			await pruneEmpty(join(root, "logs"));
			assert.deepEqual([existsSync(root), existsSync(dir)], [false, true]);
			await pruneEmpty(dir);
			assert.equal(existsSync(dir), true);
		} finally {
			if (saved === undefined) delete process.env.XDG_STATE_HOME;
			else process.env.XDG_STATE_HOME = saved;
			await rm(dir, { recursive: true, force: true });
		}
	});

	test("shell jobs: line match, completion, logs, caps and lifecycle", { timeout: 60_000 }, () =>
		withFakes(async (dir) => {
			const found: string[] = [];
			const split = lineMatcher("READY", (line) => found.push(line));
			split.push("tick 1\ntick RE");
			split.push("ADY now\nREADY again\n");
			split.end();
			const last = lineMatcher("END", (line) => found.push(line));
			last.push("a\nthe EN");
			last.push("D");
			last.end();
			const boundary = lineMatcher("XY", (line) => found.push(line), 10);
			boundary.push("0123456789X");
			boundary.push("Y");
			boundary.push("\n");
			const long = lineMatcher("XY", (line) => found.push(line), 10);
			long.push(`${"a".repeat(30)}XY${"b".repeat(30)}\n`);
			assert.deepEqual(found, ["tick READY now", "the END", "XY", "aaaaaaaaXY"]);

			const rejections: unknown[] = [];
			const onRejection = (reason: unknown) => rejections.push(reason);
			process.on("unhandledRejection", onRejection);
			const savedState = process.env.XDG_STATE_HOME;
			process.env.XDG_STATE_HOME = join(dir, "state");
			const shutdowns: (() => Promise<void>)[] = [];
			let idle = false;
			let busyOnSend = false;
			try {
				const s = harness(dir, shutdowns, {
					isIdle: () => idle,
					send: () => {
						if (busyOnSend) idle = false;
					},
				});
				const sh = (params: object) => s.call("shell_bg", params);
				const jobs = (params: object) => s.call("delegate_jobs", params);
				const settle = async () => {
					idle = true;
					await s.emit("agent_settled");
					idle = false;
				};
				const events = () => s.sent.map((sent) => [sent.message.details.job_id, sent.message.details.event]);
				const logs = join(dir, "state", "pi-delegate", "logs");

				await assert.rejects(sh({ command: "true", cwd: "relative" }), /cwd must be/);
				await assert.rejects(sh({ command: "true", timeout_s: 86401 }), /timeout_s/);
				await assert.rejects(sh({ command: "true", notify_on: "a\nb" }), /notify_on/);

				const ticker = await sh({
					command: "printf 'one\\nREA'; sleep 0.3; printf 'DY 1\\nREADY 2\\n'; sleep 1; printf 'last line'",
					notify_on: "READY",
				});
				assert.deepEqual([Object.keys(ticker), ticker.status, ticker.log], [["job_id", "status", "log"], "running", join(logs, `${ticker.job_id}.log`)]);
				for (let i = 0; i < 100 && !(await s.find(ticker.job_id)).match; i++) await sleep(20);
				const matched = await s.find(ticker.job_id);
				assert.deepEqual([matched.kind, matched.state, matched.match], ["shell", "running", "READY 1"]);
				await s.emit("agent_settled");
				assert.equal(s.sent.length, 0);
				await settle();
				await settle();
				assert.deepEqual(events(), [[ticker.job_id, "match"]]);
				assert.equal(s.sent[0]!.message.customType, "shell-bg");
				assert.equal(s.sent[0]!.message.details.status, "running");
				assert.match(s.sent[0]!.message.content, new RegExp(`^Background shell job ${ticker.job_id} output matched "READY": printf .*\nREADY 1$`));
				await s.reach(ticker.job_id, "done");
				await settle();
				await settle();
				assert.deepEqual(events(), [[ticker.job_id, "match"], [ticker.job_id, "exit"]]);
				assert.match(s.sent[1]!.message.content, /\nexit_code=0 signal=null status=exited duration_ms=\d+ /);
				assert.match(s.sent[1]!.message.content, /\nlast lines:\none\nREADY 1\nREADY 2\nlast line$/);
				assert.equal(await readFile(ticker.log, "utf8"), "one\nREADY 1\nREADY 2\nlast line");

				const tailless = await sh({ command: "printf 'a\\nfinal MATCH'", notify_on: "MATCH", notify_on_exit: false });
				await s.reach(tailless.job_id, "done");
				assert.equal((await s.find(tailless.job_id)).match, "final MATCH");
				await settle();
				await settle();
				assert.deepEqual(events().slice(2), [[tailless.job_id, "match"]]);

				const both = await sh({ command: "echo GO; sleep 0.2; echo GO again", notify_on: "GO" });
				await s.reach(both.job_id, "done");
				busyOnSend = true;
				await settle();
				assert.deepEqual(events().slice(3), [[both.job_id, "match"]]);
				await settle();
				await settle();
				assert.deepEqual(events().slice(3), [[both.job_id, "match"], [both.job_id, "exit"]]);

				const fetched = await sh({ command: "echo HIT", notify_on: "HIT" });
				const waited = await jobs({ action: "wait", job_id: fetched.job_id });
				assert.deepEqual([waited.state, waited.result.exit_code, waited.result.match, waited.result.tail], ["done", 0, "HIT", "HIT"]);
				await settle();
				assert.equal(s.sent.length, 5);
				const three = await sh({ command: "echo oops >&2; exit 3" });
				await s.reach(three.job_id, "failed");
				const slow = await sh({ command: "sleep 30", timeout_s: 0.3 });
				await s.reach(slow.job_id, "failed");
				await settle();
				assert.deepEqual(events().slice(5), [[three.job_id, "exit"]]);
				await settle();
				assert.deepEqual(events().slice(5), [[three.job_id, "exit"], [slow.job_id, "exit"]]);
				assert.match(s.sent.at(-1)!.message.content, /status=timed_out/);
				const exited = await jobs({ action: "result", job_id: three.job_id });
				assert.deepEqual([exited.result.status, exited.result.exit_code, exited.result.tail], ["exited", 3, "oops"]);
				const timedOut = await jobs({ action: "result", job_id: slow.job_id });
				assert.deepEqual([timedOut.result.status, timedOut.result.exit_code], ["timed_out", null]);
				assert.ok(timedOut.result.signal);

				const started = Date.now();
				const flood = await sh({ command: "head -c 20000000 /dev/zero | tr '\\0' a; printf '\\nEND\\n'", notify_on: "END", notify_on_exit: false });
				const flooded = await jobs({ action: "wait", job_id: flood.job_id, timeout_s: 30 });
				assert.deepEqual(
					[flooded.state, flooded.result.log_bytes, flooded.result.log_truncated, flooded.result.match],
					["done", 8 * 1024 * 1024, true, "END"],
				);
				assert.equal((await stat(flood.log)).size, 8 * 1024 * 1024);
				assert.ok(Date.now() - started < 20_000);

				const counted = await sh({ command: "seq 1 100000", notify_on_exit: false });
				await jobs({ action: "wait", job_id: counted.job_id });
				assert.equal((await jobs({ action: "tail", job_id: counted.job_id, lines: 3 })).text, "99998\n99999\n100000");
				const fortyLines = (await jobs({ action: "tail", job_id: counted.job_id })).text.split("\n");
				assert.deepEqual([fortyLines.length, fortyLines[0]], [40, "99961"]);
				await assert.rejects(jobs({ action: "tail", job_id: counted.job_id, lines: 501 }), /lines must be/);

				const known = (await jobs({ action: "list" })).length;
				await chmod(logs, 0o555);
				try {
					await assert.rejects(sh({ command: "touch never.txt", notify_on_exit: false }), (error: Error) => {
						const refused = JSON.parse(error.message);
						assert.equal(refused.status, "failed");
						assert.match(refused.error, /EACCES|permission denied/i);
						return true;
					});
				} finally {
					await chmod(logs, 0o755);
				}
				assert.equal(existsSync(join(dir, "never.txt")), false);
				assert.equal((await jobs({ action: "list" })).length, known);

				const grand = join(dir, "grand");
				await mkdir(grand);
				const stubborn = await sh({ command: `printf stubborn | ${join(dir, "pi")}`, cwd: grand });
				const grandchild = await ready(grand);
				assert.ok(await alive(grandchild));
				assert.equal((await jobs({ action: "cancel", job_id: stubborn.job_id })).state, "cancelled");
				assert.equal(await alive(grandchild), false);
				assert.equal((await jobs({ action: "result", job_id: stubborn.job_id })).result.status, "cancelled");
				assert.ok(existsSync(stubborn.log));
				const orphaner = await sh({ command: "sleep 30 & echo $! > orphan.pid", cwd: grand, notify_on_exit: false });
				await s.reach(orphaner.job_id, "done");
				assert.equal(await alive(Number(await readFile(join(grand, "orphan.pid"), "utf8"))), false);

				const sleepers = [];
				for (let i = 0; i < 4; i++) sleepers.push(await sh({ command: "sleep 30" }));
				await assert.rejects(sh({ command: "true" }), /shell_bg limit: 4 of 4 shell jobs running/);
				const pair = await s.call("delegate", { runner: "pi", tasks: [{ task: "after 20 A" }, { task: "after 20 B" }] });
				assert.deepEqual(pair.jobs.map((job: any) => job.result.final_text), ["A", "B"]);
				await s.commands.get("delegate")!.handler("", s.ctx);
				assert.match(s.notes.at(-1)!, new RegExp(`${sleepers[0].job_id} running shell \\d+s sleep 30`));
				for (const job of sleepers) await jobs({ action: "cancel", job_id: job.job_id });
				const sent = s.sent.length;
				await settle();
				assert.equal(s.sent.length, sent);

				for (let i = 0; i < 21; i++) {
					const quick = await sh({ command: "true", notify_on_exit: false });
					await jobs({ action: "wait", job_id: quick.job_id });
				}
				assert.equal(existsSync(ticker.log), false);
				await assert.rejects(jobs({ action: "result", job_id: ticker.job_id }), /Unknown delegate job/);

				const survivor = await sh({ command: "sleep 30" });
				assert.ok((await readdir(logs)).length > 1);
				await s.emit("session_shutdown");
				assert.equal(await s.state(survivor.job_id), "cancelled");
				assert.equal(existsSync(logs), false);
				await assert.rejects(sh({ command: "true" }), /shutting down/);
				await sleep(50);
				assert.deepEqual(rejections, []);
			} finally {
				await Promise.all(shutdowns.map((shutdown) => shutdown()));
				if (savedState === undefined) delete process.env.XDG_STATE_HOME;
				else process.env.XDG_STATE_HOME = savedState;
				process.off("unhandledRejection", onRejection);
			}
		}),
	);
	test("F1: markerless roots are seeded and killed on timeout and cancellation", { timeout: 10_000 }, () =>
		withFakes(async (dir) => {
			const savedState = process.env.XDG_STATE_HOME;
			process.env.XDG_STATE_HOME = join(dir, "state");
			const jobs = createJobs({ send() {}, isIdle: () => false, status() {} });
			try {
				for (const cancel of [false, true]) {
					const file = join(dir, `root-${cancel}.pid`);
					const handle = await jobs.shell({ command: `echo $$ > '${file}'; exec env -u PI_DELEGATE_RUN sleep 30`, timeout_s: cancel ? 5 : 1 }, dir);
					await until(() => existsSync(file));
					const pid = Number(await readFile(file, "utf8"));
					await until(async () => !(await readFile(`/proc/${pid}/environ`, "utf8")).includes("PI_DELEGATE_RUN="));
					assert.ok(await alive(pid));
					if (cancel) await jobs.cancel(handle.job_id);
					const result = await jobs.wait(handle.job_id, 3);
					assert.equal("result" in result && result.result && "status" in result.result ? result.result.status : undefined, cancel ? "cancelled" : "timed_out");
					assert.equal(await alive(pid), false);
				}
			} finally {
				await jobs.close();
				if (savedState === undefined) delete process.env.XDG_STATE_HOME;
				else process.env.XDG_STATE_HOME = savedState;
			}
		}),
	);

	test("F1: failed observations retain identities, PID reuse clears them, and scans are bounded", async () => {
		const statText = (pid: number, start: string, state = "S") => `${pid} (fake) ${[state, "1", ...Array(17).fill("0"), start].join(" ")}`;
		const denied = Object.assign(new Error("stat denied"), { code: "EACCES" });
		const known = new Map<number, string | null>([[41, "old"]]);
		const failed = await tree("token", known, async () => { throw denied; }, async () => ["41"]);
		assert.deepEqual(failed.pids, [41]);
		assert.match(failed.errors.join(" "), /stat denied/);
		const envFailed = await tree("token", known, async (path) => {
			if (path.endsWith("environ")) throw Object.assign(new Error("fd limit"), { code: "EMFILE" });
			return statText(41, "old");
		}, async () => ["41"]);
		assert.deepEqual(envFailed.pids, [41]);
		assert.match(envFailed.errors.join(" "), /fd limit/);
		await tree("token", known, async (path) => path.endsWith("stat") ? statText(41, "new") : "", async () => ["41"]);
		assert.equal(known.size, 0);
		known.set(41, "old");
		await tree("token", known, async () => { throw Object.assign(new Error("gone"), { code: "ENOENT" }); }, async () => []);
		assert.equal(known.size, 0);
		let active = 0;
		let peak = 0;
		await tree("token", known, async (path) => {
			peak = Math.max(peak, ++active);
			await sleep(1);
			active--;
			return path.endsWith("stat") ? statText(42, "x") : "";
		}, async () => Array.from({ length: 80 }, (_, i) => String(100 + i)));
		assert.ok(peak > 1 && peak <= 16, `peak reads: ${peak}`);
		const own = new Map<number, string | null>();
		seedRoot(process.pid, own);
		assert.equal(typeof own.get(process.pid), "string");
	});

	test("F2: cleanup failures retain model and shell capacity; cancel retries; shutdown reports survivors", { timeout: 15_000 }, () =>
		withFakes(async (dir) => {
			const savedState = process.env.XDG_STATE_HOME;
			process.env.XDG_STATE_HOME = join(dir, "state");
			let stuck = true;
			let attempts = 0;
			const sweep: typeof terminate = async (...args) => {
				attempts++;
				return stuck ? { unkilled_pids: [424242], cleanup_error: "injected survivor" } : terminate(...args);
			};
			const jobs = createJobs({ send() { assert.fail("no terminal notification while stuck"); }, isIdle: () => false, status() {}, childHooks: { sweep }, shellHooks: { sweep } });
			try {
				const repo = join(dir, "repo");
				await mkdir(repo);
				await git(["-C", repo, "init", "-q"]);
				await git(["-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-qm", "base"]);
				const a = await jobs.launch([{ runner: "pi", task: "one", mode: "write", worktree: true }], repo, false);
				const b = await jobs.launch([{ runner: "codex", task: "two" }], dir, false);
				assert.ok("job_id" in a && "job_id" in b);
				await until(() => jobs.list().every((job) => job.state === "cleanup_failed"));
				assert.deepEqual((jobs.result(a.job_id) as { unkilled_pids: number[] }).unkilled_pids, [424242]);
				await assert.rejects(jobs.removeWorktree(a.job_id, undefined, true), /cleanup_failed.*once it finishes/);
				assert.equal((await jobs.listWorktrees()).find((entry) => "job_id" in entry && entry.job_id === a.job_id)?.live_job, true);
				await assert.rejects(jobs.launch([{ runner: "pi", task: "third" }], dir, false), /concurrency limit/);
				const before = attempts;
				assert.equal((await jobs.cancel(a.job_id)).state, "cleanup_failed");
				assert.ok(attempts > before);
				await until(() => attempts > before + 2);
				stuck = false;
				assert.equal((await jobs.cancel(a.job_id)).state, "cancelled");
				await jobs.cancel(b.job_id);
				const admitted = await jobs.run([{ runner: "agy", task: "admitted" }], dir, false);
				assert.equal("final_text" in admitted && admitted.final_text, "admitted");
				stuck = true;
				const shells: { job_id: string }[] = [];
				for (let i = 0; i < 4; i++) shells.push(await jobs.shell({ command: "true" }, dir));
				await until(() => jobs.list().filter((job) => "kind" in job && job.kind === "shell").every((job) => job.state === "cleanup_failed"));
				await assert.rejects(jobs.shell({ command: "true" }, dir), /shell_bg limit/);
				stuck = false;
				await jobs.cancel(shells[0]!.job_id);
				stuck = true;
				shells.push(await jobs.shell({ command: "true" }, dir));
				await until(() => jobs.result(shells.at(-1)!.job_id).state === "cleanup_failed");
				await assert.rejects(jobs.close(), /cleanup incomplete.*injected survivor/);
				stuck = false;
				for (const handle of shells) await jobs.cancel(handle.job_id);
			} finally {
				stuck = false;
				await jobs.close();
				if (savedState === undefined) delete process.env.XDG_STATE_HOME;
				else process.env.XDG_STATE_HOME = savedState;
			}
		}),
	);

	test("F5: model reservations survive pending and failed temporary-directory removal", { timeout: 10_000 }, () =>
		withFakes(async (dir) => {
			let unblock!: () => void;
			const gate = new Promise<void>((resolve) => { unblock = resolve; });
			let removals = 0;
			let fail = true;
			const jobs = createJobs({ send() {}, isIdle: () => false, status() {}, childHooks: {
				remove: async (path) => {
					removals++;
					await gate;
					if (fail) throw new Error("injected rm failure");
					await rm(path, { recursive: true, force: true });
				},
			} });
			try {
				const a = await jobs.launch([{ runner: "pi", task: "one" }], dir, false);
				const b = await jobs.launch([{ runner: "pi", task: "two" }], dir, false);
				assert.ok("job_id" in a && "job_id" in b);
				await until(() => removals === 2);
				await assert.rejects(jobs.launch([{ runner: "pi", task: "third" }], dir, false), /concurrency limit/);
				unblock();
				await until(() => jobs.list().every((job) => job.state === "cleanup_failed"));
				assert.match((jobs.result(a.job_id) as { cleanup_error: string }).cleanup_error, /Temporary directory cleanup failed.*injected rm failure/);
				await assert.rejects(jobs.launch([{ runner: "pi", task: "third" }], dir, false), /concurrency limit/);
				fail = false;
				await jobs.cancel(a.job_id);
				await jobs.cancel(b.job_id);
				const next = await jobs.run([{ runner: "pi", task: "after-cleanup" }], dir, false);
				assert.equal("final_text" in next && next.final_text, "after-cleanup");
			} finally { fail = false; unblock(); await jobs.close(); }
		}),
	);

	test("F6: each model runner sweeps a pipe-holding orphan on exit", { timeout: 10_000 }, () =>
		withFakes(async (dir) => {
			for (const runner of ["pi", "codex", "agy"] as const) {
				await rm(join(dir, "pipe-orphan.pid"), { force: true });
				const result = await runDelegate({ runner, task: "pipe-orphan", timeout_s: 2 }, dir);
				assert.equal(result.status, "answered");
				assert.equal(result.final_text, "pipe-answer");
				assert.equal(result.error, undefined);
				assert.equal(await alive(Number(await readFile(join(dir, "pipe-orphan.pid"), "utf8"))), false);
			}
		}),
	);

	test("F7: rejected sweeps expose cleanup failure without hanging the caller or rejecting unhandled", { timeout: 10_000 }, () =>
		withFakes(async (dir) => {
			let reject = true;
			const unhandled: unknown[] = [];
			const onRejection = (error: unknown) => unhandled.push(error);
			process.on("unhandledRejection", onRejection);
			const sweep: typeof terminate = async (...args) => {
				if (reject) throw new Error("injected /proc readdir denial");
				return terminate(...args);
			};
			const savedState = process.env.XDG_STATE_HOME;
			process.env.XDG_STATE_HOME = join(dir, "state");
			const jobs = createJobs({ send() {}, isIdle: () => false, status() {}, childHooks: { sweep }, shellHooks: { sweep } });
			try {
				const result = await jobs.run([{ runner: "pi", task: "answer" }], dir, false);
				assert.equal("state" in result && result.state, "cleanup_failed");
				assert.match("cleanup_error" in result ? result.cleanup_error ?? "" : "", /sweep failed.*readdir denial/);
				const shell = await jobs.shell({ command: "true" }, dir);
				await until(() => jobs.result(shell.job_id).state === "cleanup_failed");
				assert.equal((await jobs.cancel(shell.job_id)).state, "cleanup_failed");
				await sleep(20);
				assert.deepEqual(unhandled, []);
			} finally {
				reject = false;
				await jobs.close();
				process.off("unhandledRejection", onRejection);
				if (savedState === undefined) delete process.env.XDG_STATE_HOME;
				else process.env.XDG_STATE_HOME = savedState;
			}
		}),
	);

	test("F10: trailing progress contains the last burst and stops at completion and shutdown", { timeout: 10_000 }, () =>
		withFakes(async (dir) => {
			const jobs = createJobs({ send() {}, isIdle: () => false, status() {} });
			try {
				const updates: Progress[] = [];
				const running = jobs.run([{ runner: "pi", task: "trailing" }], dir, false, undefined, (children) => updates.push({ ...children[0]!.progress }));
				await until(() => updates.some((p) => p.tools.includes("long-tool")));
				assert.deepEqual(updates[0], { turns: 1, tools: [] });
				await running;
				const count = updates.length;
				await sleep(550);
				assert.equal(updates.length, count);
				const next = jobs.run([{ runner: "pi", task: "trailing" }], dir, false, undefined, (children) => updates.push({ ...children[0]!.progress }));
				await until(() => updates.length > count);
				await jobs.close();
				await next;
				const stopped = updates.length;
				await sleep(550);
				assert.equal(updates.length, stopped);
			} finally { await jobs.close(); }
		}),
	);

	test("F11: mid-run log failure appears in completion text without changing command exit", { timeout: 10_000 }, () =>
		withFakes(async (dir) => {
			const savedState = process.env.XDG_STATE_HOME;
			process.env.XDG_STATE_HOME = join(dir, "state");
			const sent: string[] = [];
			let writes = 0;
			let idle = false;
			const jobs = createJobs({ send: (message) => { sent.push(message.content); }, isIdle: () => idle, status() {}, shellHooks: {
				write: ((...args: Parameters<typeof writeSync>) => {
					if (++writes > 1) throw new Error("injected ENOSPC");
					const written = writeSync(...args);
					writeFileSync(join(dir, "write-ready"), "");
					return written;
				}) as typeof writeSync,
			} });
			try {
				const handle = await jobs.shell({ command: "echo first; while [ ! -f write-ready ]; do sleep 0.01; done; echo second" }, dir);
				await until(() => jobs.list().some((job) => "job_id" in job && job.job_id === handle.job_id && job.state === "done"));
				idle = true;
				jobs.flush();
				assert.equal(sent.length, 1);
				assert.match(sent[0]!, /log_error: output capture failed: injected ENOSPC/);
				assert.ok(!sent[0]!.includes("(truncated)"));
				const result = jobs.result(handle.job_id);
				assert.ok("result" in result && result.result && "log_error" in result.result);
				assert.equal(result.result.exit_code, 0);
				assert.equal(result.result.status, "exited");
				assert.equal(result.result.log_error, "injected ENOSPC");
				assert.equal(result.result.log_truncated, false);
				assert.ok(writes >= 2);
			} finally {
				await jobs.close();
				if (savedState === undefined) delete process.env.XDG_STATE_HOME;
				else process.env.XDG_STATE_HOME = savedState;
			}
		}),
	);

test("F4/F8: canonical cwd rejects a committed symlink; bare and separate git dirs administer worktrees", { timeout: 30_000 }, () =>
	withFakes(async (dir) => {
		const saved = process.env.XDG_STATE_HOME;
		process.env.XDG_STATE_HOME = join(dir, "state");
		const jobs = createJobs({ send() {}, isIdle: () => false, status() {} });
		try {
			const repo = join(dir, "repo");
			await git(["init", repo]);
			await symlink(repo, join(repo, "sub"));
			await git(["-C", repo, "add", "sub"]);
			await git(["-C", repo, "-c", "commit.gpgsign=false", "-c", "user.name=x", "-c", "user.email=x@y", "commit", "-m", "symlink"]);
			await rm(join(repo, "sub"));
			await mkdir(join(repo, "sub"));
			const result: any = await jobs.run([{ runner: "pi", task: "cwd", mode: "write", worktree: true }], join(repo, "sub"), false);
			assert.equal(result.status, "failed");
			assert.match(result.error, /escapes canonical worktree/);
			assert.ok(existsSync(result.worktree_path));
			assert.equal(existsSync(join(repo, "received.json")), false);
			assert.equal(existsSync(join(repo, "sub", "received.json")), false);
			reserve(2); release(); release();
			await jobs.removeWorktree(result.job_id, undefined, true);

			for (const layout of ["bare", "separate"] as const) {
				const common = join(dir, `${layout}.git`);
				const checkout = join(dir, layout);
				if (layout === "bare") {
					await git(["clone", "--bare", repo, common]);
					await git(["--git-dir", common, "worktree", "add", "--detach", checkout, "HEAD"]);
				} else {
					await git(["init", "--separate-git-dir", common, checkout]);
					await writeFile(join(checkout, "file"), "base");
					await git(["-C", checkout, "add", "file"]);
					await git(["-C", checkout, "-c", "commit.gpgsign=false", "-c", "user.name=x", "-c", "user.email=x@y", "commit", "-m", "base"]);
				}
				const base = await locate(checkout, new Map());
				assert.equal(base.common_git_dir, common);
				const path = worktreePath(checkout, layout);
				assert.equal(await provision(base, path), path);
				const entry = (await listWorktrees()).find((entry) => entry.path === path);
				assert.ok(entry && "common_git_dir" in entry);
				assert.equal(entry.common_git_dir, common);
				assert.equal(entry.main_worktree, layout === "bare" ? null : checkout);
				assert.equal((await removeWorktree(common, path, false)).common_git_dir, common);
				assert.equal(existsSync(path), false);
			}
		} finally {
			await jobs.close();
			if (saved === undefined) delete process.env.XDG_STATE_HOME; else process.env.XDG_STATE_HOME = saved;
		}
	}),
);

test("F9: pending shell logs and batch envelopes share a hard admission bound; delivery and collection evict", { timeout: 90_000 }, () =>
	withFakes(async (dir) => {
		const saved = process.env.XDG_STATE_HOME;
		process.env.XDG_STATE_HOME = join(dir, "state");
		let idle = false;
		const sent: string[] = [];
		const jobs = createJobs({ send: (m) => { sent.push(String(m.details.job_id)); idle = false; }, isIdle: () => idle, status() {} });
		const entries: { job_id: string; log: string }[] = [];
		try {
			assert.equal(BACKLOG, 48);
			for (let i = 0; i < BACKLOG - 1; i++) {
				const entry = await jobs.shell({ command: "printf pending" }, dir);
				entries.push(entry);
				await until(() => jobs.list().some((j) => "job_id" in j && j.job_id === entry.job_id && j.state === "done"));
			}
			await assert.rejects(jobs.launch([{ runner: "pi", task: "a" }, { runner: "pi", task: "b" }], dir, true), /backlog limit/);
			assert.equal(jobs.list().length, 47);
			const model = await jobs.launch([{ runner: "pi", task: "last" }], dir, false);
			assert.ok("job_id" in model);
			await until(() => jobs.list().some((j) => "job_id" in j && j.job_id === model.job_id && j.state === "done"));
			await assert.rejects(jobs.launch([{ runner: "pi", task: "overflow" }], dir, false), /backlog limit/);
			await assert.rejects(jobs.shell({ command: "echo overflow" }, dir), /backlog limit/);
			assert.equal(jobs.list().length, 48);
			assert.ok(entries.every((entry) => existsSync(entry.log)));
			idle = true; jobs.flush();
			assert.deepEqual(sent, [entries[0]!.job_id]);
			assert.equal(jobs.list().length, 47);
			assert.equal(existsSync(entries[0]!.log), false);
			const extra = await jobs.shell({ command: "printf extra", notify_on_exit: false }, dir);
			await until(() => !jobs.list().some((j) => "job_id" in j && j.job_id === extra.job_id));
			assert.equal(existsSync(extra.log), false);
			const snapshot: any = jobs.result(entries[1]!.job_id);
			assert.equal(snapshot.result.tail, "pending");
			assert.equal(existsSync(entries[1]!.log), false);
			for (let i = 0; i < BACKLOG; i++) { idle = true; jobs.flush(); }
			assert.equal(new Set(sent).size, 47);
			assert.equal(sent.length, 47);
			assert.ok(jobs.list().length <= 20);
		} finally {
			await jobs.close();
			if (saved === undefined) delete process.env.XDG_STATE_HOME; else process.env.XDG_STATE_HOME = saved;
		}
	}),
);

test("A1/A3/A4/A5: agy gate preflight, UTF-8 byte limit before reservation, worktree refusal and bypass notice", { timeout: 15_000 }, () =>
	withFakes(async (dir) => {
		const config = join(geminiDir(), "config", "hooks.json");
		const wired = await readFile(config, "utf8");
		await rm(config);
		await assert.rejects(runDelegate({ runner: "agy", task: "missing" }, dir), /read-only preflight failed/);
		for (const value of ["{", "{}", JSON.stringify({ gate: { PreToolUse: [{ matcher: "run_command", hooks: [{ command: `bash ${join(dir, "agy-pretool.sh")}` }] }] } }), JSON.stringify({ gate: { PreToolUse: [{ matcher: "*", hooks: [{ command: `echo ${join(dir, "agy-pretool.sh")}` }] }] } })]) {
			await writeFile(config, value);
			await assert.rejects(prepare({ runner: "agy", task: "unwired" }, dir), /read-only preflight failed/);
		}
		await writeFile(config, wired);
		await rm(join(dir, "agy-pretool.sh"));
		await assert.rejects(checkAgyGate(), /read-only preflight failed/);
		await writeFile(join(dir, "agy-pretool.sh"), "#!/bin/sh\nexit 0\n", { mode: 0o755 });
		await checkAgyGate();
		assert.equal(existsSync(join(dir, "received.json")), false);
		assert.equal(AGY_TASK_BYTES, 98304);
		await prepare({ runner: "agy", task: "界".repeat(AGY_TASK_BYTES / 3) }, dir);
		await assert.rejects(runDelegate({ runner: "agy", task: "界".repeat(AGY_TASK_BYTES / 3) + "x" }, dir), /exceeds 98304 UTF-8 bytes/);
		await assert.rejects(prepare({ runner: "agy", task: "x", mode: "write", worktree: true }, dir), /agy worktree is unsupported/);
		reserve(2); release(); release();
		const normal = await runDelegate({ runner: "agy", task: "normal" }, dir);
		assert.equal(normal.sandbox_bypass, false);
		assert.match(normal.notice!, /commands run outside delegate cwd/);
		const bypass = await runDelegate({ runner: "agy", task: "bypass", mode: "write" }, dir);
		assert.equal(bypass.sandbox_bypass, true);
		assert.match(bypass.notice!, /BypassSandbox: true/);
		const sent: string[] = [];
		const jobs = createJobs({ send: (m) => sent.push(m.content), isIdle: () => true, status() {} });
		try {
			await jobs.launch([{ runner: "agy", task: "bypass", mode: "write" }], dir, false);
			await until(() => sent.length === 1);
			assert.match(sent[0]!, /BypassSandbox: true/);
		} finally { await jobs.close(); }
	}),
);
