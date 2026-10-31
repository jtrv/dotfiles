# Routing tiers: Opus 5.5 and GPT-6 — 2026-09-23

## Decision

- Claude Opus 5.5 is the strongest tier. The "ambiguous, hard debugging,
  substantial independent review" row stays in-session on Opus 5.5 and goes to
  Codex `gpt-6-astra` from anything else. Agent-instruction work names Opus 5.5.
- "Repeated attempts have failed" stays on `gpt-6-astra`: that row buys a
  different model family's explanation, which staying on Opus cannot give.
- GPT-6 Sol and GPT-6 Luna replace `gpt-5.6-sol` and `gpt-5.6-luna` in the
  table and in Pi `delegate`'s Codex allowlist.
- Terra is dropped: the ramp is Luna → Sol → Astra. There is no GPT-6 Terra
  and AA has no Terra row, while GPT-6 Sol costs less than GPT-5.6 Sol did,
  so an unscored tier between Luna and Sol no longer earns a slot. Pi's
  default model and `delegate`'s Pi and Codex defaults move to GPT-6 Sol
  (Pi's catalog lists it after `pi update --models`).

## Snapshot

Artificial Analysis Coding Agent Index v1.5
(artificialanalysis.ai/agents/coding-agents), read 2026-09-23 from the page's
embedded data. The index is the mean of DeepSWE v1.1 (113 tasks),
Terminal-Bench 4.0 (66) and SWE-Atlas-QnA (124), pass@1 averaged over three
attempts. Cost is mean API cost per task; time is mean agent wall time per task
(excludes environment startup and verification).

| Harness — model (effort) | Index | Total tokens | Output | Steps | Cost | Time |
|---|---|---|---|---|---|---|
| Claude Code — Opus 5.5 (max) | 66.0 | 15.55M | 333K | 155 | $13.04 | 64.5 min |
| Claude Code — Fable 5.1 (max, with fallback) | 62.2 | 5.72M | 134K | 37 | $12.39 | 34.8 min |
| Codex — GPT-6 Astra (max) | 61.6 | 3.35M | 47K | 39 | $7.47 | 29.4 min |
| Claude Code — Opus 5 (max) | 59.7 | 11.37M | 137K | 152 | $10.79 | 41.9 min |
| Codex — GPT-6 Sol (max) | 56.7 | 9.84M | 62K | 87 | $2.99 | 22.3 min |
| Codex — GPT-5.6 Sol (max) | 54.6 | 10.17M | 49K | 116 | $6.35 | 20.6 min |
| Codex — GPT-5.6 Luna (max) | 43.2 | 14.85M | 71K | 122 | $0.44 | 23.5 min |
| Codex — GPT-6 Luna (max) | 41.1 | 10.22M | 98K | 89 | $0.18 | 21.4 min |

All figures are means per task. Cache hit rates are 92–97% for every row.

Opus 5.5 components: DeepSWE 68.4, SWE-Atlas-QnA 66.4, Terminal-Bench 63.1.

Readings, with tokens as a ranking axis (`contexts/harnesses.md`):
- Opus 5.5 leads Astra by 4.4 points on 4.6× the total tokens, 2.2× the wall
  time and 1.7× the cost. It is the strongest tier, and the most expensive one
  to run. Astra is the most token-efficient row on the board.
- GPT-6 Sol beats GPT-5.6 Sol by 2.1 points with slightly fewer total tokens,
  fewer steps and under half the cost: a straight upgrade.
- GPT-6 Luna scores 2.1 points below GPT-5.6 Luna on 31% fewer total tokens
  and 40% of the cost. For the mechanical tier that trade is worth taking.

Not checked: DeepSWE and RealSWE directly, and BenchLM, which
`contexts/harnesses.md` names as the primary references. This placement rests
on Artificial Analysis alone, whose index includes DeepSWE.

## Availability

Codex 0.154.0 refused both new models with HTTP 400: "The '<model>' model is
not supported when using Codex with a ChatGPT account." The cause was the
client, not the plan: Codex 0.156.1 (openai/codex#47405) adds them to the
model catalog. After the upgrade, `codex exec -m gpt-6-sol` and
`-m gpt-6-luna` both answered on the same ChatGPT account.
