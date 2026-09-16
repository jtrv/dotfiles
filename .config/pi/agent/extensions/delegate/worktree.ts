import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, readdir, readFile, readlink, realpath, rmdir, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { promisify } from "node:util";

export type Base = { repo_root: string; common_git_dir: string; main_worktree?: string; base_sha: string; prefix: string };
export const NOTICE = "Worktree is pinned to base_sha; it excludes the parent's uncommitted and untracked changes";
const run = promisify(execFile);

export async function git(args: string[]) {
	try {
		const { stdout } = await run("git", args, {
			env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" },
			timeout: 60_000,
			maxBuffer: 8 * 1024 * 1024,
		});
		return stdout;
	} catch (error) {
		const { stderr, message } = error as { stderr?: string; message: string };
		throw new Error(`git ${args.join(" ")}: ${(stderr || message).trim()}`);
	}
}

// pins maps repo root to the first HEAD seen, so every child of one call shares a base commit.
export async function locate(cwd: string, pins: Map<string, string>): Promise<Base> {
	const [root = "", prefix = "", sha = ""] = (await git(["-C", cwd, "rev-parse", "--show-toplevel", "--show-prefix", "HEAD"])).split("\n");
	if (!pins.has(root)) pins.set(root, sha);
	const common_git_dir = (await git(["-C", cwd, "rev-parse", "--path-format=absolute", "--git-common-dir"])).trim();
	const privateDir = (await git(["-C", cwd, "rev-parse", "--absolute-git-dir"])).trim();
	const main_worktree = privateDir === common_git_dir ? root : await readFile(join(privateDir, "pi-delegate-main-worktree"), "utf8").catch(() => undefined);
	return { repo_root: root, common_git_dir, main_worktree, base_sha: pins.get(root)!, prefix };
}

export function stateRoot() {
	const env = process.env.XDG_STATE_HOME;
	return join(env && isAbsolute(env) ? env : join(homedir(), ".local", "state"), "pi-delegate");
}

export const worktreeRoot = () => join(stateRoot(), "worktrees");

export function worktreePath(root: string, id: string) {
	const hash = createHash("sha256").update(root).digest("hex").slice(0, 12);
	return join(worktreeRoot(), `${basename(root)}-${hash}`, id);
}

export async function provision(base: Base, path: string) {
	await mkdir(dirname(path), { recursive: true });
	const parent = await realpath(dirname(path));
	if (relative(base.repo_root, parent).split(sep)[0] !== "..")
		throw new Error(`worktree parent ${parent} is inside repository ${base.repo_root}`);
	await git(["--git-dir", base.common_git_dir, "worktree", "add", "--detach", path, base.base_sha]);
	if (base.main_worktree) {
		const privateDir = (await git(["-C", path, "rev-parse", "--absolute-git-dir"])).trim();
		await writeFile(join(privateDir, "pi-delegate-main-worktree"), base.main_worktree);
	}
	const [top, head] = (await git(["-C", path, "rev-parse", "--show-toplevel", "HEAD"])).split("\n");
	if (top !== join(parent, basename(path)) || head !== base.base_sha)
		throw new Error(`worktree verification failed: toplevel ${top}, HEAD ${head}, expected ${path} at ${base.base_sha}`);
	const root = await realpath(path);
	const cwd = await realpath(resolve(path, base.prefix));
	const rel = relative(root, cwd);
	if (isAbsolute(rel) || rel.split(sep)[0] === "..")
		throw new Error(`worktree cwd ${cwd} escapes canonical worktree ${root}; retained for inspection`);
	if (!(await stat(cwd).catch(() => undefined))?.isDirectory())
		throw new Error(`${base.prefix} is not a directory in base commit ${base.base_sha}`);
	return cwd;
}

export async function removeWorktree(common: string, path: string, force: boolean) {
	const changes = await git(["-C", path, "status", "--porcelain"]);
	if (changes && !force) throw new Error(`worktree ${path} has changes; pass force to discard them:\n${changes}`);
	await git(["--git-dir", common, "worktree", "remove", ...(force ? ["--force"] : []), path]);
	await git(["--git-dir", common, "worktree", "prune"]);
	await pruneEmpty(dirname(path));
	return { removed: path, common_git_dir: common, forced: force, discarded: changes };
}

export async function pruneEmpty(dir: string) {
	const top = dirname(stateRoot());
	for (let current = dir; current.startsWith(stateRoot()) && current !== top; current = dirname(current))
		if (!(await rmdir(current).then(() => true, () => false))) return;
}

async function describe(path: string) {
	const [top = "", common = "", head = ""] = (
		await git(["-C", path, "rev-parse", "--show-toplevel", "--path-format=absolute", "--git-common-dir", "HEAD"])
	).split("\n");
	if (top !== path) throw new Error(`${path} is not a worktree root`);
	const listing = await git(["--git-dir", common, "worktree", "list", "--porcelain", "-z"]);
	const main = listing.split("\0\0")[0]!;
	const privateDir = (await git(["-C", path, "rev-parse", "--absolute-git-dir"])).trim();
	// Separate git dirs need not contain a backlink to their main checkout.
	const hint = await readFile(join(privateDir, "pi-delegate-main-worktree"), "utf8").catch(() => undefined);
	let main_worktree: string | null = null;
	if (!main.split("\0").includes("bare")) {
		for (const candidate of [hint, main.split("\0")[0]!.slice("worktree ".length)]) {
			if (!candidate || !isAbsolute(candidate)) continue;
			const actual = await git(["-C", candidate, "rev-parse", "--show-toplevel", "--path-format=absolute", "--git-common-dir"]).catch(() => "");
			if (actual === `${candidate}\n${common}\n`) { main_worktree = candidate; break; }
		}
	}
	return { path, common_git_dir: common, main_worktree, head };
}

export async function listWorktrees() {
	const root = await realpath(worktreeRoot()).catch(() => undefined);
	if (!root) return [];
	const groups = await readdir(root).catch(() => []);
	const paths = (await Promise.all(groups.map(async (group) => (await readdir(join(root, group)).catch(() => [])).map((id) => join(root, group, id))))).flat();
	return Promise.all(
		paths.map(async (path) => {
			try {
				const entry = await describe(path);
				return { ...entry, dirty: (await git(["-C", path, "status", "--porcelain"])) !== "" };
			} catch (error) {
				return { path, error: (error as Error).message };
			}
		}),
	);
}

export async function resolveWorktree(path: string) {
	const root = await realpath(worktreeRoot());
	const real = await realpath(path);
	const rel = relative(root, real);
	if (!rel || isAbsolute(rel) || rel.split(sep)[0] === "..") throw new Error(`${real} is not inside the worktree root ${root}`);
	return describe(real);
}

export async function cwdHolders(path: string) {
	const pids = await Promise.all(
		(await readdir("/proc"))
			.filter((name) => /^\d+$/.test(name))
			.map(async (name) => {
				const cwd = await readlink(`/proc/${name}/cwd`).catch(() => "");
				return cwd === path || cwd.startsWith(path + sep) ? [Number(name)] : [];
			}),
	);
	return pids.flat();
}
