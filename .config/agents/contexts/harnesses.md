# harnesses

Changes to the coding agents themselves — Claude Code, Codex, Pi — meaning their
config dirs, plugins, skills, extensions and the wiring that keeps the three
pointed at one source of truth. `../PLUGINS.md` is the inventory of what is
installed where and what each harness's equivalent is; this file is the rules
for changing it.

## Never stage vendored skills

`skills/MANIFEST.md` records which skills are third-party. Those are
reinstallable from upstream and are deliberately **untracked** — only
hand-written skills belong in dotfiles. The manifest has always said so; saying
it there was not enough, which is why the rule lives here too.

A vendored skill is large: `color-expert` is 181 files, `last30days` 175,
`vercel-optimize` 155. Eleven of them once reached the index at 698 files,
burying a 68-file change that was the actual work. Nothing warns you — there is
no ignore rule, and `config status` on a swept directory looks like progress.

So: **name paths explicitly.** Never `config add` a directory at or above
`~/.config/agents/skills`. The standing dotfiles rule against `git add -A`/`.`
is the same rule; this is the place it gets violated.

Before committing anything under `~/.config/agents`:

```sh
config diff --cached --name-only -- "$HOME/.config/agents/skills"
```

Expect roughly one `SKILL.md` per hand-written skill. Hundreds of files, or any
name listed in `skills/MANIFEST.md`, means vendored content was swept in —
unstage it (`config restore --staged <absolute paths>`, which leaves every file
on disk) before going further.

`graphify` is a useful canary: it is vendored, so if it ever shows up staged,
something added a directory wholesale.

## Adding a skill

Claude and Pi symlink the whole `skills` directory, so a new skill is visible to
them the moment it exists. **Codex does not** — it takes per-skill symlinks,
because `$CODEX_HOME/skills/.system` holds its own bundled skills and is
re-extracted per version, so pointing the whole directory at ours would write
Codex's system skills into the dotfiles tree. Re-link after adding one:

```sh
cd "$CODEX_HOME/skills" && for d in ~/.config/agents/skills/*/; do
  ln -sfn "$d" "$(basename "$d")"; done
```

`skills.extra_roots` looks like the tidy alternative and is not — the key does
not exist, and Codex ignores it silently rather than erroring, so a session
looks configured while loading nothing.

## Adding a plugin

For a port of a named upstream tool, only that upstream's own package counts. A
third party repackaging someone else's service under its name is a different
trust decision — especially anything that would hold API access to an account —
and those stay unadopted no matter how many downloads they have. Generic
plumbing with no upstream to be from (LSP and MCP bridges) is exempt.

Record the result in `../PLUGINS.md` either way. A dash there means *checked and
nothing suitable exists*, which is worth as much as an install — it stops the
next session re-researching it. Deferred adoptions get a probe in `../watches/`;
the research behind a decision goes in `../research/` (see its README), and
the decision points back at it.

## Changing a routing table

The routing table (in `../AGENTS.md`, read by every harness) decides which
model does which kind of work, so where a model sits in it follows published
agentic-coding results, not vibes or a model's launch post:

- **DeepSWE** (deepswe.datacurve.ai): pass@1 on long-horizon tasks, with
  agent steps, output tokens and cost per task, plotted per effort level.
  The rendered page shows one effort per model; every effort row is in
  `https://deepswe.datacurve.ai/artifacts/v1.1/leaderboard-live.json`
  (`rows[]`, keyed by `model` and `reasoning_effort`), which `curl` + `jq`
  reads directly. Use
  pass rate to compare capability. For near-ties, compare output tokens,
  measured runtime and cost under comparable settings. Steps are another
  signal; fewer steps alone prove neither less context use nor less wall time
  (see `../research/2026-08-25-post-counting-agent-turns.md`).
- **RealSWE** (realswe.withspecific.com): real engineering tasks in private
  codebases licensed from companies, with code and solutions unavailable on
  the public internet. Use it to check that a DeepSWE ranking
  holds up outside public repos before trusting a tier for real work.

Two aggregators are secondary references, for cross-checks and for models the
two above have not scored yet:

- **Artificial Analysis** (artificialanalysis.ai/agents/coding-agents): a
  coding-agent index with runtime and token measurements. Check its current
  component suites and measurement definitions before comparing results.
- **BenchLM** (benchlm.ai): an aggregate benchmark reference. Read its agentic
  and coding results and their weights; the headline score does not order
  coding tiers on its own.

When sources disagree, or a model has no entry, say so in the table's
justification rather than picking whichever number suits. Comparative tier
placements require a dated report in `../research/` with the leaderboard
snapshot (date, rows, harness, effort level) they relied on; point the table
at it. Dispatch corrections, wording fixes and strongest-tier escalation
policies require evidence and a rationale, but not a leaderboard snapshot:
they address tool contracts or the cost of repeated failure, not tier ranking.
Record that evidence in a dated report and link it from the affected rule.
Benchmarks measure a model under their own harness; an observed failure of a
tier in this setup outranks a leaderboard position.

Dispatch and escalation rationale:
`../research/2026-09-15-routing-instruction-fixes.md`.

## Verify wiring, do not assume it

A symlink that silently loads nothing looks identical to one that works. After
changing how a harness finds instructions or skills, ask that harness something
answerable only from the file you just wired up — a tool named in `AGENTS.md`,
a skill name — rather than trusting that the path looks right.

Codex's home is `$CODEX_HOME` (`$XDG_CACHE_HOME/codex`), not `~/.config/codex`
as sorting by name would suggest. Confirm with `codex doctor` before editing
anything, or you will edit a config nothing reads.

## Adding a Pi extension

Pi loads **every** `.ts` file in `$PI_CODING_AGENT_DIR/extensions/`, tests
included. A test file there needs a default no-op export and must register its
tests only under a test runner (`delegate.test.ts` is the pattern), or Pi runs
it at every startup. A subdirectory is loaded only when it has an `index.ts`,
`index.js`, or a `package.json` with `pi.extensions`
(`pi-coding-agent/dist/core/extensions/loader.js`, `resolveExtensionEntries`).
That is what makes `delegate/` a safe home for the modules `delegate.ts`
imports: it has neither, so nothing in it is an extension. Add an `index.ts`
there and Pi will load it as one.

Pi provides `@earendil-works/pi-ai`, `pi-tui`, `pi-coding-agent` and `typebox`
to extensions through its own loader. Standalone `bun test` cannot resolve them,
and `bun install` of the current Pi packages is refused by the bun
`minimumReleaseAge` guard for a week after each Pi release — `file:` copies then
fail on their transitive deps for the same reason. So keep anything a test
imports free of runtime imports from the `pi-*` packages (`import type` is fine;
`StringEnum` is a one-liner over typebox, reimplement it), and resolve `typebox`
through `$PI_CODING_AGENT_DIR/package.json` as a `file:` dependency pointing at
Pi's own copy. `node_modules` and `bun.lock` there are ignored.

Verify by interrogation after any change: a `pi -p` prompt that must call the
tool and print its result, one per runner.

## Changing `delegate`

Tests run from the extensions dir: `bun test ./delegate.test.ts`, then
`oxlint delegate.ts delegate/*.ts delegate.test.ts`. `tsc --noEmit` needs a
scratch tsconfig pointing at Pi's global `node_modules`; none is committed.

Background delivery cannot be observed with `pi -p`: print mode disposes the
session when the prompt ends, which emits `session_shutdown` and cancels every
background job, so no result message ever appears. Drive `pi --mode rpc` from
a script instead. Scripted `pi -p` runs need stdin closed (`</dev/null`); one
that inherited a harness's stdin socket waited on it for ten minutes and looked
like a broken worktree.

Results go out as `pi.sendMessage` custom messages, never `sendUserMessage`,
which is refused during compaction. Delivery runs only when `ctx.isIdle()`
(that check already excludes compaction), flushed on `agent_settled` and again
one tick after `session_compact`/`session_compact_failed`, because Pi fires
those before clearing its compacting flag.

The kill sweep finds a job's tree by the `PI_DELEGATE_RUN` env marker plus a
`/proc` PPID walk: SIGTERM, 2 s grace, then SIGSTOP and SIGKILL. SIGTERM is not
optional — print-mode Pi cleans up its detached bash children only on that
signal. Known escape: a process that scrubs its environment (Codex does, for
its MCP servers) and is reparented before the first scan is unreachable;
cgroups would close it and were deliberately not built. Codex exits 0 on
SIGTERM, so a killed job is detected from the result's `error`/status, never
from `exit_code`.

Test repos live outside `$HOME`, where git has no identity (it comes from the
`includeIf "gitdir:~/"` includes) while global `commit.gpgsign` is on. Make
base commits with `-c commit.gpgsign=false -c user.email=x@y -c user.name=x`,
or a worker's failed commit looks like a sandbox effect — it did, once.

## Antigravity only relocates by flag

`agy` hardcodes `~/.gemini`, reads no `*_HOME` variable and ignores
`XDG_CONFIG_HOME`. The one knob is `--gemini_dir`, which is not in `--help`
(it is in the binary's strings) and moves config and state together:
`--app_data_dir` exists but refuses absolute paths. The `agy` fish function
passes `--gemini_dir=$XDG_CONFIG_HOME/gemini`; a wrapper script under the
same name would not survive, because `~/.local/bin/agy` is the real binary
and the auto-updater replaces it. Anything that spawns `agy` outside fish
must pass the flag itself (`delegate/child.ts` does), or the run silently
recreates `~/.gemini` and loads none of the shared files.

If an update drops the flag the function fails loudly (unknown flag), which
is the wanted outcome. Login lives in the system keyring, not the directory,
so relocating never needs a re-auth.

Inside that directory `GEMINI.md` and `antigravity-cli/skills` are symlinks to
`AGENTS.md` and `skills/`; a whole-directory link is safe because agy keeps
its bundled skills apart in `antigravity-cli/builtin/`. Verify with a prompt,
not a listing: asked to list its skills, agy names only the bundled ones even
while a shared skill is loaded and invocable.

Headless agy has no read-only mode. A tool it cannot prompt for is soft-denied
and the run then prints nothing at all, so delegate children pass
`--dangerously-skip-permissions` (with `--sandbox`: workspace-scoped writes,
no network) and `<gemini_dir>/config/hooks.json` is the gate:
`hooks/agy-pretool.sh` reads `PI_DELEGATE_MODE` from the child's env and
denies everything outside a read-tool allowlist in read-only mode, then runs
`block-secrets.sh` on every string argument. A PreToolUse hook that returns
`{}` denies — the decision field is not optional — so the pass case has to
say `allow` (children, already unprompted) or `ask` (interactive sessions).
Workspace `.agents/hooks.json` did not fire from an untrusted directory; the
global file did.

## context-mode writes to `~/.claude`, `~/.codex`, `~/.pi` unless told otherwise

Its adapters fall back to those literal paths: the Pi adapter ignores
`PI_CODING_AGENT_DIR` outright, the Codex-side copy runs the Claude cache-heal
step regardless of platform and needs `CLAUDE_CONFIG_DIR` to aim it, and per-
process stats default to `~/.codex/context-mode`. The one knob that moves all
of it is `CONTEXT_MODE_DIR` (`env.fish` sets `$XDG_STATE_HOME/context-mode`).
It is ignored in silence if the value is empty, relative, or the directory
does not exist — so the directory is created there too.

Codex does pass its launching env to plugin MCP servers, so the shell variable
is enough for Codex; a partial `[mcp_servers.context-mode.env]` table in
`config.toml` is not an option — Codex validates it as a standalone server and
refuses to load. Anything that spawns a harness with an env allowlist
(`extensions/delegate.ts`) has to forward `CONTEXT_MODE_DIR`, `CLAUDE_CONFIG_DIR`
and the `XDG_*` vars, or the child recreates the home-dir litter.

A long-lived `codex app-server` (the Codex plugin's companion daemon) keeps the
env it was born with; after changing these variables, kill it so the next
dispatch respawns it clean.
