# Gemini 4 Neon placement — 2026-11-21

## Decision

Gemini 4 Neon replaces Gemini 4 Argon on the bounded one-shot row (agy):
`gemini-4-neon-medium` first, `-high` when medium misses, never `-low`. The
row's limits stay as they were. Gemini 4 Hydrogen takes no row: Neon beats it
on score, time and tokens, and Hydrogen's only edge is cost. Neon gets no
coding tier: GPT-6.1 Sol is far ahead on cost, time and tokens for a score
gap the coding rows do not need (below).

`watches/new-models.sh` flagged both on 2026-11-21. The same day it was fixed
to strip agy's `-xhigh` suffix, which had made each effort show up as a
separate model.

## Leaderboard snapshot (fetched 2026-11-21)

**Artificial Analysis coding agents** (artificialanalysis.ai/agents/coding-agents).
The index now averages **FrontierCode 2.0**, Terminal-Bench v4 and SWE-Atlas-QnA
(equal weights). FrontierCode moved from v1.1 to 2.0 since the Argon report, so
its index numbers (Argon 53.2 then) do not compare with these. Default effort
rows only: Neon and Hydrogen are scored at xhigh, Argon at high.

| Agent – model (effort) | Index | FrontierCode 2.0 | TB v4 | QnA | Cost/task | Wall | Total tok | Output tok |
|---|---|---|---|---|---|---|---|---|
| **Antigravity CLI – Gemini 4 Neon (xhigh)** | **58.6** | 43.0 | 67.7 | 65.2 | $6.86 | 30m | 13.8M | 126k |
| Claude Code – Opus 5.5 (max) | 58.2 | 44.0 | 65.9 | 64.6 | $12.61 | 65m | 15.9M | 310k |
| Antigravity CLI – Gemini 4 Carbon (high) | 55.5 | 38.0 | 63.7 | 64.6 | $9.75 | 34m | 15.4M | 120k |
| Antigravity CLI – Gemini 4 Hydrogen (xhigh) | 52.3 | 36.6 | 60.2 | 60.1 | $4.45 | 32m | 18.5M | 199k |
| Codex – GPT-6.1 Sol (max) | 52.2 | 42.5 | 59.9 | 54.0 | $1.51 | 22m | 4.3M | 57k |
| Antigravity CLI – Gemini 4 Argon (high) | 45.5 | 24.8 | 55.1 | 56.6 | $13.67 | 38m | 16.4M | 127k |

Neon against Argon: +13.1 points, half the cost, 0.8× the wall time, 0.84×
the tokens. That is better on all four metrics, so it takes the row under the
dominance rule. Hydrogen against Neon: 6.3 points lower, more time and 1.3×
the tokens, for 0.65× the cost.

Neon against Sol for coding: +6.4 points, mostly from TB v4 and QnA. On
FrontierCode, the coding suite, the two are level (43.0 vs 42.5). Neon costs
4.5× as much, takes 1.4× the wall time and uses 3.2× the tokens. No coding row
changes.

Gemini 4 Carbon is on AA but not in `agy models` (agy 2026-11-21), so it
cannot be dispatched and was not placed.

**RealSWE** (realswe.withspecific.com, fetched 2026-11-21): no Neon or Hydrogen
entry. Gemini 4 Carbon 55.2% (±2.7), Argon 39.2%.

**DeepSWE** (`artifacts/v1.1/leaderboard-live.json`): no Gemini 4 entry of any
kind. The newest Gemini rows are 3.8 Flash. The long-horizon axis is unconfirmed.

**BenchLM** (benchlm.ai/models/gemini-4-neon, -argon): Neon ranks #2 of 215
overall and #1 in Coding. Argon ranks #10 overall and #13 in Coding. Headline
only; agentic weights not read.

## Local probe (agy-run, 2026-11-21)

This rebuilt the Argon report's probe, since its fixture was not kept: a
Postgres column rename plan with three planted flaws and one true decoy. The
flaws are a rename before the rolling update, which breaks old pods; a
`rollout undo` that cannot run against the migrated schema; and a backup taken
after the migration. The decoy is that the unique index follows the renamed
column. Each run was told to read one file and answer, with all four runs in
parallel. n=1.

| Model | Wall | Tokens | Verdict | Planted flaws | Decoy | Extra real findings |
|---|---|---|---|---|---|---|
| gemini-4-argon-medium | 36s | 14.9k | REJECT | 3/3 | correct | lock_timeout |
| gemini-4-argon-high | 48s | 17.6k | REJECT | 3/3 | correct | lock_timeout, pg_dump snapshot blocks VACUUM, index keeps old name |
| gemini-4-neon-medium | 40s | 17.7k | REJECT | 3/3 | correct | lock_timeout, pg_dump snapshot/VACUUM, index name + `ON CONFLICT ON CONSTRAINT` |
| gemini-4-neon-high | 58s | 19.7k | REJECT | 3/3 | correct | same as medium, plus other consumers of the column |

All four runs found every planted flaw and judged the decoy correctly. At
medium, Neon matched what Argon found only at high. Locally Neon cost about
10% more time and 19% more tokens than Argon at medium. That gap is inside
n=1 noise and the opposite of the leaderboard, so it is no veto.

## Not checked

Neon at `-medium` on any leaderboard (only xhigh is scored), Neon on RealSWE
and DeepSWE (no entries), and BenchLM's agentic weights.
