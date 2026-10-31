# Pi delegate gaps and effort review — 2026-09-15

## Verdict

The direction is sound, but **“~200 lines including tests” is optimistic**. Basic progress and two-way fan-out are small; reliable background delivery requires session ownership, cancellation, retained results, and compaction handling. Worktree creation is straightforward only after lifecycle and process cleanup are dependable. I estimate **300–500 additional production lines and 550–900 test lines** for a narrow implementation of 1–4, excluding strict filesystem confidentiality and stronger descendant containment. `pi-background-tasks` supplies completion notifications, but its inspected public API has no line-match watcher, its manifest excludes Pi 0.85.1, and installation introduces substantially more than shell backgrounding.

## Effort table

Incremental estimates above the existing launcher; tests include shared integration coverage separately.

| Item | My grade—your estimate | Your grade—my assessment | Prod lines | Test lines | Biggest risk |
|---|---|---|---:|---:|---|
| 1. Background runs | Easy–medium; ~60 | **Medium** | 120–180 | 160–240 | Lost or misrouted completion during compaction/session replacement |
| 2. Parallel fan-out | Easy; ~20 | **Easy**, for an atomic batch of at most two | 35–60 | 70–110 | Partial dispatch and incorrect global capacity accounting |
| 3. Live progress | Easy; ~30 | **Easy** for Pi only; **medium** for both runners plus task controls | 60–100 | 100–160 | Treating streaming updates as durable job state |
| 4. Worktree isolation | Medium; ~50 + tests | **Medium**, with cleanup prerequisites | 80–140 | 130–220 | Deleting uncommitted work or allowing surviving writers |
| 5. Background shell | Medium build; trivial install | **Medium** build; package adoption **easy–medium, unverified** | 100–180 shell; +50–100 matching | 140–240; +80–140 matching | Package mismatch, log limits, notification semantics |
| Cross-feature coverage | Not included | Required | Included above | 80–140 | Background × cancellation × worktree races |

These are engineering estimates, not measured patch sizes.

## Evidence and scope

Verified locally:

- `pi --version`: **0.85.1**.
- `codex --version`: **0.153.4**.
- `codex exec --help`: supports **`--json`**.
- Read the installed launcher, test, Pi extension documentation, subagent example, ponytail implementation, harness rules, and both September 10 reports.
- Inspected context-mode’s installed Pi adapter.
- An existing linked worktree successfully ran read-only Git status.

**Not run:** launcher tests, authenticated children, worktree creation, package installation, or runtime integration tests. The existing tests create temporary files, which conflicts with this session’s filesystem restrictions and your report-only write scope.

Citation shorthand below:

- **Pi docs**: [installed `docs/extensions.md`](/home/sugimoto/.local/share/bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs/extensions.md).
- **Pi session**: [installed `dist/core/agent-session.js`](/home/sugimoto/.local/share/bun/install/global/node_modules/@earendil-works/pi-coding-agent/dist/core/agent-session.js).
- **Launcher**: [delegate.ts](/home/sugimoto/.config/pi/agent/extensions/delegate.ts).
- **CM**: [context-mode Pi adapter](/home/sugimoto/.config/pi/agent/npm/node_modules/context-mode/build/adapters/pi/extension.js).

## 1. Background runs

### API verdict

Your proposed call is valid:

```ts
pi.sendUserMessage(text, { deliverAs: "followUp" });
```

When idle, it starts a turn immediately. When streaming, it queues a follow-up after tool processing finishes. Ponytail uses precisely this distinction at `pi-extension/index.js:100–111`. **Pi docs, “pi.sendUserMessage”, lines 1439–1468.**

However, there are two consequential qualifications:

1. It creates an actual **user message**, and passes through `input` interception with source `"extension"`. Another extension can transform or consume it. **Pi docs, “input”, lines 911–958; Pi session:843–853, 1161–1188.**
2. Manual compaction rejects prompts before input handling. The extension-facing wrapper catches the asynchronous error and reports it through extension error handling; the caller does not receive a delivery acknowledgement. **Pi session:836–837, 2020–2027.**

### Implementation

Use one registry inside the extension factory:

```text
job ID → owner generation, controller, completion promise,
         state, progress, bounded result, worktree metadata
```

Do not start timers or children from the factory itself; start them when a tool runs. **Pi docs, “Long-lived resources and shutdown”, lines 220–224.**

Add `background?: boolean`. Separate admission/startup from awaiting completion:

1. Validate input and reserve capacity.
2. Register the job before asynchronous setup.
3. Start the child with its job-owned `AbortController`.
4. Return `{ job_id, status: "running" }` after successful spawn.
5. On completion, retain the bounded result and mark notification pending.
6. Deliver through a single session-owned completion pump.

Prefer a custom message:

```ts
pi.sendMessage(
  {
    customType: "delegate-result",
    content: formattedResult,
    display: true,
    details: { jobId },
  },
  { deliverAs: "followUp", triggerTurn: true },
);
```

This preserves provenance as an extension result. Custom messages participate in model context. **Pi docs, “pi.sendMessage”, lines 1416–1437; Pi session:1099–1135.**

For the smallest reliable version, **deliver only when `ctx.isIdle()`**, retaining completions while Pi is busy. Attempt a deferred flush after completion, `agent_settled`, and compaction success/failure. This avoids relying on follow-up delivery during retry/compaction transitions. `agent_end` is insufficient because automatic continuation may remain. **Pi docs:567–580, 1044–1046, 454–491.**

Keep results queryable through a small `delegate_status`/result action even after notification submission. The API is fire-and-forget; submission is not proof the model consumed the result.

Register idempotent shutdown cleanup:

- Mark the instance closed **before awaiting anything**.
- Abort every active job.
- Await bounded cleanup.
- Suppress callbacks and notifications from that generation.
- Clear footer state.

Shutdown covers quit, reload, new session, resume, and fork. **Pi docs:516–524; session replacement:432–450; reload:1318 onward.**

### Tests

Assert immediate handle return; fast-exit ordering; spawn failure; background capacity remaining occupied; retained failure results; cancellation; no unhandled rejection; exactly one notification submission; no delivery during compaction; delivery after settlement; and no old-session notification after reload/switch/fork.

**Estimate correction:** ~60 lines can implement launch-and-notify. It does not comfortably cover ownership, result retrieval, delivery suppression, and compaction.

## 2. Parallel fan-out

### Implementation

For the first version, accept **one task or a batch of one/two tasks**, retaining the existing individual fields within each task object.

Choose explicit semantics:

> A batch reserves all required slots atomically, or starts nothing.

Keep the global cap at two across **foreground and background children**, not two tool invocations. Count preparing jobs too. Validate the complete batch, reserve capacity synchronously, then begin setup.

Use settled outcomes so one failure does not abandon its sibling:

```text
validate → reserve N slots → start N independent jobs
         → await all settled → return results in input order
```

Background batches return a batch ID plus child IDs and produce one aggregate completion after both settle. No sibling output becomes another child’s input.

Pi’s official example contains a bounded worker mapper at `examples/extensions/subagent/index.ts:219–239` and uses it around line 645. That verifies the implementation pattern; it does not make its scheduler appropriate for this launcher.

### Tests

Assert:

- A third child never starts.
- A two-task batch with only one free slot starts neither.
- One rejected/failed child does not lose the other result.
- Results preserve input order despite reverse completion order.
- Batch cancellation reaches both children.
- Capacity returns after setup failure.
- Every child receives exactly its own task bytes.

### Estimate correction

~20 lines describes `Promise.all`, not admission and failure semantics. For **arbitrary `tasks[]`**, a queue introduces fairness, queued cancellation, deadlines, and bounded queue length: medium effort.

Codex rate limits are one operational ceiling. Local capacity, provider retries, CPU/memory, disk contention, and overlapping edits also constrain useful concurrency. No account-specific rate ceiling was measured.

I agree that pipelines, resume, and journals are outside the first build.

## 3. Live progress

### Implementation

Add a runner-neutral progress callback to `runDelegate`:

```text
child JSONL → bounded event parser → progress snapshot
            → registry → foreground onUpdate / footer / task listing
```

For Pi, consume:

- `turn_start` for turn count;
- `tool_execution_start` and `tool_execution_end` for active tool IDs/names;
- existing assistant `message_end` handling for final output.

Track a **set of active tools**, not one current tool: Pi supports interleaved tool execution. **Pi docs:600–673.**

JSON mode forwards session events; its conversion preserves non-`message_update` events. **`dist/modes/print-mode.js:84–87`; `dist/modes/json-event.js:16–28`.** Do not assume JSON `message_update` contains the same full message object as the extension hook.

During foreground execution:

```ts
onUpdate?.({
  content: [{ type: "text", text: summary }],
  details: progress,
});
```

This is documented at **Pi docs:1400–1403 and “Custom Tools”**. Stop invoking that callback once `execute` returns. Background progress belongs in the registry.

Use `ctx.ui.setStatus("delegate", summary)` and clear with `undefined`; guard UI calls with `ctx.hasUI`. **Pi docs:970–974, 2590–2591.** A compact `/delegate-tasks` command can list jobs and cancel one through its controller; commands use `pi.registerCommand`. **Pi docs, Quick Start:94–102.**

### Codex correction

**Codex is not limited to exit status.** Local help confirms `--json`; official documentation describes `turn.started`, `turn.completed`, `turn.failed`, and item lifecycle events, including command executions. Retain `--output-last-message` as the final-answer channel. [Codex non-interactive output](https://learn.chatgpt.com/docs/non-interactive-mode#make-output-machine-readable).

Do not present Codex turn counts as directly equivalent to Pi’s model/tool rounds. Report event-supported activity without inventing a percentage complete.

### Tests

Feed split JSON lines, multiple events per chunk, malformed input, oversized events, parallel tool starts/ends, and final output without a trailing newline. Assert bounded/throttled updates, separate job attribution, unchanged final capture, and no updates after completion.

**Estimate correction:** ~30 lines is credible for a Pi-only counter/footer prototype. Both adapters, bounded parsing, task listing, and cancellation exceed that.

## 4. Worktree isolation

### Implementation

The **Pi extension process provisions the worktree before launching Codex**:

1. Resolve repository root and a full base commit once per batch.
2. Reserve capacity.
3. Create a unique detached worktree through argument-array spawning:

   ```text
   git -C ROOT worktree add --detach ABSOLUTE_PATH BASE_SHA
   ```

4. Verify the resulting root and `HEAD`.
5. Recheck cancellation.
6. Launch with that exact cwd.
7. Return base SHA and worktree path with every terminal result.

No fallback to the original cwd. A creation, verification, or cancellation failure dispatches no model child.

Use the existing Node subprocess supervision or `pi.exec` for bounded Git operations; this needs no special Pi worktree API. **Pi docs, “pi.exec”.**

Keep **successful and failed writer worktrees** until manual review: a successful Codex worker may have only uncommitted changes. “Keep failed worktrees” alone would lose successful output if success cleanup removes them.

A pinned commit excludes the parent’s dirty/untracked changes. State that in the receipt; do not silently copy the parent worktree, which could also copy planning material.

### What `.git` protection breaks

A linked worktree has its own administrative directory under the common repository. Its `.git` file points there; index and HEAD operations therefore access that external directory. [Git worktree details](https://git-scm.com/docs/git-worktree#_details).

Upstream Codex source explicitly handles `.git` pointer files and protects the resolved gitdir, not merely the pointer file: `codex-rs/protocol/src/permissions.rs:2079–2098`. This is **upstream-source evidence**, not a verified match to the installed binary. [Codex permission implementation](https://raw.githubusercontent.com/openai/codex/main/codex-rs/protocol/src/permissions.rs).

Consequences:

- **Worktree creation inside the restricted worker:** expect failure when common Git metadata is not writable.
- **Creation by an unrestricted Pi supervisor:** unaffected by the child’s later sandbox.
- **Status/diff/rev-parse:** readable Git metadata remains usable; disable optional index writes with `GIT_OPTIONAL_LOCKS=0`.
- **Stage/commit:** require metadata writes and ordinarily fail under that protection.
- **“The lead commits”:** works only when the lead itself has appropriate Git metadata permissions.

Actual read-only verification: `/home/sugimoto/repos/dotfiles/.git` points to `/home/sugimoto/.config/dotfiles/worktrees/dotfiles`; status with optional locks disabled exited **0** on this session’s read-only filesystem. This verifies linked-worktree reading, not creation or worker writes.

### Tests

In an authorized disposable repository: assert a shared pinned SHA, distinct paths, unchanged main worktree, fail-closed creation, cancellation during setup, preserved uncommitted success/failure output, and correct handling when the supplied cwd is itself linked.

Add an actual Codex sandbox probe for file edits versus status/add/commit. Mocked Git results cannot establish sandbox behavior.

**Estimate correction:** ~50 lines is plausible for creation and cwd substitution. Retention, cancellation, verification, and integration tests make it larger.

## 5. Background shell and line-match notification

### Building it

Reuse the job registry and notification pump, with a separate shell-job tool:

- Explicit command, cwd, timeout, and optional literal line matcher.
- Detached subprocess and bounded output file under an absolute XDG state path.
- Job-owned log path, controller, read offset, partial-line buffer, and notification state.
- Completion message containing exit status and bounded tail.
- One-shot line-match notification while the process remains running.

Match incrementally across chunk boundaries; bound line length and notification count. Start with literal matching. Arbitrary regular expressions add execution-time and validation concerns.

Tests cover split lines, final unterminated lines, duplicate matches, output floods, log-write failure, cancellation, and completion/match ordering. Pi-facing APIs are the same `registerTool`, `sendMessage`, lifecycle handlers, and footer APIs verified above.

Detached spawning alone does not provide restart recovery. That would require additional supervision and persisted ownership.

### Package findings

| Question | Finding |
|---|---|
| Current version | npm page and upstream manifest show **2.5.0**; direct registry verification failed |
| Weekly downloads | npm page displayed **27,042**; Pi catalog displayed **15K/week**—not a verified common reporting window |
| Release date | Pi catalog reports **September 4, 2026** |
| Maintenance | Inspected commit history shows fixes/features and additional contributor activity; latest displayed commit was August 13, but the page was cached |
| Completion notification | **Yes**, including optional follow-up turn |
| Line-match notification | **No exposed matcher found** in inspected schema/options/registry |
| Restart survival | Live jobs are killed on shutdown/reload; persisted artifacts do not imply reattachment |
| Pi 0.85.1 compatibility | **Unverified; declared peer range excludes it** |

Sources: [npm package page](https://www.npmjs.com/package/pi-background-tasks), [Pi catalog](https://pi.dev/packages/pi-background-tasks), [commit history](https://github.com/ismailsaleekh/pi-background-tasks/commits/main/).

Direct requests to npm registry metadata and downloads endpoints failed through both web access and shell DNS. Therefore **the requested registry-backed current version/download verification remains incomplete**.

Completion is implemented through `pi.sendMessage` with follow-up delivery in `src/core/registry.ts:2185–2194`. Public shell options contain timeout and completion flags but no line matcher in `src/core/common.ts:228–237`. [Registry](https://raw.githubusercontent.com/ismailsaleekh/pi-background-tasks/main/src/core/registry.ts), [options](https://raw.githubusercontent.com/ismailsaleekh/pi-background-tasks/main/src/core/common.ts).

`bg_run` defaults to completion plus wake-up; `/bg` sets wake-up false. Shutdown kills running jobs. [Extension source:105–133, 459–498](https://raw.githubusercontent.com/ismailsaleekh/pi-background-tasks/main/src/extension.ts).

The manifest loads both background tasks and an Anthropic attribution extension. Its Pi peer range ends at `^0.84.0`, which excludes 0.85.1. [Package manifest:80–104](https://raw.githubusercontent.com/ismailsaleekh/pi-background-tasks/main/package.json).

Finally, its `bg_delegate` uses a frozen parent-conversation projection. **It cannot replace this launcher for blind refuters.** [README, workflow table](https://raw.githubusercontent.com/ismailsaleekh/pi-background-tasks/main/README.md).

**Estimate correction:** executing an install command is trivial. Establishing compatible, appropriately scoped adoption is not. The package does not close the line-match gap established here.

## Interactions and prerequisites

### Background capacity must follow children

Returning a handle must not release its slot. Count preparation, execution, and stopping until cleanup completes. Batch admission must share that same counter; independent per-batch limiters exceed the intended cap.

### Session switch, fork, and tree navigation differ

Switch/fork/reload tear down the old runtime, so cancel its jobs and suppress late callbacks. **Pi docs:432–450, 516–524.**

Tree navigation has separate events without the same shutdown sequence. For the first build, cancel and invalidate jobs on successful `session_tree`, or explicitly retain branch ownership and suppress automatic delivery onto another branch. **Pi docs, “session_before_tree / session_tree”, ending at line 512.**

### Context-mode will not automatically preserve late results

The installed adapter captures `tool_result`, builds a snapshot before compaction, and injects memory through `context`. It has no inspected `input`/`message_end` handler that captures arbitrary late delegate completions. A custom completion also is not the original tool’s result. **CM:469–530, 655–673, 742–769.**

Consequently:

- Keep job/result state independently of conversation history.
- Bound aggregate notifications as well as each child result.
- Include task identity, runner, base SHA, and worktree path in the completion.
- Keep a retrieval action available after compaction.
- Do not claim context-mode guarantees result retention.

`pi.appendEntry` can persist extension metadata without adding model context, but that still does not resume processes. It is unnecessary for the first in-memory-only build. **Pi docs:1473 onward.**

### Existing process-group cleanup has a writer-specific hole

The launcher kills the child’s process group with `SIGKILL`. Pi’s own Bash tool starts shell processes with `detached: true` on POSIX, creating another group. **Launcher:154–169; installed `dist/core/tools/bash.js:50–62`.**

Thus, “kills the child group” does **not** establish “kills every descendant.” The current fake-runner test uses an ordinary inherited-group grandchild and does not cover this case.

Pi print mode handles SIGTERM/SIGHUP by killing tracked detached children; SIGKILL bypasses those handlers. **`dist/modes/print-mode.js:31–44`.**

Before parallel writers, test graceful termination followed by bounded escalation. For a strict all-descendants guarantee, use OS containment such as a dedicated cgroup; a signal-only solution remains weaker. Never remove a worktree while a writer might survive.

### The strict refuter property is not currently enforced

The launcher guarantees it does not automatically pass parent history. Its own description explicitly disclaims filesystem read isolation. It forwards HOME/config paths, and children can read accessible parent transcripts, memory, or planning files.

Preserve the current boundary by keeping task-only stdin, no fork/resume, no sibling-output chaining, and no transcript-derived task expansion. But **literal inability to access parent conversation requires an additional filesystem boundary**: curated source visibility, excluded session/memory/state directories, controlled ambient configuration, and credentials exposed without exposing conversation storage.

Worktrees isolate edits; they do not isolate reads or shared Git history. Strong confidentiality is a separate prerequisite, excluded from the line estimates above.

## Recommended order and first-build scope

1. **Define ownership, admission, cancellation, and retained-result semantics.**
2. **Implement 3 and 1 together**, internally starting with progress parsing and foreground regression coverage.
3. **Add 2:** atomic batches of at most two, no queue or pipelines.
4. **Add 4 only after descendant cleanup is validated.**
5. **Evaluate 5 separately:** package compatibility and scope must be established; line matching remains additional work.

First build: read-only foreground/background delegation, Pi/Codex activity summaries, one compact task-list/cancel surface, bounded results, idle completion delivery, cancellation on session replacement/tree navigation, and no resume.

That is roughly **180–280 production lines plus 260–400 test lines** before fan-out and worktrees. It is a plausible focused implementation job with a writable test environment. Model size does not eliminate the lifecycle and sandbox verification work.

## Requested path and ten-line summary

**Intended path, unsaved:**  
`/home/sugimoto/.config/agents/research/2026-09-15-pi-delegate-gaps-effort.md`

1. Pi is 0.85.1; Codex is 0.153.4 and supports JSON events.
2. Background execution is medium effort once delivery and ownership are included.
3. Prefer custom completion messages; retain results independently.
4. Compaction can reject `sendUserMessage`; deliver after settlement.
5. A two-task atomic fan-out is easy; arbitrary queued batches are larger.
6. Progress is straightforward, but foreground callbacks cannot own background state.
7. Provision worktrees in the supervisor and retain uncommitted successful output.
8. Pi’s detached Bash children expose a gap in current group-kill coverage.
9. The shell package supports completion, but matching and 0.85.1 compatibility remain gaps.
10. Budget about 300–500 production and 550–900 test lines; neither report path was writable.
