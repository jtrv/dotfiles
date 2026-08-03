# Long-running & multi-session tasks

The transcript is ephemeral; the workspace is authoritative.

## Ledger (any task spanning sessions or > ~1 hour)
- Work on a task branch. Two files, split by lifecycle: `plan.md` — stable
  numbered steps, edited rarely; `state.md` — volatile cursor, replaced
  in-place: objective, decisions (mark accepted/provisional/superseded —
  never delete, summaries resurrect deleted decisions), failed attempts (so
  they aren't retried), evidence pointers, and exactly ONE next executable
  action.
- Every "done" claim cites evidence (commit hash, passing test output).
- Commit the ledger WITH the code at milestones. Crash recovery = checkout
  last milestone + read state.md.
- Refresh state.md at milestones, before any /compact, and at session end —
  not per tool call.

## Compaction & handoff
- Prefer handoff over repeated compaction: at session end make state.md a
  self-contained restart packet (goal, current state, decisions, failed
  attempts, next action); the next session starts fresh and reads it.
- Compact deliberately at ~60% full and steer it
  (`/compact keep <the load-bearing thing>`) — never ride to auto-compact.
- Checkpoint-before-compact: refresh state.md → compact → re-read state.md.
  After any compaction, distrust the summary's version of decisions and
  constraints; the ledger is the record.

## Subagent quarantine
- Noisy work (repo exploration, log analysis, research sweeps, adversarial
  review) goes to subagents; only conclusions return to the main window.
  Each gets a bounded contract: scope, output shape, max return size,
  evidence required for claims.
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
