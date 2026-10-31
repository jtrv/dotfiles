# Pi delegate build — closing the delegation gaps

*2026-09-15. Built by sequential Opus 5 subagents, each step verified by the lead before the next. Spec: `2026-09-15-pi-delegate-gaps-effort.md`. Per-step return docs lived in the session scratchpad; the decisive evidence is copied here.*

## Outcome

The Pi `delegate` extension now covers five gaps that separated it from Claude Code's delegation:

| # | Gap | What shipped | Lead's own live check |
|---|---|---|---|
| 1 | Timeout/abort left descendants alive | Tree sweep: random env marker `PI_DELEGATE_RUN` + `/proc` PPID walk; SIGTERM, 2 s grace, then SIGSTOP+SIGKILL; `runDelegate` resolves only after the sweep | A Pi child's `sleep 300` (started through Pi's bash tool, own process group) was dead after a 25 s timeout; the pre-fix code left the same sleeper alive |
| 2 | No background runs, no progress | Job registry; `background: true`; `delegate_jobs` (list/result/cancel/wait); `/delegate`; footer; progress from Pi `--mode json` and `codex exec --json`; idle-only `pi.sendMessage` delivery | Background Codex Luna job: list `running`, wait `LEAD-BG-OK`, 12 s end to end |
| 3 | No fan-out | `tasks[]` of 1–2, atomic admission against the shared cap of 2, settled semantics, one aggregate notice | Mixed Codex + Pi batch returned `LEAD-A`, `LEAD-B` in order; agent measured 5.4 s total vs 9.7 s sequential |
| 4 | No worktree isolation | `worktree: true` — supervisor-created detached worktree at one pinned SHA, fail closed, kept after the job, `list_worktrees`, `remove_worktree` (by job id or path, guarded) | Pi child wrote only inside its worktree; main repo status unchanged; forced removal clean. A repo with no HEAD failed closed |
| 5 | No background shell / monitor | `shell_bg` — `bash -c`, own cap of 4, 8 MiB log, `tail`, one-shot literal `notify_on`, exit notice | `notify_on` match + wait: exit 0, full tail, log deleted at shutdown |

Polish after step 5 (lead): delegate children run with `GIT_CONFIG_COUNT=1 / commit.gpgsign=false` so Pi workers can commit (unsigned, normal identity); empty `pi-delegate` state directories are pruned. Live: a Pi worker in a `~/` repo committed as `jtrv <…noreply…>` with signature status `N`.

Final size: production 1468 lines across `delegate.ts`, `delegate/child.ts`, `delegate/worktree.ts`, `delegate/shell.ts`; tests 964 lines, 5 tests, all passing; `oxlint` and `tsc --noEmit` clean. Every step ran deliberate mutations (negative controls) to show its tests fail when the new code is broken — 16 in step 5 alone.

## Estimates vs reality

My first estimate for items 1–4 was ~200 lines with tests; Astra's review said 300–500 production + 550–900 test. Actual: ~1030 production + ~690 test through step 4, ~1450 + ~940 with the shell tool. Both estimates were low: production came in at roughly 2–3× Astra's 500-line upper bound (tests landed within its range). The growth was lifecycle, admission and delivery correctness, not spawning. A later review (`2026-09-15-pi-delegate-review.md`) found the lifecycle guarantees still incomplete.

## Findings worth keeping

- **Codex spawns outside its process group** (sandbox, bwrap, MCP servers in their own sessions/groups). None outlived a group kill in testing, but the sweep does not rely on that.
- **Codex exits 0 on SIGTERM.** Detect kills from status/error, not exit code.
- **Codex sandbox and git worktrees:** `git status` works; `git add`/`commit` fail — `index.lock` under the main repo's `.git/worktrees/<id>/` is on a read-only mount. Codex workers leave uncommitted changes; the lead commits.
- **`pi.sendUserMessage` is refused during compaction**; `pi.sendMessage` custom messages with `triggerTurn` are the delivery path. `ctx.isIdle()` already excludes compaction, but Pi fires compaction events before clearing its flag, so the flush waits one tick.
- **`pi -p` cancels background jobs at prompt end** (print mode emits `session_shutdown`). Delivery is only observable end to end with `--mode rpc`. Scripted `pi -p` hangs on an open stdin.
- **Pi's extension loader** loads subdirectories only with `index.ts`/`index.js` or a `package.json` declaring `pi.extensions`; plain module directories are safe.
- **Git identity is directory-scoped** (`includeIf gitdir:~/` → personal, `~/work/` → work); repos under `/tmp` have none. Global `commit.gpgsign` is on.

## Decisions

- **Built background shell rather than adopting `pi-background-tasks`:** its peer range excludes Pi 0.85.1, it has no line-match notification, it bundles an Anthropic attribution extension, and its `bg_delegate` passes a projection of the parent conversation (not blind).
- **Unsigned worker commits** (user's choice) over forwarding `GNUPGHOME`: signing from a headless child fails whenever gpg-agent's passphrase cache is cold.
- **A surviving descendant marks a job `failed`** even with a good answer, so a worktree is never removed under a live writer.
- **Fetched results are not also notified; tree navigation cancels jobs; foreground batches throw only when every child failed; no `partial` state.**
- **Out of scope:** filesystem read isolation for refuters (children are prompt-blind, not file-blind); cgroup containment (the env-scrub-and-reparent escape stays open); restart-surviving jobs.
