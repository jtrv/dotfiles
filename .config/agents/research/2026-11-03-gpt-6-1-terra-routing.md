# GPT-6.1 Terra in the routing table — 2026-11-03

GPT-6.1 Terra was released 2026-10-26. `watches/new-models.sh` flagged it on
2026-11-03 from Codex's model cache ("GPT-6.1 Terra Codex model.").

## Decision

- GPT-6.1 Terra at effort `low` replaces GPT-6 Luna on the mechanical row
  (fixtures, extraction, renames). The tier ramp becomes Terra → Sol → Astra.
  Chosen by the user on 2026-11-03.
- Sol keeps every Sol row. Terra xhigh, Terra's best index score, sits 5.9
  points below Sol max and uses 75% more tokens.
- Pi `delegate` gained an optional `effort` field for the Codex runner
  (`-c model_reasoning_effort=<effort>`), so the row's `low` can be honoured
  from Pi. Its Codex model allowlist swaps `gpt-6-luna` for `gpt-6.1-terra`.
  Claude Code passes `--effort low` to `codex:codex-rescue`. Whether Codex's
  `spawn_agent` takes a per-call effort is unverified, so a Codex-steered child
  may run Terra at the default medium.
- The OpenRouter runway prose pick (`openai/gpt-6-luna`,
  `2026-10-23-openrouter-prose-route.md`) is a separate route and is unchanged.

## Availability

Codex 0.163.0: `codex exec -m gpt-6.1-terra -c model_reasoning_effort=low`
answered on the ChatGPT account.

## Snapshot

Artificial Analysis Coding Agent Index v5.0
(artificialanalysis.ai/agents/coding-agents), read 2026-11-03 from the page's
`self.__next_f` payload. Suites: FrontierCode v1.1 Main, SWE-Atlas-QnA,
Terminal-Bench v4. Figures are per-task means. v5.0 scores must not be compared
with the v1.5 figures in earlier reports.

| Harness — model (effort) | Index | FrontierCode | QnA | TB v4 | Total tok | Output | Steps | Cost | Time |
|---|---|---|---|---|---|---|---|---|---|
| Codex — GPT-6 Astra (max) | 54.7 | 49.3 | 59.1 | 55.6 | 3.23M | 41K | 39 | $7.04 | 24.8 min |
| Codex — GPT-6.1 Sol (max) | 54.1 | 49.4 | 59.9 | 53.0 | 3.94M | 55K | 41 | $1.50 | 23.7 min |
| Codex — GPT-6.1 Terra (xhigh) | 48.2 | 44.9 | 53.8 | 46.0 | 6.89M | 37K | 72 | $0.69 | 16.4 min |
| Codex — GPT-6.1 Terra (max) | 48.1 | 41.8 | 54.0 | 48.5 | 12.28M | 73K | 100 | $1.24 | 26.1 min |
| Codex — GPT-6.1 Terra (high) | 46.3 | 43.5 | 53.0 | 42.4 | 5.60M | 27K | 67 | $0.54 | 12.7 min |
| Codex — GPT-6.1 Terra (medium) | 42.0 | 43.8 | 47.0 | 35.4 | 4.08M | 19K | 58 | $0.39 | 10.2 min |
| Codex — GPT-6.1 Terra (non-reasoning) | 39.2 | 46.2 | 46.2 | 25.3 | 5.78M | 14K | 82 | $0.45 | 9.5 min |
| Codex — GPT-6.1 Terra (low) | 34.9 | 40.6 | 38.7 | 25.3 | 1.89M | 9K | 43 | $0.20 | 6.3 min |
| Codex — GPT-6 Luna (max) | 31.1 | 39.5 | 38.2 | 15.7 | 8.89M | 91K | 81 | $0.16 | 21.3 min |

Only these effort rows are published: Sol and Luna appear at max alone, so
neither tier's dispatched (default medium) effort is on the board.

Other sources, read 2026-11-03:
- **DeepSWE** (`leaderboard-live.json`): no GPT-6.1 Terra row, and no GPT-6
  Luna row either; only the GPT-5.6 generation.
- **RealSWE:** no Terra entry.
- **BenchLM:** "Estimated"; agentic rank #6 of 135 (76, 5/5 benchmarks
  verified); coding not measured.

## Readings

- **Terra low against Luna max:** +3.8 points, 21% of the tokens, 30% of the
  time, 125% of the cost. Better on three of four metrics; the extra cent per
  task is the trade.
- **Terra medium against Luna max:** +10.9 points, 46% of the tokens, 48% of
  the time, 2.4× the cost. More score than mechanical work needs.
- **Terra against Sol max:** every Terra effort scores lower; Terra xhigh costs
  less but uses more tokens. Sol keeps its rows.
- **Caveat:** the Luna comparison is against Luna max, not the default effort
  Luna was dispatched at. Luna at medium could be closer on tokens and time.

## Local probe

One mechanical task in a throwaway TypeScript repo, with planted traps:
rename `fetchUserRecord` → `loadUser` across five files, including a
namespace call and a log string, while keeping the prefix-sharing decoys
`fetchUserRecords` and `fetchUserRecordTimeoutMs`; and extract the `ERR` object
into a sorted `errors.json`, skipping a decoy `ERR_LOG` constant. Twelve scripted
checks, validated as 4/12 on the untouched fixture (the decoy-preservation
checks) and 12/12 on a reference solution. `codex exec --sandbox
workspace-write`, two runs per cell, all eight in parallel.

| Model (effort) | Run 1 | Run 2 |
|---|---|---|
| Terra low | 12/12 · 28 s · 12.9K tok | 12/12 · 31 s · 37.7K tok |
| Terra medium | 12/12 · 26 s · 30.0K tok | 12/12 · 28 s · 48.3K tok |
| Luna low | 12/12 · 30 s · 19.9K tok | 11/12 · 30 s · 19.7K tok |
| Luna medium | 12/12 · 28 s · 18.8K tok | 12/12 · 21 s · 7.6K tok |

Luna low's miss was real: it sorted `ERR_USER_409` before `ERR_USER_404`. The
probe does not veto Terra and does not rank the two: wall times are level,
Terra's token counts vary more, and Luna medium was the leanest run. The
placement rests on the AA reading above.

## Re-check

- When AA publishes a Luna or Terra row at the dispatched effort, or DeepSWE
  or RealSWE adds Terra.
- If Terra low misses on real mechanical tasks, raise it to medium before
  reverting to Luna.
