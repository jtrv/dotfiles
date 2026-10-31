# GPT-6.1 Sol in the routing table — 2026-09-29

GPT-6.1 Sol was released 2026-09-29 at GPT-6 Sol's API price ($2 in / $10 out
per MTok, cached input halved to $0.10).

## Decision

- GPT-6.1 Sol replaces GPT-6 Sol on every Sol row: bounded tasks, demanding
  coding work and prose. It also replaces GPT-6 Sol as the default for Pi and
  for the Codex and Pi runners of `delegate`. Use Codex's default medium effort:
  medium beat high and max on the index for less.
- It supersedes the Sonnet 5.5 high route
  (`2026-09-28-sonnet-5-5-routing.md`), which was one day old. GPT-6.1 Sol
  medium beats Sonnet 5.5 high on all four metrics. The `sonnet-high` agent
  definition is removed.
- Astra keeps "repeated attempts have failed" and hard debugging when the
  session is not on Opus. GPT-6.1 Sol xhigh beats Astra max on all four
  metrics, but only on AA and only on release day. Re-check when DeepSWE or
  RealSWE scores GPT-6.1 Sol.
- Luna keeps the mechanical tier. It is still the cheapest per task, and
  mechanical work does not need the extra score.
- Prose moves to 6.1 as the Sol successor. No writing board has scored it
  yet (EQ-Bench v3, Longform, Arena).
- Chosen by the user on 2026-09-29.

## Availability

Codex 0.156.1 refused `gpt-6.1-sol` with HTTP 400 ("not supported when using
Codex with a ChatGPT account"). Codex 0.159.1 (released 2026-09-29) added it to
the bundled catalog (openai/codex#49323 and #49342). bun's 7-day
`minimumReleaseAge` guard blocked the upgrade, so the user approved a one-off
`bun add -g @openai/codex@0.159.1 --minimum-release-age 0`. Checked afterwards:
- `codex exec -m gpt-6.1-sol` answered.
- `pi update --models` added `openai-codex/gpt-6.1-sol`, and `pi -p` answered
  on it.
- A Pi `delegate runner=codex` call with no model given reported
  `gpt-6.1-sol`.

## Snapshot

Artificial Analysis Coding Agent Index v1.5
(artificialanalysis.ai/agents/coding-agents), read 2026-09-29 from the page's
`self.__next_f` payload. The index is the equal-weight mean of DeepSWE v1.1,
Terminal-Bench 4.0 and SWE-Atlas-QnA, pass@1 over three attempts. Figures are
per-task means. The page's host slug for GPT-6.1 Sol is `openai_quasar-alpha`.

| Harness — model (effort) | Index | DeepSWE | TB 4.0 | QnA | Total tok | Output | Steps | Cost | Time |
|---|---|---|---|---|---|---|---|---|---|
| Claude Code — Sonnet 5.5 (max) | 68.4 | 72.0 | 66.2 | 66.9 | 27.74M | 601K | 266 | $14.19 | 87.4 min |
| Claude Code — Opus 5.5 (max) | 66.0 | 68.4 | 63.1 | 66.4 | 15.55M | 333K | 155 | $13.04 | 64.5 min |
| Codex — GPT-6.1 Sol (xhigh) | 62.9 | 73.2 | 54.6 | 61.0 | 3.21M | 35K | 40 | $1.04 | 15.5 min |
| Claude Code — Sonnet 5.5 (xhigh) | 62.9 | 68.4 | 58.1 | 62.1 | 7.09M | 126K | 78 | $3.33 | 27.0 min |
| Codex — GPT-6 Astra (max) | 61.6 | 67.6 | 55.6 | 61.8 | 3.35M | 47K | 39 | $7.47 | 29.4 min |
| Codex — GPT-6.1 Sol (medium) | 61.4 | 72.0 | 51.5 | 60.8 | 2.30M | 22K | 38 | $0.71 | 10.9 min |
| Codex — GPT-6.1 Sol (high) | 60.2 | 70.5 | 50.0 | 60.0 | 2.82M | 29K | 39 | $0.89 | 13.3 min |
| Codex — GPT-6.1 Sol (max) | 60.2 | 69.6 | 53.0 | 57.8 | 4.00M | 62K | 41 | $1.55 | 24.4 min |
| Codex — GPT-6.1 Sol (low) | 57.2 | 67.6 | 49.0 | 55.1 | 1.71M | 15K | 36 | $0.50 | 8.6 min |
| Codex — GPT-6 Sol (max) | 56.7 | 69.0 | 43.4 | 57.5 | 9.84M | 62K | 87 | $2.99 | 22.3 min |
| Claude Code — Sonnet 5.5 (high) | 55.0 | 66.7 | 41.9 | 56.5 | 2.65M | 41K | 37 | $1.24 | 12.3 min |
| Codex — GPT-6 Luna (max) | 41.1 | 63.7 | 15.2 | 44.4 | 10.22M | 98K | 89 | $0.18 | 21.4 min |

Other sources, read 2026-09-29:
- **DeepSWE, RealSWE, EQ-Bench Creative Writing v3 and Longform, Arena
  creative writing:** no GPT-6.1 Sol row on any of them.
- **BenchLM:** GPT-6.1 Sol is "estimated", 66.86 overall (#23), coding 67.0
  (#8, one benchmark). All 11 of its rows are OpenAI-reported. That includes
  DeepSWE 71.9%, which DeepSWE's own board has not confirmed.
- **OpenAI's launch post** says it "matches GPT-6 Astra at roughly one-fifth
  of the cost" on DeepSWE v1.1. This is a provider claim.

## Readings

- **GPT-6.1 Sol medium against GPT-6 Sol max:** +4.7 points, 23% of the
  tokens, 24% of the cost, 49% of the time. A straight upgrade.
- **GPT-6.1 Sol medium against Sonnet 5.5 high:** +6.4 points, and fewer
  tokens, lower cost and less time.
- **GPT-6.1 Sol xhigh against Astra max:** +1.3 points, 96% of the tokens,
  14% of the cost, 53% of the time. This is the placement to re-check.
- **Effort curve:** medium is the knee. High and max score lower than medium
  and cost more.

## Re-check

- When DeepSWE or RealSWE adds GPT-6.1 Sol: it may take Astra's rows.
- When EQ-Bench scores GPT-6.1 Sol: it confirms or reverses the prose
  placement.
