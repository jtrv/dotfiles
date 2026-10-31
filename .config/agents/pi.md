# Pi-only instructions

Everything shared with other agents lives in `AGENTS.md`. This file is the Pi
counterpart of the Claude-only half of `~/.config/claude/CLAUDE.md`. Which model
takes which work is the routing table in `AGENTS.md`;
`extensions/instructions.ts` appends this file to the system prompt.

## Delegation
Use the `delegate` tool for independent refuters and Codex-tier workers. The child
receives only the task; include its inputs and acceptance check there, without
parent reasoning. Use `runner=pi` for a fresh Pi child, `runner=agy` for a Gemini one, or `runner=codex` with a
tier from the routing table. User and project AGENTS.md rules remain enabled.
Read-only is the default; choose `mode=write` explicitly for implementation
workers. For `grind`, lead the in-session loop and inspect each child's result
before dispatching the next task, using the skill's checks and stop conditions.
The child is prompt-blind, not file-blind: it can read transcripts, memory and
plans on disk, so do not count on it for isolation from those.

Foreground when the next step needs the result; `background: true` when there
is other work meanwhile. The result arrives as a `delegate-result` message, or
sooner via `delegate_jobs wait`. In print mode (`pi -p`) the session ends with
the prompt and cancels background jobs, so `wait` on every job before
finishing. At most 2 model children run at once — foreground, background and
batch together; a call over the cap is rejected with nothing started, so
finish or `wait` on one and retry. `tasks` batches two children only when
neither needs the other's output; the batch is admitted or rejected whole.

Two writers on one checkout collide: give each `worktree: true`. Worktrees are
pinned to HEAD, so a child never sees your uncommitted changes — commit first
or put the content in the task. They survive the job; review the diff there,
then `delegate_jobs remove_worktree`. Codex workers cannot commit in a worktree
and Pi workers commit unsigned, so the lead commits worker output.

`shell_bg` is for builds, servers and watchers, not model work: it takes no
delegate slot and has its own cap of 4. Run a server as the command itself,
never `server &` — the job's whole process tree is killed when the command
exits. `notify_on` (a literal substring) reports readiness; `delegate_jobs
tail` reads the log.
