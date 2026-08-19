---
name: grind
description: >
  Work through PLAN.md's execution queue mostly hands-off: a lean lead session dispatches
  one fresh-context subagent per task, each verifying and committing its own work.
  Use when the user says "grind", "grind through the plan", "work through the
  backlog", "run the plan", or asks for autonomous execution of a task list on a
  long-running project. For fully unattended overnight runs, offers a headless
  bash-loop variant instead.
---

Ralph-style execution inside one session: the lead never implements — it
dispatches. Each task gets a fresh subagent context (the anti-rot property);
the lead accumulates only short reports.

## Setup

1. The backlog is the `## Execution queue` section of PLAN.md at the project
   root: an ordered `- [ ]` checkbox list where each task is one-session-sized,
   independent where possible, and has a concrete acceptance check.
   - PLAN.md exists but has no such section (e.g. it's a design/vision doc):
     APPEND the section — never rewrite or reorganize the existing content.
   - No PLAN.md: create one containing just the section.
   - Grind only ever edits inside `## Execution queue` (and its `### Log`).
   A `- [D]` item is a human decision — skip it, never dispatch it.
2. Determine the verify command once: from CLAUDE.md, justfile/Makefile, or
   project type (Rust: `cargo nextest run` + `cargo clippy --all-targets -- -D warnings`).
   Record it at the top of the Execution queue so subagents and future
   sessions agree.
3. Confirm scope with the user before the first dispatch (task count, verify
   command, stop conditions). After that, run without asking.

## Loop

For each first-unchecked task, dispatch ONE subagent (Agent tool, default
type) with this brief — filled in, not referenced:

> Implement exactly this task, nothing else: <task text>.
> Verify with: <verify command>. Do not stop until verify passes or you are
> genuinely blocked.
> Commit only the files you changed, message `<type>: <task summary>`.
> FORBIDDEN: git stash, git reset, git checkout/restore on paths outside your
> changed files, or any tree-wide git state change.
> Watch-fors: <task-specific values/conditions to report verbatim, e.g. "the
> exact error if migration X fails", "final count of Y" — omit line if none>.
> Return ≤20 lines: DONE or BLOCKED(reason); files changed; tail of verify
> output as evidence; each watch-for answered verbatim; ANOMALIES: one line,
> anything that deviated from expectations even if unexplained (or "none");
> DISCARDED: one line, what you chose not to report. No narrative.

On the report:
- **DONE** → check the box in PLAN.md, append one line to a `## Log` section
  (task, commit type, date). Do not read the diff — the verify tail is the evidence.
- **BLOCKED** → mark the task `- [!] <task> — <reason>`, move to the next task
  that doesn't depend on it. If the reason looks like ran-out-of-room rather
  than a genuine blocker, re-dispatch ONCE at a changed configuration — higher
  effort first, model tier second, or split the task — with the failed-attempt
  summary in the brief. Never re-dispatch the same configuration.

Sequential by default. Parallelize only clearly independent tasks, and then
each agent works in its own `git worktree` (EnterWorktree / worktree isolation),
never a shared tree.

## Stop conditions

- All boxes checked → summarize: tasks done, commits made, anything marked `[!]`.
- Two consecutive BLOCKED → stop and surface both reasons; don't burn iterations.
- Lead context getting heavy after many tasks → invoke the `handoff` skill and
  tell the user to resume grinding in a fresh session (PLAN.md carries the state).

## Headless variant (unattended / overnight)

When the user asks for fully unattended, don't loop in-session. Write
`grind.sh` into the repo instead and hand it to them:

```bash
#!/usr/bin/env bash
# One fresh claude process per iteration = fresh context per task.
MAX=${1:-25}
for i in $(seq "$MAX"); do
  grep -q '^- \[ \]' PLAN.md || { echo "plan complete"; break; }
  claude -p "Read PLAN.md. Do exactly the first unchecked task. Verify with the command recorded in PLAN.md; commit only your changed files; check the box; append one Log line. If blocked, mark the task [!] with the reason. Then stop." \
    --permission-mode acceptEdits
done
```

Recommend running it from a dedicated `git worktree` so an unattended agent
never touches the main working tree. Note the trade-off honestly: headless
gets no interactive judgment between tasks; the in-session loop lets the user
glance at reports and intervene.
