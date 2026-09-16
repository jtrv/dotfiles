# Pi delegate build — Astra review (2026-09-15)

## 1. Verdict

**The extension does not meet the stated lifecycle guarantees.** Task-only stdin and atomic batch admission are implemented, but process discovery can miss even the root process, detected survivors become finished jobs, and worktree removal lacks durable ownership protection. There are also concrete hang paths, a symlink escape in worktree cwd selection, and unbounded pending-result retention. I reviewed the production paths, tests, documentation, and installed Pi 0.85.1 source; ran only read-only inspection and `/proc` benchmarks. No files were changed, and the mutating test suite was not run.

## 2. Findings

Paths below: `delegate.ts`, `delegate.test.ts`, and `delegate/*.ts` are under `~/.config/pi/agent/extensions/`; documentation paths are under `~/.config/agents/`.

| id | severity | verified/suspected | file:line | one-line issue |
|---|---|---|---|---|
| F1 | high | verified | `delegate/child.ts:148`, `:172` | Marker-dependent discovery can miss the root or descendants and mistake unreadable processes for dead ones. |
| F2 | high | verified | `delegate/child.ts:396`, `delegate/shell.ts:163`, `delegate.ts:350` | Detected survivors still produce terminal results and release capacity. |
| F3 | high | verified | `delegate.ts:503`, `:541`, `delegate/worktree.ts:108` | Worktree removal relies on local retained results and a non-atomic cwd scan. |
| F4 | high | verified | `delegate/worktree.ts:54` | A committed symlink at the requested subdirectory can send the worker outside its new worktree. |
| F5 | high | verified | `delegate/child.ts:417` | Model capacity is released before temporary-directory cleanup completes. |
| F6 | medium | verified | `delegate/child.ts:370` | Model cleanup waits for pipe closure; a descendant can delay it until the task timeout. |
| F7 | medium | verified | `delegate/child.ts:375`, `delegate/shell.ts:160` | A rejected termination sweep leaves the enclosing job pending and creates an unhandled rejection. |
| F8 | medium | verified | `delegate/worktree.ts:75` | Inferring the repository root from `dirname(git-common-dir)` breaks bare/separate-git-dir repositories. |
| F9 | medium | verified | `delegate.ts:266` | Pending notifications bypass retention limits, allowing unbounded results and logs. |
| F10 | medium | verified | `delegate.ts:409` | Progress throttling drops the last update without scheduling a trailing update. |
| F11 | low | verified | `delegate/shell.ts:140`, `delegate.ts:206` | Mid-run log-write failure is omitted from the completion notification. |
| F12 | medium | verified | `delegate.test.ts:150`, `:165`, `:99` | Tests can check stale PIDs; important CLI and Pi lifecycle assertions rely on self-comparison or fakes. |
| F13 | medium | verified | `pi.md:28`, `:35`, `contexts/harnesses.md:153` | Agent instructions overstate guarantees and omit safe integration of retained worktree output. |
| F14 | medium | verified | `delegate.test.ts:137` | `NODE_ENV=test` makes ordinary Pi startup execute the test suite. |

“Verified” means the conditional failure path was traced in source; it does not imply a live reproduction.

## 3. Finding details

### F1 — Process discovery is not a containment boundary

**Scenario:** A shell command executes `exec env -u PI_DELEGATE_RUN sleep 1000`. The root retains its PID but loses the marker. `terminate()` starts with an empty `known` map; signals—including the process-group signal—are sent only inside loops whose discovery result is nonempty. Timeout/cancellation therefore sends nothing. The cached empty sweep prevents another attempt. See `child.ts:172–188` and `shell.ts:120–131`.

A detached descendant that clears its environment and reparents before discovery likewise escapes. This is already acknowledged in `contexts/harnesses.md:169–171`; it remains a violation of the task’s strict guarantee.

Additionally, per-process read failures are swallowed at `child.ts:131–140`, and missing observations delete previously known identities at `:150`. Permission failures or descriptor exhaustion can be mistaken for successful cleanup.

**Smallest fixes:**

- Capture and retain the root’s PID/start identity independently of its environment.
- Bound scan concurrency; distinguish confirmed disappearance from failed observation.
- For the **whole-tree guarantee**, use kernel-maintained membership such as a delegated cgroup. A later PPID/environment snapshot cannot reconstruct vanished ancestry.

### F2 — Surviving processes are treated as finished jobs

**Scenario:** A sweep reaches its deadline with surviving descendants whose inherited pipes are already closed. Both runners return `unkilled_pids`, release their slots, and the registry sets `finished` plus `failed`/`cancelled`. Shutdown subsequently ignores them because `live()` only recognizes `starting` and `running`.

Evidence: `child.ts:396–419`, `shell.ts:163–182`, `delegate.ts:160`, `:349–352`, `:429`, `:479–485`.

**What goes wrong:** “Failed” becomes indistinguishable from “cleanup finished.” More jobs can start while old processes remain, violating both completion and capacity guarantees.

**Smallest fix:** Introduce a nonterminal cleanup-failed/terminating state. Keep its reservation and ownership until process membership is proven empty; expose the error without claiming completion.

### F3 — Worktree removal cannot establish absence of writers

**Scenario:** Another Pi session owns the worktree, or the owning result has been evicted. `owners()` knows only this registry. A writer whose cwd is elsewhere can still access the worktree through absolute paths or open descriptors, and `cwdHolders()` will miss it.

Even known survivor protection disappears after result eviction: `delegate.ts:268–275`, `:503–509`, `:542–548`. There is also a check/use interval between the cwd scan and Git removal.

**Smallest fix:** Preserve worktree ownership separately from result retention, shared across sessions. Hold an exclusive removal lease against job provisioning and ownership, and release ownership only after verified process cleanup. Keep cwd scanning as an additional diagnostic.

An unconditional guarantee against arbitrary unmanaged external writers requires stronger access isolation; cwd scanning cannot provide it.

### F4 — Worktree subdirectory validation follows symlinks outside

**Scenario:** HEAD contains `sub` as an absolute symlink to the original checkout. The original checkout has locally replaced that symlink with a directory, and delegation starts from that directory. `locate()` records `sub/`; the new worktree restores the committed symlink.

`provision()` validates the new root, then merely calls `stat()` on `resolve(path, prefix)`. `stat()` follows the symlink, and spawning from that path enters the original checkout. See `worktree.ts:27–30`, `:51–57`, and `delegate.ts:293–295`.

**Smallest fix:** Resolve the final cwd with `realpath()` and require it to remain within the canonical worktree root before launching. Reject an escape. This is source-verified; no repository fixture was created.

### F5 — Capacity returns before cleanup

`spawnChild()` calls `release()` before awaiting `rm(dir)` at `child.ts:417–419`. Another admission can reserve that slot while the earlier job still awaits cleanup.

**Smallest fix:** Release after required cleanup completes. Handle cleanup failure explicitly rather than making a failed deletion silently satisfy the “cleanup complete” condition.

This is high severity under the task’s explicit reservation-through-cleanup rule; it does not imply three model processes normally run simultaneously.

### F6 — Model exit can wait on descendants’ pipes

**Scenario:** A model runner exits after spawning a descendant that retains stdout/stderr. Node emits `exit`, but `close` waits for those pipes. The model runner starts its sweep only on `close`, so a successful answer can stall until the default 600-second timeout and then be reported as timed out.

Evidence: `child.ts:312–315`, `:370–378`. Shell jobs already handle this correctly at `shell.ts:152–154`.

**Smallest fix:** Start model cleanup on `exit` too, retaining the existing single-sweep guard and waiting for both stream completion and cleanup.

### F7 — Sweep rejection can hang the job indefinitely

`readdir("/proc")` can reject outside the per-process catches. Neither runner handles rejection of `sweep`; both attach fulfillment-only handlers to resolve their outer promises. See `child.ts:127–128`, `:375–378`, `shell.ts:160`.

**What goes wrong:** The job never settles, while the rejected derived promise is unhandled. Cancellation, shutdown, and reload can hang.

**Smallest fix:** Handle termination rejection immediately. Surface cleanup failure while retaining ownership/reservation; ensure every promise branch has an explicit outcome. Do not convert an observation failure into “no survivors.”

### F8 — Bare and separate Git directories break removal

`describe()` returns `repo_root: dirname(common)` at `worktree.ts:80`. For a linked worktree of a bare repository, the common directory **is** the repository; its parent is not. Separate-git-dir layouts have the same invalid assumption.

`removeWorktree()` subsequently runs `git -C` against that invented root at `:63–64`.

**Smallest fix:** Retain the actual common Git directory and perform administrative commands with `git --git-dir <common>`. Do not infer a working-tree root by removing one path component.

### F9 — Retention limits exclude the backlog

**Scenario:** Pi remains busy while repeatedly launching background jobs. Completed jobs have `notify: pending`, so `evict()` never counts them toward the limit. Shell logs can accumulate indefinitely.

Evidence: `delegate.ts:266–275`; the “24 retained logs” claim is at `shell.ts:14`. Collection or flushing also does not immediately invoke eviction (`delegate.ts:241–260`, `:430–435`).

**Smallest fix:** Put a hard bound on outstanding retained entries, including pending notifications. Reject new admissions when that budget is exhausted rather than dropping notifications; evict eligible entries after collection/delivery too.

### F10 — Progress can remain stale throughout a long tool call

A `turn_start` update is emitted. A tool starts milliseconds later, so its update is discarded by the 500-ms throttle. If the tool runs for minutes without further progress events, no update ever says it is running.

Evidence: `delegate.ts:341–344`, `:409–413`.

**Smallest fix:** Keep the latest snapshot and schedule one trailing update when throttled. Clear that timer on completion/shutdown. Preserve the immediate leading update if desired.

### F11 — Logging failure disappears from the notification

**Scenario:** The log opens successfully, then disk space runs out. `writeSync` failure sets `logError`, but a command exiting zero still becomes `done`. The retained result has `log_error`; the completion formatter omits it.

Evidence: `shell.ts:140–143`, `:165–178`; `delegate.ts:206–215`, `:481–485`.

**Smallest fix:** Include `log_error` in completion text and distinguish failed output capture from intentional size truncation. The command’s successful exit need not be rewritten as failure.

### F12 — Tests leave important failure modes unprotected

**False-pass/flakiness:** `delegate.test.ts:165–175` sleeps 150 ms and reads a shared `grandchild` file. The second iteration can read the previous job’s already-dead PID. The first can fail before the file exists.

**Smallest fix:** Use a unique launch directory or readiness token; assert the current descendant is alive before cancellation; then verify that same identity disappears.

Other consequential coverage gaps:

| Evidence | Gap | Smallest improvement |
|---|---|---|
| `delegate.test.ts:150–151` | Expected argv comes from production `buildArgs()` itself. | Pin independent expected argv, especially isolation flags. |
| `:72–79`, `:99–125` | Model executables and Pi delivery/lifecycle are simulated. | Keep a small real RPC integration check for settlement, compaction, and reload. |
| `:49–51` | Model orphan fixture uses ignored stdio. | Add an orphan retaining stdout to catch F6. |
| `:598–618`, `:710–727` | Real Git coverage lacks the bare/separate-git-dir and symlink-prefix cases. | Add focused fixtures for F4/F8 and cross-session ownership. |
| `:902–914` | Logging failure coverage tests opening the log, not writing after opening. | Inject a write failure after successful startup. |

**Why ~20 seconds is plausible:** Several tests deliberately incur the real two-second SIGTERM grace, alongside real Git operations, subprocess startup, sleeps, and a 20 MB output fixture (`:177–194`, `:295`, `:359–364`, `:884–892`, `:918–921`). I did not independently time the suite.

The duration comparison at `:431` and exact throttled-update count at `:439` are scheduling-sensitive. Replace timing expectations with synchronization. Keep one real grace-period integration case; use a controllable clock for repeated state-machine cases.

### F13 — Instructions overstate guarantees and omit an integration step

- `pi.md:29` says a child “never sees” uncommitted changes, although `:16–17` correctly acknowledges filesystem visibility. The **new checkout** excludes those changes; the child can still read them elsewhere.
- `pi.md:30–32` moves from reviewing the worktree to removing it without explicitly transferring committed/uncommitted output. A Pi worker may already have committed, making plain `git diff` empty.
- `pi.md:35–37` promises whole-tree cleanup despite F1/F2.
- `contexts/harnesses.md:153–155` says no background result can ever appear in print mode. Pi emits `agent_settled` before the original prompt returns, allowing an already-pending result to be submitted before disposal: installed `dist/core/agent-session.js:772–784`, `:347–351`; `dist/modes/print-mode.js:104–138`. Print mode is unsuitable for reliable background delivery, but “never” is too strong.

**Smallest fix:** Use the exact replacements in section 5. Documentation changes alone do not repair the core guarantees.

### F14 — The test-runner guard also matches normal processes

At `delegate.test.ts:137`, `NODE_ENV === "test"` registers the entire suite. Pi loads this `.ts` file during ordinary extension discovery; therefore launching Pi from a test-configured environment can run tests that change process environment, create repositories, and launch children.

**Smallest fix:** Move the test file outside the extension-discovery directory. Alternatively, require an actual runner-specific signal rather than the generic application environment.

## 4. Simplification proposals, ranked by savings versus risk

Estimates are net production lines; they overlap and should not be added mechanically.

| Proposal | Evidence | Estimated saving | Risk |
|---|---|---:|---|
| Share the narrow subprocess supervision routine: timer, abort listener, exit/close coordination, termination outcome. Keep runner-specific I/O separate. | `child.ts:296–381`; `shell.ts:111–162` | 35–55 | Medium; lifecycle ordering must remain explicit. This also prevents the F6 divergence. |
| Extract common job initialization/finalization and ready-promise handling for model and shell jobs. | `delegate.ts:301–363`, `:436–495` | 20–35 | Medium; startup rejection, batch notification, and shell match state differ. |
| Shorten tool dispatch and batch progress construction with named local functions. | `delegate.ts:654–664`, `:691–704` | 10–20 | Low; preserve parameter validation and error behavior. |
| Remove redundant model reassignment/onSpawn argument: preparation already resolves the model. | `child.ts:261`, `:360`; `delegate.ts:319`, `:334–336` | 3–6 | Low. |
| Remove `Batch.started`/`finished` and derive elapsed time from children where needed. | `delegate.ts:135–136`, `:183`, `:370`, `:376` | 2–5 | Low, but little benefit; skipping this cut is reasonable. |

**Do not simplify away** generation tracking, atomic reservation, separate readiness/completion, or notification state. Those represent different obligations.

### Performance evidence

The requested command, `ls /proc | grep -c '^[0-9]'`, returned **4**. The benchmark subsequently saw **3** processes: the pipeline itself changes the count. This is the sandbox’s visible process namespace, **not a verified count of the host desktop’s processes**.

A read-only Node benchmark ran 100 repetitions of equivalent scan operations:

| Operation | Median | p95 | CPU per scan |
|---|---:|---:|---:|
| `/proc` enumeration + stat/environment reads and marker check | 0.119 ms | 0.276 ms | 0.286 ms |
| `/proc` enumeration + cwd readlinks | 0.054 ms | 0.121 ms | 0.088 ms |

No environment contents were printed. The first benchmark excludes the ancestry-closure loop.

- At this tiny process count, 20 scans/second costs roughly **0.6% of one CPU core per sweep**. That is not a useful host-scale benchmark.
- With **N** visible live processes, each ordinary scan performs roughly **2N file reads**. At nominal 20 Hz, that is **40N reads/second per terminating job**. At 1,000 processes: about 40,000 reads/second; force-phase iterations scan twice (`child.ts:182–184`).
- Actual frequency is lower because each iteration takes scan time **plus** 50 ms. Concurrent job termination multiplies the work.
- `cwdHolders()` is one scan per removal, not a 50-ms loop (`worktree.ts:108–117`).

**Other hot paths:**

- `lineSplitter()` repeatedly searches the growing unfinished line from the beginning (`child.ts:205–209`). Large JSON lines have quadratic cumulative scanning across chunks; the 8 MiB limit bounds the damage. Keep a search offset.
- Foreground UI callbacks are throttled, but JSON parsing and progress-map copies are not (`child.ts:322–334`).
- Shell logging uses synchronous disk writes on Pi’s event loop (`shell.ts:139`). The 8 MiB cap bounds bytes, not individual write latency.
- Tail reads are appropriately bounded to 64 KiB, or 8 KiB for completion (`shell.ts:20`, `:74–87`, `:175`).
- `listWorktrees()` starts Git subprocesses across all discovered entries concurrently (`worktree.ts:87–95`). Bound this fan-out if retained worktrees accumulate.

## 5. Doc fixes — exact replacement text

### Replace `pi.md:28–32`

> Two writers on one checkout collide: give each `worktree: true`. The new checkout starts at a pinned HEAD and excludes uncommitted and untracked changes; include required changes in a commit or in the task. Worktrees survive the job. Review both commits since `base_sha` and uncommitted changes, integrate the wanted output into the target checkout, then use `delegate_jobs remove_worktree`. Codex workers cannot commit under the current worktree sandbox configuration; Pi workers commit unsigned.

### Replace `pi.md:34–38`

> `shell_bg` runs builds, servers and watchers with a separate cap of 4. Run a server as the command itself, never `server &`; command exit starts descendant cleanup. Cleanup currently uses best-effort process discovery, so it is not a containment guarantee. `notify_on` matches a literal substring in an output line. `delegate_jobs tail` reads the stored log, which stops recording after 8 MiB.

### Replace `contexts/harnesses.md:153–158`

> Use RPC to verify background delivery across idle, compaction and shutdown transitions. Print mode disposes the session when its prompt sequence returns, so outstanding jobs are cancelled; an already-pending completion can race with disposal. In `pi -p` runs, collect required results before finishing. Close stdin in scripted runs that provide the prompt through arguments.

### Replace `contexts/harnesses.md:166–173`

> Termination currently discovers processes through `PI_DELEGATE_RUN` and `/proc` ancestry, then sends SIGTERM followed by SIGSTOP/SIGKILL after the grace period. This is best-effort: sanitized, reparented descendants can escape, and the current implementation also fails to seed the root independently of its marker. Neither a returned sweep nor a terminal job state currently proves all descendants are gone. Preserve SIGTERM handling for Pi’s detached-bash cleanup. For Codex, determine cancellation from status/error rather than exit code alone.

### Replace the first two sentences of `contexts/harnesses.md:124–127`

> Pi loads top-level `.ts` extension files, including test files. Keep tests outside that discovery directory; `NODE_ENV=test` does not reliably distinguish a test runner from ordinary Pi startup.

The opening explanation in `pi.md:3–6` can also be removed if system-prompt tokens matter: it describes wiring rather than changing an agent’s decision.

## 6. Anomalies

- **Estimate arithmetic:** `research/2026-09-15-pi-delegate-build.md:23` calls the earlier upper bound “right,” despite approximately 1,030 production lines through step 4 versus a 500-line upper estimate. Test size was within the estimate. This is a reporting inconsistency, not a code defect.
- **Displayed cwd differs from execution cwd:** worktree jobs retain the original cwd in their list view while the result contains the execution cwd (`delegate.ts:320`, `:175`, `child.ts:409`). `worktree_path` helps, but the two meanings deserve explicit names.
- **After log truncation, “tail” is the end of the retained prefix**, not recent process output (`shell.ts:135–144`). The replacement documentation above makes this explicit.
- **Relative removal paths are accepted** and resolved against the supervisor process cwd (`worktree.ts:102`), not explicitly against `ctx.cwd`. Canonical containment still applies; an absolute-only contract would be less surprising.
- Git helper calls have a 60-second `execFile` timeout but no job cancellation signal (`worktree.ts:14–18`, `delegate.ts:293–294`). Cancellation during provisioning can therefore wait for Git. Hook-descendant behavior was not traced far enough to classify an additional finding.

## 7. Discarded / checked without another finding

- **Parent/sibling prompt leakage:** each child receives its own `input.task` through stdin; batches do not feed sibling results into later tasks (`child.ts:380`, `delegate.ts:396–415`). Filesystem confidentiality remains explicitly outside the implementation.
- **Ordinary failed-worktree fallback:** provisioning rejection does not launch in the original cwd (`delegate.ts:290–299`, `:330–348`). F4 is a separate canonical-path escape.
- **Batch admission versus background slots:** validation precedes synchronous all-or-none reservation (`delegate.ts:396–406`, `child.ts:265–270`). The accounting failures concern cleanup, not normal admission.
- **Removal prefix traversal:** canonicalization and component-based containment reject ordinary `..`, sibling-prefix, and symlink-to-outside escapes (`worktree.ts:100–105`).
- **Normal notification duplication/busy delivery:** the pending-state checks and synchronous idle check are consistent with Pi setting its active flag synchronously when delivery starts (`delegate.ts:241–254`; installed `dist/core/agent-session.js:772–773`, `:1099–1121`). No independent duplicate-send race was found.
- **Normal shutdown/reload ownership:** `closed` is set before awaiting cancellation, and Pi awaits shutdown before invalidating/reloading the extension (`delegate.ts:602–609`; installed `dist/core/agent-session.js:2217–2225`). F2/F7 break exceptional cleanup.
- **Normal descriptor/timer cleanup:** final-message and tail descriptors have `finally` cleanup; wait timers are aborted; child timers/listeners are removed on close. No separate normal-path leak found.
- **RPC/UI separation:** status updates check `hasUI`; background delivery is not dependent on the interactive footer (`delegate.ts:617–621`).
