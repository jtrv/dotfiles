# Gemini 3.8 Flash as a one-shot route — 2026-09-16

## Decision

Add one routing row: bounded one-shot work (a second opinion on a diff or
file, a single question, an extra voice on a plan) goes to Gemini 3.8 Flash
through the `agy` skill, `--effort medium` first, `high` when medium misses,
never `low` (the user's floor: low is cheapest but the model's weakest setting,
and one-shot reviews are where a missed finding costs the most). Nothing multi-step or
long-horizon goes there, and it is never the only plan refuter. Codex tier
placements are unchanged; this is an addition beside them, not a re-ranking.

Why this shape and not a tier: on a uniform harness the model ties the top
tier on pass rate at a third of the cost, but it gets there with two to five
times the output tokens and steps, and on native harnesses (which is how we
run it) it drops to the middle. The verbosity is a wall-clock and quota cost
inside agy, not a parent-context cost — `agy-run` returns only the final
response — so the price is paid where a one-shot can afford it and a long
task cannot.

## Leaderboard snapshot (fetched 2026-09-16)

DeepSWE scores several efforts per model; the other sources score one
(`high`). Fable 5.1 and Gemini 3.1 Pro are missing from several tables; "no
entry" below means exactly that.

**DeepSWE** (deepswe.datacurve.ai, generated 2026-09-03, 113 tasks, every
model on mini-swe-agent, 4 runs per task). The rendered page shows one row
per model; the per-effort rows come from its data artifact,
`https://deepswe.datacurve.ai/artifacts/v1.1/leaderboard-live.json`
(mean cost, mean output tokens, mean steps, mean wall time):

| Model | Effort | Pass@1 | Cost/task | Output tok | Steps | Wall |
|---|---|---|---|---|---|---|
| gemini-3-8-flash | high | 74%±1 | $2.36 | 143k | 166 | 11m |
| gemini-3-8-flash | medium | 71%±2 | $1.97 | 125k | 147 | 14m |
| gemini-3-8-flash | low | no entry | | | | |
| gemini-3-7-flash | high / medium / low | 65% / 65% / 54% | $2.18 / $2.03 / $1.83 | 107k / 94k / 73k | 125 / 117 / 130 | 21m |
| gpt-6-astra | xhigh / high / medium / low | 74% / 73% / 73% / 67% | $6.52 / $5.72 / $4.38 / $2.19 | 30k / 27k / 20k / 11k | 29 / 27 / 26 / 20 | 19m / 17m / 15m / 10m |
| gpt-5-6-sol | max / high / medium / low | 73% / 69% / 61% / 45% | $8.39 / $3.47 / $1.86 / $1.07 | 60k / 28k / 18k / 11k | 61 / 37 / 31 / 23 | 19m / 10m / 7m / 4m |
| gpt-5-6-terra | max / high / medium | 70% / 54% / 35% | $4.95 / $1.13 / $0.58 | 72k / 22k / 12k | 76 / 34 / 25 | 17m / 6m / 4m |
| gpt-5-6-luna | max / xhigh / high | 67% / 57% / 44% | $3.03 / $1.54 / $0.78 | 73k / 45k / 26k | 102 / 71 / 49 | 19m / 12m / 8m |
| claude-opus-5 | max / high / medium / low | 74% / 73% / 69% / 58% | $11.84 / $6.08 / $3.29 / $1.66 | 118k / 64k / 37k / 20k | 99 / 73 / 52 / 36 | 32m / 19m / 13m / 8m |
| claude-fable-5 | xhigh / high / medium / low | 70% / 69% / 65% / 60% | $13.41 / $9.18 / $6.09 / $3.76 | 80k / 57k / 40k / 25k | 68 / 59 / 48 / 38 | 24m / 18m / 14m / 11m |
| claude-sonnet-5 | max / high / medium | 54% / 48% / 40% | $26.40 / $7.43 / $4.08 | 214k / 87k / 57k | 268 / 147 / 108 | 80m / 29m / 19m |

Gemini 3.1 Pro (preview) 12%, Fable 5.1: no entry. Flash's effort curve is
flat: medium gives up 3 points for 17% of the cost, and both efforts use
more output tokens and steps than any Astra or Sol row. Only Flash and Astra
stay above 70% below their top effort.

**RealSWE** (realswe.withspecific.com, no page date, native harnesses, high
reasoning, pass@1 over 8 runs): Fable 5.1 / Claude Code 38.8% ($6.96);
GPT-6 Astra / Codex CLI 33.8% ($4.67); Gemini 3.8 Flash / Gemini CLI 31.2%
($2.50, cheapest of 8, rank 4); GPT-5.6 Sol / Codex CLI 16.2% ($2.65).
Per-task output tokens on the ten sample tasks: Flash 67k–134k, Astra
13k–33k, Fable 5.1 26k–95k.

**Artificial Analysis coding agents index** (artificialanalysis.ai/agents/
coding-agents, parsed from page JSON-LD): Claude Code Fable 5.1 (max) 0.622,
2090 s, $12.39; Codex GPT-6 Astra (max) 0.616, 1762 s, $7.47; Claude Code
Opus 5 (max) 0.597; Antigravity SDK Gemini 3.8 Flash (high) 0.419, 703 s,
$2.47. Luna, Terra, Sol, Sonnet 5, Gemini 3.1 Pro: no entry.

**AA-Omniscience** (artificialanalysis.ai/evaluations/omniscience, top-20
charts): Gemini 3.8 Flash (high) index 29.6, accuracy 54.6%, hallucination
rate 55.2%. Neighbours: GPT-6 Astra (high) 43.7 / 61.1% / 44.8%; Fable 5.1
(high) 40.8 / 64.9% / 68.8%; Opus 5 (max) 37.1 / 60.9% / 60.8%; Sol (max)
22.0 / 59.4% / not shown. Reasoning tokens to run the eval: Flash 20.8M,
Astra 11.4M, Opus 5 5.4M, Fable 5.1 (high) 2.1M. The site publishes no
non-response chart; any abstention figure is derived, not measured.

**BenchLM** (benchlm.ai model pages, no page date; agentic weight 22%, coding
20%): Fable 5.1 agentic 80.2 (#1) coding 83.9 (#1); Opus 5 78.1 / 75.7; Astra
70.2 / 74.5; Sol 69.6 / 74.4; Gemini 3.8 Flash 66.4 (#10) / 66.5 (#10); Terra
60.3 / 67.0; Sonnet 5 65.9 / 64.0; Luna 56.6 / 66.8; Gemini 3.1 Pro 38.7 /
46.2 (mixed sources).

Reading across: pass rate ties the top on the uniform harness, sits fourth to
tenth on native harnesses and aggregates; cost per task is the lowest of any
frontier row; verbosity is the highest except Sonnet 5; hallucination rate is
mid-pack (better than Opus 5 and Fable-high, worse than every Astra variant)
with the lowest accuracy of the frontier set.

## Sentiment (30-day sweep, raw in `2026-09-16-last30days-gemini-3-8-flash-raw.md`)

Sources: Hacker News (19 stories, ~200 comments), 18 Reddit threads (titles
and OP text only, comment bodies were walled), Google AI developer forum,
one antigravity-cli issue, YouTube, web articles. X, TikTok and Instagram
were not searched (the skill's consent wizard had not been run).

- Verbose and overeager (5 independent sources): a forum thread titled
  "3.8 Flash: Overeagerness and verbosity, tired of it?"; an HN report that
  "Hi" produced a four-panel app; "opus 5 medium outputs 4x fewer tokens to
  achieve the same result".
- Loops and repeated reads (4): "go in circles reading the same file 20
  times"; a forum thread where loops burned 10% of a weekly quota, answered
  by a Google staffer with the fix we adopt below: explicit boundaries in
  the prompt, "inspect X once; if you cannot identify the issue, stop and
  ask".
- Confident answers without tool calls (3): antigravity-cli issue #1001
  (satirical in tone, three wrong answers in 45 minutes, the model skipping
  tool calls on topics it "knows").
- As reviewer (3): finds "subtle and insidious defects" in Opus output while
  tests are green; one practitioner running a Codex-writes, Claude-and-Gemini-
  review loop says Flash-high now catches much more in code review than
  earlier Flash versions, but "its review on design plans is still quite
  agreeable" and approves plans Claude would pick apart.
- Consensus phrasing: "love oneshotting or sanity checks"; "best back-and-
  forth model for iterating, would not use for long horizon"; "would not
  trust it for long agentic tasks, that really is the realm of sol/fable".

## Local probes (this machine, agy 1.1.24, 2026-09-16)

Task: review the 90-line `agy-run` script for correctness bugs, verdict
first, under 200 words, read-only gate active.

| Prompt | Model | Outcome | Wall | Tokens |
|---|---|---|---|---|
| Unbounded ("read it with your file tools") | flash-high | timed out at 300 s and again at 220 s, no answer; 8 tool calls, read four unrelated files, tried `agy --help` (denied by the gate), kept exploring | 297 s / 189 s | 194k / 155k |
| Bounded ("view that one file exactly once, then answer; no other files, no search, no commands") | flash-high | 1 real bug found | 176 s | 75k |
| Bounded, same prompt | flash-low | 1 different real bug found | 56 s | 19k |
| Bounded, same prompt, after both fixes landed | flash-medium | CLEAN (correct: both bugs were already fixed) | 97 s | 63k |
| "Reply with exactly PONG." | flash-high / flash-low | PONG | 23 s / 12 s | 16.7k / 16.7k |

Both bugs were genuine and both were fixed (`jq -e` masking a warning when a
later event printed `false`; dangling value flags aborting under `set -u`
without a message). Neither run hallucinated. The 16.7k tokens on a
one-word reply is the fixed cost of the loaded `AGENTS.md` and skills; it
does not reach the parent's context.

Two things the harness taught: model ids carry the effort
(`gemini-3.8-flash-low`), or `--model gemini-3.8-flash --effort low`, and a
bare `--model gemini-3.8-flash` errors with "requires --effort". A
read-only gate denial does not stop the run; the model keeps going.

## What the row says, and why each clause

- **Bounded one-shot only.** Every source points the same way: the verbosity
  and loop reports are multi-step failures; the one-shot praise is
  consistent; the local unbounded run never finished.
- **Boundaries in the brief.** The Google staffer's advice reproduced
  locally: the same task went from never finishing to a correct answer.
- **`medium` first, never `low`.** DeepSWE scores Flash medium at 71%±2
  against high's 74%±1 for 17% less cost; it has no low row for 3.8 Flash,
  and 3.7 Flash's low dropped 11 points. The user set medium as the floor so
  the cheap tier is not also an unmeasured one. Locally medium cost about the
  same as high in tokens (63k vs 75k) and ran in half the time. Escalate to
  high when medium misses.
- **Never the sole plan refuter.** The one practitioner report on plan
  review says it is too agreeable, and Omniscience gives it the lowest
  accuracy of the frontier set. As an extra refuter under plan-refute's kill
  mandate it adds a cheap different-family voice; alone it would rubber-
  stamp.
- **Not multi-step, not long-horizon.** Native-harness pass rates are
  mid-pack, output tokens are two to five times the alternatives, and the
  loop reports are what that looks like from the inside.

## Not verified

Low effort has no leaderboard row for 3.8 Flash; medium is scored only by
DeepSWE. Reddit comment bodies were
unavailable. Fable 5.1 has no DeepSWE row (Fable 5 does). The sandbox flag is
still broken here (`2026-09-15-agy-sandbox-diagnosis.md`), so `--write` runs
are unsandboxed and the row stays read-only.
