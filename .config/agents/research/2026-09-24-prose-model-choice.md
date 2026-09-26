# Which model writes simple prose — 2026-09-24

"Simple prose" here means documentation, READMEs, summaries, commit and PR
text: short, factual, voice-light writing. The question is which reachable
model does it well at the lowest cost, time and tokens.

## Decision

- Substantial prose that is worth delegating goes to Codex `gpt-6-sol` at
  Codex's configured default effort (medium). It sits with Astra and Fable
  5.1 on both EQ-Bench writing boards, with the lowest slop of any GPT-6
  model on longform, at a fraction of their cost and time.
- Short prose stays inline. Delegation overhead outweighs any quality or cost
  gain on a commit message or a paragraph.
- Luna no longer takes documentation. GPT-6 Luna has no prose score anywhere
  yet, and GPT-5.6 Luna sits mid-table (below). Re-check when EQ-Bench scores
  GPT-6 Luna.
- Avoid Gemini 3.8 Flash and Claude Haiku 4.5 for prose (below).
- Agent-instruction prose is unaffected: it stays with the strongest model.

## Evidence (all read 2026-09-24)

EQ-Bench Creative Writing v3 (eqbench.com/creative_writing.html; judged by a
Claude model; Slop is lower-better, Length in characters):

| Model | Elo | Rubric | Slop | Repetition | Length |
|---|---|---|---|---|---|
| gpt-6-astra | 2173 | 84.00 | 1.2 | 3.5 | 6191 |
| claude-fable-5-1 | 2162 | 84.75 | 1.1 | 3.6 | 5841 |
| claude-opus-5 | 2133 | 85.35 | 0.9 | 4.3 | 6003 |
| gpt-6-sol | 2125 | 82.55 | 1.2 | 3.6 | 6182 |
| claude-opus-5-5 | 2050 | 83.95 | 1.4 | 3.8 | 6041 |
| gpt-5.6-luna | 1829 | 82.90 | 1.6 | 4.0 | 7927 |
| claude-sonnet-5 | 1794 | 82.35 | 1.6 | 4.6 | 5753 |
| gemini-3.8-flash | 1748 | 82.70 | 3.1 | 3.1 | 7251 |

GPT-6 Luna and Claude Haiku 4.5 are not on this board.

EQ-Bench Longform (eqbench.com/creative_writing_longform.html):

| Model | Score | Slop | Repetition | Degradation |
|---|---|---|---|---|
| claude-opus-5 | 86.3 | 5.6 | 5.0 | 0.000 |
| claude-fable-5-1 | 85.3 | 7.6 | 5.4 | 0.000 |
| claude-opus-5-5 | 84.6 | 9.0 | 5.9 | 0.000 |
| gpt-6-astra | 82.8 | 9.1 | 6.3 | 0.050 |
| gpt-6-sol | 82.8 | 7.9 | 8.0 | 0.014 |
| claude-sonnet-5 | 78.3 | 13.5 | 5.6 | 0.014 |
| gemini-3.8-flash | 76.8 | 27.7 | 5.2 | 0.029 |
| gpt-5.6-luna | 75.5 | 14.1 | 10.1 | 0.106 |
| claude-haiku-4.5 | 65.0 | 14.7 | 5.4 | 0.462 |

Arena creative writing (arena.ai/leaderboard/text/creative-writing, human
votes): Fable 5.1 max 1486, Gemini 3.8 Flash high 1496 (preliminary, 1,072
votes), Astra max 1461, Sonnet 5 high 1437, GPT-5.6 Luna xhigh 1411, Haiku
4.5 1389. GPT-6 Sol and Luna are not listed yet.

Cost and time, Artificial Analysis Intelligence Index
(artificialanalysis.ai/leaderboards/models; cost to run the index, total
response time for a typical request):

| Model (effort) | Index | Cost | Tokens/s | Response |
|---|---|---|---|---|
| GPT-6 Sol (medium) | 40 | $0.25 | 114 | 6.3 s |
| GPT-6 Sol (high) | 43 | $0.37 | 97 | 14.8 s |
| GPT-6 Luna (medium) | 29 | $0.02 | 143 | 8.8 s |
| Claude Sonnet 5 (medium) | 28 | $1.00 | 67 | 9.8 s |
| Claude Haiku 4.5 | 17 | $0.21 | 104 | 26.9 s |
| Gemini 3.8 Flash (high) | 41 | $1.24 | 292 | 16.4 s |
| Claude Fable 5.1 (medium) | 49 | $2.98 | 57 | 20.8 s |
| Claude Opus 5.5 (medium) | 51 | $1.34 | 79 | 27.7 s |
| GPT-6 Astra (medium) | 50 | $1.54 | 48 | 16.7 s |

Launch coverage (vellum.ai, 2026-09) reports GPT-6 Sol and Luna were tuned
to cut conversational bloat, and a builder's editorial test found Sol's
paragraphs close to Astra's, thesis first. That is anecdote, not a benchmark.

## Readings

- Sol is the cheapest model near the prose frontier: fourth on Creative
  Writing v3, tied with Astra on longform with less slop, at a sixth of
  Astra's cost and under half its response time at medium effort.
- Opus 5.5, the strongest coding tier, is not the strongest prose tier: it
  trails Fable 5.1 and Opus 5 on both EQ-Bench boards and slops more.
- Gemini 3.8 Flash wins human votes on Arena but has by far the worst slop
  on both EQ-Bench boards (3.1 and 27.7): readers liking flourish is the
  opposite of what documentation needs.
- Haiku 4.5 is cheap but last on longform, with heavy degradation.
- Sonnet 5 costs four times Sol for weaker scores on every board.

## Caveats

- These are creative-writing benchmarks. Documentation rewards accuracy and
  brevity more than style; no current benchmark measures technical prose
  directly (BenchLM's 2026 writing guide says the same and ranks on provider
  documentation only).
- EQ-Bench is judged by a Claude model, which may favour Claude prose.
- GPT-6 Luna has no prose data yet; its placement is by omission.
