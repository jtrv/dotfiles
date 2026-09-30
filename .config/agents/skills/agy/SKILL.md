---
name: agy
description: >
  Use when a session in any harness (Claude Code, Codex, Pi) should hand a
  self-contained task to a Gemini worker through the Antigravity CLI (`agy`) —
  a cross-family second opinion, a review by a non-Anthropic and non-OpenAI
  model, a bounded read-only investigation, or a parallel fan-out of
  independent questions. Also use when the user says "ask gemini",
  "run this through agy", "antigravity", or "agy subagent".
---

# agy: Gemini subagents from any harness

`scripts/agy-run` runs one headless `agy` turn and prints only the final
response. Everything else (stream events, auth prompts, tool chatter) stays
out of the conversation. Read-only is the default.

## Quick reference

```sh
S=~/.config/agents/skills/agy/scripts
$S/agy-run "TASK"                              # read-only, 600 s timeout
$S/agy-run --write "TASK"                      # edits and shell allowed
$S/agy-run --model gemini-3.8-flash-medium "TASK" # effort is part of the id; `agy models` lists them
$S/agy-run --timeout 120 --add-dir /other "TASK"
$S/agy-run - < brief.md                        # long task from stdin
```

Exit 0 and stdout = the worker's answer. Non-zero = no answer; stderr has why
(auth, timeout, agy error, gate missing). A one-line stats summary always goes
to stderr.

One shell call per task, from whichever harness is steering the session
(Claude Code Bash, Codex shell, or Pi's `delegate` with `runner=agy`, which
wraps the same script). Independent tasks go in parallel calls. Anything likely
over two minutes runs in the harness's background mode and is read back when it
finishes. Argv is the only prompt channel, so `--` before a task that starts
with `-`.

## The task brief

The worker sees only the task, plus the shared `AGENTS.md` and skills. Write a
brief a stranger could act on: inputs as absolute paths, the question or change
wanted, and the acceptance check. No parent reasoning. Set hard boundaries:
"view X once, then answer; do not open other files, search, or run commands."
Without them Flash explores until the timeout and returns nothing (measured:
never finished at 300 s unbounded, about a minute bounded). Start at
`gemini-3.8-flash-medium`; use `-high` only when medium misses; never `-low`. Routing and
evidence: `research/2026-09-16-gemini-3-8-flash-routing.md`. Tell it to `cd` to the
repo in any command it runs — agy executes shell commands in its own scratch
directory, not the launch cwd, so relative paths in commands break. Ask for the
result shape you want (verdict first, then evidence).

## Modes and safety

Headless agy has no read-only flag and soft-denies unprompted tools into
silence, so the script passes `--dangerously-skip-permissions` and the
`PreToolUse` gate in `<gemini_dir>/config/hooks.json` (`hooks/agy-pretool.sh`)
is the enforcement: it reads `PI_DELEGATE_MODE`, allows only read tools in
read-only mode, and runs `block-secrets.sh` on every argument in both modes.
The script refuses to launch if that gate is not wired.

`--write` is unsandboxed: full workspace edits, shell and network. Use it on a
branch or worktree you can throw away. `--sandbox` (agy's own jail) is passed
through but dies on this machine while installing its CA bundle — see
`research/2026-09-15-agy-sandbox-diagnosis.md` before relying on it.

## Setup

- Binary: nixpkgs `antigravity-cli` (unfree; `mainProgram` is `agy`). The
  `antigravity` package is the IDE, not the CLI.
- Sign in once interactively: run `agy --gemini_dir=$XDG_CONFIG_HOME/gemini`
  with no prompt. Headless runs never prompt; unauthenticated ones exit 1 with
  `authentication failed or timed out`.
- Config lives in `$XDG_CONFIG_HOME/gemini` only because the script passes
  `--gemini_dir`; a bare `agy` recreates `~/.gemini` and loads none of the
  shared files. `AGY` and `AGY_GEMINI_DIR` override the binary and directory.
- Self-check after editing the script: `scripts/agy-run.test.sh`.

## When not to use

- Work that needs the parent's context or a conversation: use the harness's
  own subagent (the dispatch table in `AGENTS.md`). agy gets one task and
  returns one answer.
- Codex tiers from the routing table: the `Codex <model>` dispatch row.
- Tasks over 96 KiB: the prompt rides in argv (process-visible, size-capped);
  put the material in files and reference the paths.
