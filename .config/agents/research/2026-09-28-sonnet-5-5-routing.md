# Sonnet 5.5 in the routing table — 2026-09-28

Sonnet 5.5 was released 2026-09-28. The question is whether it takes a row
from a Codex tier (Luna, Sol, Astra) or from Opus 5.5.

## Decision

Superseded 2026-09-29 by `2026-09-29-gpt-6-1-sol-routing.md`: GPT-6.1 Sol
medium beats Sonnet 5.5 high on all four metrics, so the route and the
`sonnet-high` agent definition were removed.

Sonnet 5.5 high takes the bounded coding or investigation half of the
"substantial separable task" row, from Claude Code only, through the
`sonnet-high` agent definition. Sol keeps that row in Codex and Pi, and keeps
demanding coding work and prose everywhere. Luna keeps the mechanical tier:
mechanical work gains nothing from the extra score, and Luna is cheaper and
spends the ChatGPT plan. Chosen by the user 2026-09-28.

## Reachability

Claude Code 2.1.284: `claude -p --model sonnet` answers as `claude-sonnet-5-5`,
so the `Agent` tool's `model: sonnet` already dispatches Sonnet 5.5. Effort is
fixed per agent definition (`effort:` frontmatter in `.claude/agents/*.md`),
not per call. Pi `delegate` has no Claude runner (pi, codex, agy only).

## Snapshot

Artificial Analysis Coding Agent Index v1.5
(artificialanalysis.ai/agents/coding-agents), read 2026-09-28 from the page's
`self.__next_f` payload. Index = equal-weight mean of DeepSWE v1.1,
Terminal-Bench 4.0 and SWE-Atlas-QnA, pass@1 over three attempts. Per-task
means.

| Harness — model (effort) | Index | DeepSWE | TB 4.0 | QnA | Total tok | Output | Steps | Cost | Time |
|---|---|---|---|---|---|---|---|---|---|
| Claude Code — Sonnet 5.5 (max) | 68.4 | 72.0 | 66.2 | 66.9 | 27.74M | 601K | 266 | $14.19 | 87.4 min |
| Claude Code — Opus 5.5 (max) | 66.0 | 68.4 | 63.1 | 66.4 | 15.55M | 333K | 155 | $13.04 | 64.5 min |
| Claude Code — Sonnet 5.5 (xhigh) | 62.9 | 68.4 | 58.1 | 62.1 | 7.09M | 126K | 78 | $3.33 | 27.0 min |
| Claude Code — Fable 5.1 (max, fallback) | 62.2 | 64.3 | 57.6 | 64.8 | 5.72M | 134K | 37 | $12.39 | 34.8 min |
| Codex — GPT-6 Astra (max) | 61.6 | 67.6 | 55.6 | 61.8 | 3.35M | 47K | 39 | $7.47 | 29.4 min |
| Claude Code — Opus 5 (max) | 59.7 | 62.5 | 54.6 | 62.1 | 11.37M | 137K | 152 | $10.79 | 41.9 min |
| Codex — GPT-6 Sol (max) | 56.7 | 69.0 | 43.4 | 57.5 | 9.84M | 62K | 87 | $2.99 | 22.3 min |
| Claude Code — Sonnet 5.5 (high) | 55.0 | 66.7 | 41.9 | 56.5 | 2.65M | 41K | 37 | $1.24 | 12.3 min |
| Claude Code — Sonnet 5.5 (medium) | 45.9 | 65.5 | 27.3 | 44.9 | 1.25M | 21K | 22 | $0.62 | 8.5 min |
| Claude Code — Sonnet 5.5 (low) | 42.1 | 62.0 | 25.3 | 39.0 | 0.98M | 16K | 19 | $0.48 | 6.3 min |
| Codex — GPT-6 Luna (max) | 41.1 | 63.7 | 15.2 | 44.4 | 10.22M | 98K | 89 | $0.18 | 21.4 min |

GPT-6 tiers appear only at max effort; there is no like-for-like effort
comparison.

Other sources, read 2026-09-28:
- **DeepSWE** (deepswe.datacurve.ai, updated 2026-09-22): no Sonnet 5.5 row.
  Sonnet 5 max scored 53.8% at $26.40 against Astra max 73.2% at $7.50.
- **RealSWE** (realswe.withspecific.com): no Sonnet 5.5 row. Only Astra
  (46.25%) and Fable 5.1 (45.00%) of the current tiers are listed.
- **BenchLM** (benchlm.ai, methodology bench-align-v5.7): Sonnet 5.5 is marked
  "estimated", and every row comes from Anthropic's launch post and system
  card. Coding 79.8 (#2) against Opus 5.5 83.1, Astra 74.0 and Sol 62.7.
  Agentic 66.2 (#10) against Opus 5.5 87.8, Astra 70.7 and Sol 60.0.
- **Prose** (EQ-Bench Creative Writing v3 and Longform, Arena creative
  writing): no Sonnet 5.5 row on any board.

## Readings

- **Sonnet 5.5 high against Sol max:** 1.7 points lower (Sol also leads each
  component), on 27% of the total tokens, 41% of the cost and 55% of the wall
  time.
- **Sonnet 5.5 medium and low against Luna max:** higher scores (+4.8 and
  +1.0), about a tenth of the tokens and 30–40% of the time, but 2.7–3.5× the
  cost ($0.30–0.44 more per task).
- **Sonnet 5.5 xhigh against Astra max:** +1.3 points on 2.1× the tokens, at
  45% of the cost and 92% of the time. Astra stays the most token-efficient
  row on the board.
- **Sonnet 5.5 max** tops the index (+2.4 over Opus 5.5), but uses the most
  tokens (1.8× Opus), time (1.35×) and money of any row.
- **Evidence is thin.** Only AA measures Sonnet 5.5 independently. BenchLM's
  numbers are the provider's own, and DeepSWE, RealSWE and every prose board
  have not scored it yet. Sonnet 5 did badly on DeepSWE, so the long-horizon
  placement needs DeepSWE's own Sonnet 5.5 run to confirm it.
- **Sonnet cannot replace Codex on cross-family rows.** It shares Claude's
  blind spots, so it cannot take "repeated attempts have failed" or
  cross-family review.
- **Quota pool.** A Sonnet subagent spends the Claude plan. Codex spends the
  ChatGPT plan.


## Re-check

When DeepSWE, RealSWE or EQ-Bench add Sonnet 5.5.
