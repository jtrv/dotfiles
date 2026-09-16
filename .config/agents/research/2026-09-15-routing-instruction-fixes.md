# Routing instruction fixes — 2026-09-15

## Decision and evidence

Shared routing lives in `../AGENTS.md`. Comparative tier placements need a
leaderboard snapshot. Dispatch corrections and strongest-tier escalation need
tool evidence and a rationale: they do not establish a comparative ranking.
Repeated failed attempts go to Astra because the existing routing policy names
it as the strongest Codex tier, and another attempt should test an alternative
explanation with the accumulated evidence. This is an escalation policy, not
a claim that a benchmark proves the best rescue model. Luna, Terra and Sol
placements were not re-ranked in this review.

Local checks:

- `codex features list` reports `multi_agent stable true`.
- The installed Codex bridge's `agents/codex-rescue.md` leaves its model unset
  by default. The old Claude routing row did not select Astra explicitly.
- This session's `spawn_agent` contract forbids model overrides with omitted
  or `all` history forks. It permits `none` or a positive turn count. The
  shared dispatch rule uses `none` and a self-contained brief.
- `skills/grind/SKILL.md` implements its headless variant with `claude -p`.
  Pi's installed `extensions/delegate.ts` registers an in-session tool with
  runners `pi` and `codex`, and modes `read-only` and `write`. Its default is
  read-only. Pi leads the skill's in-session loop with one write child per
  task and inspects the result before continuing.
- The original shared rule required strongest-model involvement only before
  committing a weaker model's draft. Loaded files take effect before commit,
  so weaker-model drafts must stay outside loaded instruction and skill paths.
- All review entry points are user-invoked. The Pi dispatch cell must say so.

## Benchmark wording

Primary pages fetched on 2026-09-15:

- [DeepSWE](https://deepswe.datacurve.ai/) exposes output tokens, agent steps
  and cost. Step count alone does not measure context consumption or runtime.
- [RealSWE](https://realswe.withspecific.com/) describes licensed production
  codebases whose code and solutions are unavailable on the public internet.
  That does not establish universal absence from model training data.
- [Artificial Analysis](https://artificialanalysis.ai/agents/coding-agents)
  provides runtime and token measurements. Its runtime definition excludes
  environment startup and verification overhead; it is not total elapsed time.
- [BenchLM](https://benchlm.ai/) distinguishes weighted ranking benchmarks
  from display-only benchmarks. A total benchmark count misstates what drives
  the aggregate score.

These checks support measurement guidance and wording, not a new tier order.

## Live verification

The three installed CLIs were launched from `/tmp`, asking from startup
instructions only: which model handles repeated failures, what evidence it
receives, what it must be asked for, how Pi dispatches grind, and who invokes
Codex reviews. The prompt supplied none of those answers and prohibited tools.

- Pi exited before answering: settings lock creation failed with `EROFS`,
  followed by “No API key found for the selected model.”
- Codex exited before answering: initialization of its in-process app-server
  failed with a read-only filesystem error.
- Claude timed out after 90 seconds (exit 124), without output.

Live loading is unverified for failed invocations. Logs and the prepared
Claude-only patch are in `/tmp/routing-fixes/`. The sandbox permits edits in
`~/.config/agents` but rejects writes to `~/.config/claude/CLAUDE.md`.

## Files to preserve in dotfiles

No staging or commits were performed. The edited shared files are `AGENTS.md`,
`contexts/harnesses.md`, `PLUGINS.md` and the untracked `pi.md`. This report and
`research/README.md` are also untracked. The Claude-only patch still needs to
be applied to `~/.config/claude/CLAUDE.md` in a writable session.

Existing untracked dependencies referenced by these docs include
`research/2026-08-25-post-counting-agent-turns.md`, the other reports listed in
the research index, and Pi's `extensions/instructions.ts`, `delegate.ts`,
`delegate.test.ts` and `caveman.ts`. Preserve those authored files when staging
the related work; do not sweep vendored skills or package caches into the index.

Other untracked reports in the index:

- `research/2026-07-07-last30days-context-optimization-plugins-raw.md`
- `research/2026-07-30-context-rot-persistent-memory.html`
- `research/2026-07-30-last30days-codebase-architecture-analysis-raw.md`
- `research/2026-07-30-last30days-context-rot-raw.md`
- `research/2026-07-30-last30days-persistent-memory-raw.md`
- `research/2026-08-15-post-sharpening-the-harness.md`
- `research/2026-09-10-pi-delegate-launcher-report.md`
- `research/2026-09-10-pi-subagents-last30days.md`
- `research/2026-09-10-pi-subagents-options.md`
- `research/2026-09-15-pi-delegate-gaps-effort.md`
- `research/lessons-from-memory.md`
- `research/subagent-delegation-advisor-pattern.md`

Validation: reviewed the task-only diffs against pre-edit copies;
`git diff --check` passed for edited tracked files, and the cached diff was
byte-identical before and after this work. The three harnesses' answers remain
unavailable; startup-path inspection alone does not satisfy live acceptance.
