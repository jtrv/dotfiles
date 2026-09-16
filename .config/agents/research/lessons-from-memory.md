# Lessons from session memory

A digest of what past sessions learned about running these agents, pulled from
the per-project memory files under `~/.config/claude/projects/*/memory/` and
the `.remember/` daily logs. Each entry names its source so the original can
be checked; the sources stay where they are. Dates are when the lesson was
learned, not when it was copied here.

## Context rot and memory — the July 2026 sweep

*Sources: `~/tmp/claude/.remember/today-2026-07-31.done.md`, `archive.md`; report in this directory as `2026-07-30-context-rot-persistent-memory.html`; raws `2026-07-30-last30days-*.md`.*

Six agents (web, social, Codex) researched context-rot prevention for LLM
coding agents. Consensus: **handoff over compaction** — a fresh session primed
by a written handoff beats another compaction cycle. Anthropic's own 80%
system-prompt cut and `/doctor` were the reference points. Memory tools
surveyed: claude-mem, deja-vu, Beads.

Four candidate tools were then evaluated in depth and all rejected:
`post_compact_reminder` (redundant with the SessionStart hook),
`planning-with-files` (+68% per-turn injection overhead, confirmed by
recitation), Beads (Dolt migration instability), and the upstream
`handoff-skill` (judged clean but unmaintained — vendored instead of
installed).

What shipped from it: the `handoff` skill (vendored synthesis, `[V]`/`[?]`
verify protocol) and the `grind` skill — one fresh-context subagent per queue
item, because the ralph-loop plugin lacks the fresh-context property and
planning-with-files was rejected for its injection tax.

## Refutation as a standing protocol

*Sources: `~/repos/zhulong-theme/REFUTATION.md` (2026-08-06), `~/repos/flect/reports/flect-refutation-2026-07-29.html`, quickword memory `workflow-verify-and-refute.md` (2026-07-29), shiso memory `refute-the-refuters-numbers.md` (2026-08-04).*

The protocol that became `plan-refute`: one refuter per load-bearing claim,
**context asymmetry** (the refuter gets the claim and its sources, never the
planner's reasoning), a kill mandate, cross-model where possible (Codex
refuters for code-fact claims, web-research refuters for literature claims,
direct runnable checks where a claim can simply be executed). The user's
standing rule from quickword: never present a plan as final without a
refutation table; the user distrusts single-model agreement.

The refinement from shiso: a refuter's quantitative kill is only as good as
the constants the plan handed it. Before dispatching, mark which numbers are
*derived* from the design and which the plan simply chose; refuters test the
derived ones, and the chosen ones get swept across their real range first.
The case: a "+4.2%" verdict that was really about an arbitrary 1.25 factor.

## How work is split between models

*Sources: shiso memory `mise-model-split.md` (2026-07-28), `mise-agent-batch-protocol.md` (2026-07-30), `mise-decision-bundling.md`, `mise-render-for-decision.md` (2026-08-16); `subagent-delegation-advisor-pattern.md` in this directory (2026-08-15).*

The main session plans, decides, verifies and converges; implementation goes
to subagents with a full brief — file ownership, house rules, measured
starting point, expectations, and "report what contradicted the brief".
Verify an agent's headline claims before relaying them; well-briefed workers
repeatedly caught the main loop's diagnosis errors, which is the argument
for the split.

Parallel batches: a written brief in, a written return doc out, and the
orchestrator reads **only** the return doc — never the transcript. The
reason is the same context asymmetry as refutation: a reviewer anchoring on
the author's reasoning is how correlated errors survive. One owner per shared
file per wave; workers make no tree-wide git operations and no commits; the
lead runs the single gate after the wave settles and commits in file-disjoint
groups.

Decisions are bundled, not raised mid-task: push everything that does not
depend on an open question, bank the questions, and end with one concise
report plus one multi-choice batch. UI taste calls get real rendered variants
from the capture rig, never prose descriptions — and never Codex, which
cannot run Flutter.

The advisor-pattern document generalises this into tiers (mechanical →
haiku/low, everyday → sonnet/medium-high, cross-cutting → opus/xhigh,
code-against-approved-plan → codex) with the rule that raising effort is a
cheaper lever than jumping tiers.

## Codex as a delegation target

*Sources: shiso memory `codex-dispatch.md` (2026-07-31), `codex-sandbox-limits.md` (2026-08-10); vellum memory `codex-plugin-operational-notes.md` (2026-08-27); this directory's `2026-09-10-pi-delegate-launcher-report.md`.*

- Dispatch through the plugin's rescue path; never hand-roll
  `codex exec --full-auto` in a subagent — the permission classifier reads it
  as an approval-disabling loop and blocks it.
- The rescue subagent is a pure forwarder: it returns a job handle and may
  not poll. Poll from the main session with the companion script's `status`
  and `result`, and arm the wait only after every job is launched or the loop
  exits on a momentary gap. The job record can vanish on completion; keep the
  log path.
- The sandbox mounts `.git` read-only (no commits), has no network, and
  cannot open the Flutter test harness's loopback socket. Every brief says:
  leave changes uncommitted, list the gates you skipped. Its SDK copies fill
  the 16 GB `/tmp` tmpfs — check `df /tmp` before dispatch and sweep after.
- Codex's upstream classifier kills security-framed turns mid-run
  ("adversarially verify" plus attacker vocabulary). Phrase review work as
  verification.
- Pass `--effort` explicitly; do not trust a default that lives in a config
  file you may not be reading.

## The permission classifier and Agent dispatch

*Source: shiso memory `agent-dispatch-classifier-blocks.md` (2026-08-15); upstreamed to the Claude-only `CLAUDE.md`.*

During a grind wave the classifier blocked a handful of dispatches while
thirty near-identical ones passed. The pattern: loop and load-test phrasing,
scraping-adjacent wording. One honestly reworded retry, then do the task in
the main loop or park it — never disguise a task to slip past.

## Skills built from research, and what was cut

*Sources: tmp-claude memory `geiger-skill.md` (2026-07-29/30), `grind-skill.md`, `handoff-skill-vendored.md` (2026-07-31).*

geiger (architecture audit) recorded its rejected branches so they are not
re-proposed: folder-level metric aggregation fabricated cycles and was cut;
the regex fallback extractor was removed; a repair phase, few-shot exemplars,
self-consistency voting and commit untangling were all closed with evidence.
Calibration between Claude and Codex on identical protocol reached 83%
agreement after criteria were tightened. PairSmell (arXiv 2411.01012) is the
peer-reviewed backing for the hidden-coupling premise.

## Harness plumbing that cost a day each

*Sources: tmp-claude memory `herdr-codex-state-hook.md` (2026-08-11); `../contexts/harnesses.md` (2026-09-10).*

- Claude Code picks up newly added hooks in a running session — measured,
  contrary to the "snapshotted at startup" belief.
- The Notification hook also fires for the 60-second "waiting for your
  input" notice, not only permission prompts; anything wired to it needs to
  filter that.
- Codex's real home was the cache directory, not the config directory that
  sorting by name suggested; half an hour of edits went to a file nothing
  read. `codex doctor` first.
- Pi loads every sibling `.ts` in `extensions/`, tests included; a
  config key that does not exist is ignored in silence. Verify wiring by
  interrogation, never by inspection.

## Pi delegation — September 2026

*Sources: `2026-09-10-pi-subagents-options.md`, `2026-09-10-pi-subagents-last30days.md`, `2026-09-10-pi-delegate-launcher-report.md` in this directory.*

Delegation pays for read-heavy, separable work and loses on sequential
work; equal-compute single agents match multi-agent debate; debate is not
blind review because the exchange happens before independence ends. No Pi
package gives a structurally blind child or fail-closed writes, so the
independence boundary is owned: a `delegate` tool whose child receives only
the task. Package adoption for everyday fan-out remains optional on top.
