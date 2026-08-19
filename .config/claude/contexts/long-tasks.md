# Long-running & multi-session tasks

The transcript is ephemeral; the workspace is authoritative.

## Ledger (any task spanning sessions or > ~1 hour)
- Work on a task branch. Two files, split by lifecycle: `plan.md` — stable
  numbered steps, edited rarely; `state.md` — volatile cursor, replaced
  in-place: objective, decisions (mark accepted/provisional/superseded —
  never delete, summaries resurrect deleted decisions), failed attempts (so
  they aren't retried), evidence pointers, and exactly ONE next executable
  action. It's a cursor, not a report — written deliverables trend long by
  default, and a state.md nobody rereads is worse than none.
- Every "done" claim cites evidence (commit hash, passing test output).
- Commit the ledger WITH the code at milestones. Crash recovery = checkout
  last milestone + read state.md.
- Refresh state.md at milestones, before any /compact, and at session end —
  not per tool call.

## Compaction & handoff
- Prefer handoff over repeated compaction: at session end make state.md a
  self-contained restart packet (goal, current state, decisions, failed
  attempts, next action); the next session starts fresh and reads it.
- Compact deliberately and steer it (`/compact keep <the load-bearing thing>`)
  — never ride to auto-compact. Trigger on the harness's own pressure warning,
  not a fixed fraction: `~60%` was a 200k-window number and the window is now
  1M. Bigger windows don't repeal context rot, they just move the threshold.
- Checkpoint-before-compact: refresh state.md → compact → re-read state.md.
  After any compaction, distrust the summary's version of decisions and
  constraints; the ledger is the record.
- Check the next three actions after compacting, and check for what's
  *missing*: compaction damage is ~90% omission, and it surfaces within about
  three steps or arrives later as confident, coherent, wrong behaviour.

## Stuck vs slow
- Repetition is evidence of stuck; elapsed time is only evidence of expense.
  Silence with a growing diff is work; silence with byte-identical tool calls
  is not.
- Thresholds worth copying (shipped defaults, nobody's measured optima):
  identical action+observation ×4, action+error ×3, agent monologue ×3,
  alternating A→B→A→B ×6, over the last 20 events. The alternating check is
  the one that catches test-result oscillation.
- When a fix fails, change approach — don't rerun it. Looping runs reuse
  commands; successful ones diversify after the first error.
- Raise the turn ceiling before diagnosing the agent. Budget expiry
  *mid-progress* is the most common long-task failure, and a low cap
  manufactures it.
- **Three ways a run ends; don't conflate them.** Repetition → kill. No output
  for N → kill (N above the slowest legitimate operation: full suite, emulator
  boot, CI wait). Per-task budget → *graceful stop*, tell it to checkpoint and
  finish. Never kill on total runtime: it converts progressing runs into
  failures and takes the state.md refresh with it.
- "Done" cites state — exit code, diff, test output. A second model's opinion
  is not verification: judges barely beat chance at spotting a false success,
  and agents over-claim most when they've failed.

## Subagent quarantine
- Noisy work (repo exploration, log analysis, research sweeps, adversarial
  review) goes to subagents; only conclusions return to the main window.
  Anything smaller is cheaper inline — the default pull is to over-delegate.
- Each gets a bounded contract: scope, output shape, max return size, evidence
  required for claims. Cap the *dump*, never the finding count — "only report
  high-severity" and a low result cap are both read literally, and the agent
  reports less rather than filtering better. Filter in a second pass.
- **Watch-fors:** the dispatcher names the specific values, files, or
  conditions the agent must report verbatim. Significance is defined by
  dispatcher foresight, not agent judgment — judging what matters is exactly
  what a cheap fresh-context agent is worst at.
- Reports also carry two one-liners: **anomalies** — anything that deviated
  from expectations, reported even without an explanation (spotting weirdness
  is the agent's job; judging its importance is the dispatcher's) — and
  **discarded** — categories of output it chose not to report, so exclusions
  are visible decisions the dispatcher can veto.
- An agent that exhausts its budget never gets the same configuration with a
  bigger budget. Budget exhaustion is a routing decision: raise effort, raise
  model tier, split the task, or revise the plan — effort first, it's the
  cheaper lever. Feed the failed-attempt summary into the next dispatch.
- Fan-out agents get a written state brief (what's already known, what's
  been tested-and-rejected, "do not re-report X") so they return only
  deltas — and "nothing new" is declared a valid answer.
- Bulky agent results persist to files; the agent returns a pointer, not
  the dump.

## Memory hygiene
- Past-session recall: `deja "<query>"` searches all local agent transcripts
  (Claude Code + Codex); `deja show <id>` expands a hit. Pull-only — prefer
  it over re-deriving something a prior session already solved.
- Nontrivial memories carry source and date; re-verify a recalled fact
  before acting on it (files move, flags change, tools die).
- Record tested-and-rejected approaches WITH the evidence, so future
  sessions don't re-litigate them; new evidence is the only reopener.
