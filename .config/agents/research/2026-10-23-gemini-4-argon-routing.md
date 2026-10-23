# Gemini 4 Argon placement — 2026-10-23

## Decision

Gemini 4 Argon replaces Gemini 3.8 Flash on the bounded one-shot row (agy):
`gemini-4-argon-medium` first, `-high` when medium misses, never `-low`. The
row's limits stay: bounded briefs, nothing multi-step, never the sole plan
refuter (the cross-family rule, not a Flash-specific one). Argon gets no
coding tier: GPT-6.1 Sol matches or beats it on every one of the four
metrics, on both sources that score both.

Argon was released 2026-09-30 and sat unnoticed in `agy models` until a
skill review on 2026-10-23. `watches/new-models.sh` now catches the next one.

## Leaderboard snapshot (fetched 2026-10-23)

**Artificial Analysis coding agents** (artificialanalysis.ai/agents/coding-agents).
The index now averages FrontierCode v1.1 Main, Terminal-Bench v4 and
SWE-Atlas-QnA (eval version 1.2.10), not DeepSWE. A plain `fetch` of the
page carries the full payload in `self.__next_f.push` chunks — no browser
needed. Default effort rows only; the page lists no medium row for Argon.

| Agent – model (effort) | Index | FrontierCode | TB v4 | QnA | Cost/task | Wall | Total tok | Output tok |
|---|---|---|---|---|---|---|---|---|
| Claude Code – Opus 5.5 (max) | 61.7 | 56.0 | 63.1 | 65.9 | $11.42 | 61m | 14.5M | 279k |
| Claude Code – Sonnet 5.5 (max) | 59.3 | 47.6 | 66.2 | 64.2 | $13.30 | 80m | 24.1M | 495k |
| Claude Code – Fable 5.1 (max) | 57.6 | 48.9 | 57.6 | 66.4 | $11.53 | 35m | 6.0M | 126k |
| Codex – GPT-6 Astra (max) | 54.7 | 49.3 | 55.6 | 59.1 | $7.04 | 25m | 3.2M | 41k |
| Codex – GPT-6.1 Sol (max) | 54.1 | 49.4 | 53.0 | 59.9 | $1.50 | 24m | 3.9M | 55k |
| **Antigravity CLI – Gemini 4 Argon (high)** | **53.2** | 48.6 | 56.1 | 55.1 | $5.86 | 35m | 13.9M | 109k |
| Antigravity SDK – Gemini 3.8 Flash (high) | 33.3 | 40.8 | 14.6 | 44.4 | $2.51 | 13m | 14.3M | 113k |
| Codex – GPT-6 Luna (max) | 31.1 | 39.5 | 15.7 | 38.2 | $0.16 | 21m | 8.9M | 91k |

Argon against Sol: 0.9 points lower, 3.9× the cost, 1.5× the wall time,
3.6× the total tokens. Against Flash: +19.9 points for 2.3× the cost and
2.7× the wall time, at the same token count. Flash is scored under the SDK
harness and Argon under the CLI, so the gap mixes model and harness.

**RealSWE** (realswe.withspecific.com, no page date): Opus 5.5 56.8%,
GPT-6 Astra 56.0%, Sonnet 5.5 51.2%, GPT-6.1 Sol 47.2%, Fable 5.1 45.6%,
**Gemini 4 Argon 39.2%** (±3.3, $4.66/task, rank 7 of 17), GPT-6 Luna 10.4%.
Gemini 3.8 Flash is no longer listed. Sol's per-task cost did not parse
from the page and is not recorded here.

**DeepSWE**: no Argon entry. The live artifact
(`artifacts/v1.1/leaderboard-live.json`) was generated 2026-09-22, before
Argon's release; no `v1.2` path exists. Unconfirmed on the long-horizon axis.

**BenchLM** (benchlm.ai/models/gemini-4-argon): overall rank 5, BenchAlign
82.81 ("supported"); Terminal-Bench 4.0 57.4% (best: Sonnet 5.5 70.6%); SWE
77.9% (best: Muse Wonder Full 79.0%). Headline only; agentic weights not
read.

## Local probe (agy 1.4.6, 2026-10-23)

One bounded plan review via `agy-run`, the row's own job: a Postgres column
rename plan with three planted flaws (rename before a rolling update breaks
old pods; `rollout undo` cannot survive the migrated schema; backup taken
after the migration) and one true decoy (the unique index follows the
column). n=1, so it can veto a model but not rank close ones.

| Model | Wall | Tokens | Verdict | Planted flaws | Decoy | Extra real findings |
|---|---|---|---|---|---|---|
| gemini-3.8-flash-medium | 21s | 31.3k | REJECT | 3/3 | correct | lock_timeout |
| gemini-3.8-flash-high | 34s | 33.5k | REJECT | 3/3 | correct | lock_timeout |
| gemini-4-argon-medium | 21s | 17.6k | REJECT | 3/3 | correct | lock_timeout, dependent views/triggers |
| gemini-4-argon-high | 50s | 8.5k | REJECT | 3/3 | correct | lock_timeout, dependent objects, `SELECT *` scans |

A first run hit a broken hook (below) and no model could read the file.
Flash still returned a confident `REJECT` with no evidence; Argon reported
the denial and asked for the content. That is the failure the one-shot row
cares about most: a verdict with nothing under it.

Locally Argon medium is no slower than Flash medium and spends fewer tokens,
so the leaderboard's cost gap does not show up at one-shot scale.

## Found on the way

- **agy 1.4.6 renamed its tools.** `view_file` is now `read_file`, and
  `find_by_name`, `grep_search` and `list_dir` are gone — listing and search
  go through `run_command`. `hooks/agy-pretool.sh` allowlisted only the old
  names, so every read-only agy delegation was denied its one read tool.
  Fixed by adding `read_file`. Read-only children can no longer list or grep;
  briefs must name files by absolute path (they already should).
- **The AA page parses without a browser.** `contexts/harnesses.md` said a
  plain fetch returns no numbers; the payload is in the HTML.

## Not checked

Argon at `-medium` on any leaderboard (only `high` is scored); Argon on
DeepSWE; `gpt-reserve` and `gpt-oss-120b`, which the new watch acked as
baseline without a placement review.
