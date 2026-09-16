# Sub-Agent Delegation (Advisor Pattern)

Companion doc: `delegation-design-rationale.md` — read it before modifying
this file. It explains why each mechanism exists, what evidence supports it,
and which parts are load-bearing vs. tunable.

## Architecture

**Advisor:** one long-running `fable / max` agent. It plans, delegates,
arbitrates, synthesizes, and attributes rework. It writes its plan and
running decisions to `PLAN.md` on disk so state survives context resets.

**Workers:** fresh context per dispatch, discarded after completion.

| Task profile | Model / effort |
|---|---|
| Search, extract, summarize, classify; mechanical & read-only | haiku / low |
| Everyday coding & analysis, well-trodden, verifiable output | sonnet / medium–high |
| Cross-cutting changes, hard judgment calls, deep review | opus / xhigh |
| Writing code against an approved plan | codex |

Prefer raising effort over jumping model tiers — it is the cheaper lever.
Score tasks on: blast radius, reversibility, novelty, duration/autonomy.

**Code tasks — split plan from implementation:**
1. Plan/design with the tier chosen above (opus minimum for non-trivial plans).
2. Implement against the approved plan with codex.
3. Review diffs at the planning tier when blast radius is high.

## Information Tiers (advisor access rules)

- **Trace** — unprocessed execution output: tool calls, logs, diffs, stack
  dumps, loop transcripts. Never enters the advisor's context by default.
  Lives in `reports/<task-id>/` only.
- **Artifact** — completed work products: final files, plans, test results.
  The advisor may deliberately pull a *named* artifact when a report is
  insufficient to decide. Pull, don't push.
- **Report** — the worker's handoff. Always enters. The only push channel.

Nothing enters the advisor's context by default except reports; everything
else requires an explicit, named request.

## Delegation Contract

Every dispatch from the advisor must specify:
- Objective and expected output format
- Relevant context as file pointers, never pasted content
- Task boundaries (what is out of scope)
- A loop budget
- **Watch-for items:** specific values, files, or conditions the worker
  must report on verbatim. Advisor foresight — not worker judgment —
  defines significance.
- Stakes marking (normal / high-stakes / irreversible)

## Loops

Loops are encouraged — inside worker contexts. Workers iterate freely
(test-fix-retest, search-refine) within their loop budget. The noise stays
in the worker's context and dies with it. A worker returns to the advisor
only when: done, budget exhausted, or the task scope turns out to be wrong.

## Handoff Report

The only thing that enters the advisor's context by default. Max ~300 words,
written for a reader with zero visibility into the work:

- Objective (restated) and verdict: **done / blocked / scope-mismatch**
- What changed: artifact paths (files, branches), never contents
- Answers to every watch-for item, verbatim
- Key findings & decisions made, one-line rationale each
- **Anomalies:** observations that deviated from expectations, reported
  even without an explanation. Judging weirdness is the worker's job;
  judging importance is not.
- **Discarded:** one line listing categories of output deemed irrelevant,
  so exclusions are visible decisions.
- What was tried and failed (so retries don't repeat it)
- Open questions / risks for the advisor
- Loops used vs. budget

Full logs, diffs, and traces go to `reports/<task-id>/`. Reports index
into them with paths and line ranges ("full test output:
reports/t-14/pytest.log, lines 340–390 are the odd part") — reports are
lazy-loading indexes into the traces, not replacements for them.

**Stakes-scaled reporting:** for dispatches marked high-stakes, the handoff
is written by an opus-tier reader from the trace, separate from the worker
that did the work. Compression quality scales with the stakes of the
decision it feeds.

## Escalation

A worker that exhausts its budget does not get a bigger budget at the same
configuration. The advisor decides: raise effort, raise tier, split the
task, or revise the plan. Failed-attempt context from the report goes into
the next dispatch.

## Audits

Periodically — and after any surprise — the advisor pulls one full trace at
random from a completed task and diffs it against the report it received.
Findings update the watch-for lists and report norms. Audits calibrate the
compression layer; they are a standing practice, not a debugging tool.

## Routing Telemetry & Calibration

Every dispatch appends one line to `routing_log.jsonl`:
task class, model/effort, verdict, loops used, tokens, escalated (y/n),
rework (y/n).

- **Rework attribution is the advisor's job** at synthesis time: a task
  that passed but caused a downstream fix is retroactively marked
  `rework: true`. Workers cannot see this; only the advisor can.
- **Per task class:** expected cost at each tier =
  tier cost + p(fail at tier) × cost of the escalation that follows.
  Route to the cheapest tier by *expected* cost, not sticker cost.
- **Probe rule:** ~1 in 10 borderline dispatches routes one tier DOWN from
  the table's recommendation. A probe that succeeds within budget means
  the boundary is too conservative. Down-probes are safe because failure
  triggers normal escalation. Never probe on tasks marked irreversible.
- **Priors before data:** the hand-tuned table is the prior. Only move a
  boundary after ~15–20 logged observations for that task class.
- Threshold changes are edited in this file with the supporting numbers
  noted in a comment.

# Sub-Agent Delegation (Advisor Pattern)

Companion doc: `delegation-design-rationale.md` — read it before modifying
this file. It explains why each mechanism exists, what evidence supports it,
and which parts are load-bearing vs. tunable.

## Architecture

**Advisor:** one long-running `fable / max` agent. It plans, delegates,
arbitrates, synthesizes, and attributes rework. It writes its plan and
running decisions to `PLAN.md` on disk so state survives context resets.

**Workers:** fresh context per dispatch, discarded after completion.

| Task profile | Model / effort |
|---|---|
| Search, extract, summarize, classify; mechanical & read-only | haiku / low |
| Everyday coding & analysis, well-trodden, verifiable output | sonnet / medium–high |
| Cross-cutting changes, hard judgment calls, deep review | opus / xhigh |
| Writing code against an approved plan | codex |

Prefer raising effort over jumping model tiers — it is the cheaper lever.
Score tasks on: blast radius, reversibility, novelty, duration/autonomy.

**Code tasks — split plan from implementation:**
1. Plan/design with the tier chosen above (opus minimum for non-trivial plans).
2. Implement against the approved plan with codex.
3. Review diffs at the planning tier when blast radius is high.

## Information Tiers (advisor access rules)

- **Trace** — unprocessed execution output: tool calls, logs, diffs, stack
  dumps, loop transcripts. Never enters the advisor's context by default.
  Lives in `reports/<task-id>/` only.
- **Artifact** — completed work products: final files, plans, test results.
  The advisor may deliberately pull a *named* artifact when a report is
  insufficient to decide. Pull, don't push.
- **Report** — the worker's handoff. Always enters. The only push channel.

Nothing enters the advisor's context by default except reports; everything
else requires an explicit, named request.

## Delegation Contract

Every dispatch from the advisor must specify:
- Objective and expected output format
- Relevant context as file pointers, never pasted content
- Task boundaries (what is out of scope)
- A loop budget
- **Watch-for items:** specific values, files, or conditions the worker
  must report on verbatim. Advisor foresight — not worker judgment —
  defines significance.
- Stakes marking (normal / high-stakes / irreversible)

## Loops

Loops are encouraged — inside worker contexts. Workers iterate freely
(test-fix-retest, search-refine) within their loop budget. The noise stays
in the worker's context and dies with it. A worker returns to the advisor
only when: done, budget exhausted, or the task scope turns out to be wrong.

## Handoff Report

The only thing that enters the advisor's context by default. Max ~300 words,
written for a reader with zero visibility into the work:

- Objective (restated) and verdict: **done / blocked / scope-mismatch**
- What changed: artifact paths (files, branches), never contents
- Answers to every watch-for item, verbatim
- Key findings & decisions made, one-line rationale each
- **Anomalies:** observations that deviated from expectations, reported
  even without an explanation. Judging weirdness is the worker's job;
  judging importance is not.
- **Discarded:** one line listing categories of output deemed irrelevant,
  so exclusions are visible decisions.
- What was tried and failed (so retries don't repeat it)
- Open questions / risks for the advisor
- Loops used vs. budget

Full logs, diffs, and traces go to `reports/<task-id>/`. Reports index
into them with paths and line ranges ("full test output:
reports/t-14/pytest.log, lines 340–390 are the odd part") — reports are
lazy-loading indexes into the traces, not replacements for them.

**Stakes-scaled reporting:** for dispatches marked high-stakes, the handoff
is written by an opus-tier reader from the trace, separate from the worker
that did the work. Compression quality scales with the stakes of the
decision it feeds.

## Escalation

A worker that exhausts its budget does not get a bigger budget at the same
configuration. The advisor decides: raise effort, raise tier, split the
task, or revise the plan. Failed-attempt context from the report goes into
the next dispatch.

## Audits

Periodically — and after any surprise — the advisor pulls one full trace at
random from a completed task and diffs it against the report it received.
Findings update the watch-for lists and report norms. Audits calibrate the
compression layer; they are a standing practice, not a debugging tool.

## Routing Telemetry & Calibration

Every dispatch appends one line to `routing_log.jsonl`:
task class, model/effort, verdict, loops used, tokens, escalated (y/n),
rework (y/n).

- **Rework attribution is the advisor's job** at synthesis time: a task
  that passed but caused a downstream fix is retroactively marked
  `rework: true`. Workers cannot see this; only the advisor can.
- **Per task class:** expected cost at each tier =
  tier cost + p(fail at tier) × cost of the escalation that follows.
  Route to the cheapest tier by *expected* cost, not sticker cost.
- **Probe rule:** ~1 in 10 borderline dispatches routes one tier DOWN from
  the table's recommendation. A probe that succeeds within budget means
  the boundary is too conservative. Down-probes are safe because failure
  triggers normal escalation. Never probe on tasks marked irreversible.
- **Priors before data:** the hand-tuned table is the prior. Only move a
  boundary after ~15–20 logged observations for that task class.
- Threshold changes are edited in this file with the supporting numbers
  noted in a comment.
