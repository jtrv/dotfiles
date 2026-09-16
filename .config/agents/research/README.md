# Research on how we set up and use our agents

The home for research reports about the harnesses themselves — Claude Code,
Codex, Pi — their plugins, skills, delegation patterns and context handling.
Reports a session produces land here rather than in a scratchpad that dies
with the session. Rules for *changing* the harnesses live in
`../contexts/harnesses.md`; the inventory of what is installed where is
`../PLUGINS.md`; deferred adoptions get a probe in `../watches/`. This
directory holds the evidence those files cite.

Conventions: date-prefix reports with the day the research was done
(`YYYY-MM-DD-topic.md`); undated files are living digests. Raw `/last30days`
output is kept with a `-raw` suffix; its processed counterpart, when one
exists, carries the same date. Nothing here is tracked as a source of truth —
a decision belongs in `PLUGINS.md`, a context file, or a skill, with a
pointer back to the report that justified it.

## Index

### Digests
- `lessons-from-memory.md` — what past sessions learned about running these agents, pulled from per-project memory and the `.remember` logs, each entry with its source.

### Delegation and subagents
- `2026-09-16-gemini-3-8-flash-routing.md` — why Gemini 3.8 Flash gets a bounded one-shot row and nothing more: leaderboard snapshot (DeepSWE, RealSWE, Artificial Analysis incl. Omniscience, BenchLM), 30-day sentiment, and local `agy` probes where the unbounded run never finished.
- `2026-09-16-last30days-gemini-3-8-flash-raw.md` — the raw sweep behind it.
- `2026-09-15-routing-instruction-fixes.md` — routing contract checks, strongest-tier policy, benchmark wording, and live interrogation limits.
- `2026-09-10-pi-subagents-options.md` — Astra research: Pi delegation packages ranked, literature on when multi-agent helps (Kim et al. 2026, Anthropic's research system, Cognition's counter-essay, MAST), the minimal-launcher option, adoption plan and risks.
- `2026-09-10-pi-subagents-last30days.md` — 30-day sentiment sweep on subagents in terminal coding agents; Pi's creator's position, the fragmented `pi-subagents` namespace, practitioner convergence on read-heavy fan-out only.
- `2026-09-15-pi-delegate-review.md` — Astra review of the finished build: 14 findings (process discovery can miss the root, survivors released as finished, worktree ownership, a symlink cwd escape, hang paths, unbounded backlog), `/proc` scan cost, simplification cuts, doc fixes.
- `2026-09-15-pi-delegate-build.md` — what the five-step build shipped (kill sweep, background + progress, batches, worktrees, `shell_bg`), the lead's live checks, estimates vs actual size, Codex sandbox and Pi API findings, and the decisions taken.
- `2026-09-15-pi-delegate-gaps-effort.md` — Astra review of closing five delegation gaps on Pi (background, fan-out, progress, worktrees, background shell): implementation sketches with Pi API citations, effort grades, the process-group kill hole and the read-isolation limit in `delegate.ts`.
- `2026-09-10-pi-delegate-launcher-report.md` — build report for the `delegate` tool: registered schema, child command lines, test output, live transcripts.
- `subagent-delegation-advisor-pattern.md` — the advisor/worker design document (uploaded 2026-08-15): one long-running advisor, fresh-context workers, model/effort tiers, plan-then-implement split. Its referenced companion `delegation-design-rationale.md` was never found on this machine.

### Context and memory
- `2026-07-30-context-rot-persistent-memory.html` — combined findings of the six-agent sweep on context rot and on-disk memory; the "handoff over compaction" consensus that produced the `handoff` and `grind` skills.
- `2026-07-30-last30days-context-rot-raw.md`, `2026-07-30-last30days-persistent-memory-raw.md` — the raw sweeps behind it.
- `2026-07-07-last30days-context-optimization-plugins-raw.md` — context-mode, leanctx, rtk and the rest; the sweep that preceded adopting context-mode.

### Architecture tooling
- `2026-07-30-last30days-codebase-architecture-analysis-raw.md` — the sweep behind the `geiger` skill.

### Posts
Converted from the site's TSX sources in `~/repos/career/portfolio-v2`; diagrams are referenced by name, not embedded.
- `2026-08-15-post-sharpening-the-harness.md` — what the papers on context and agent design say, what this setup measures, what survived contact.
- `2026-08-25-post-counting-agent-turns.md` — turns and wall time as the axis benchmarks leave out.

## Not copied, but related

- `~/documents/Last30Days/` — every raw sweep, including the job-search ones that are about using agents for a task rather than setting them up.
- `~/repos/zhulong-theme/REFUTATION.md` and `~/repos/flect/reports/flect-refutation-2026-07-29.html` — refutation records for project specs; the protocol is summarised in the digest, the records stay with their projects.
- `~/repos/career/job-hunt-swe/ai-job-search-research-report.md` — multi-agent orchestration applied to a search, not harness research.
- `~/tmp/claude/reports/dark-palette-research.html` — design research, no agent content.
