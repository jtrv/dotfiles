# OpenRouter route for one-shot generation, and the prose-model pick (2026-10-23)

## Decision
- **New route:** "OpenRouter `<model>`" via the `openrouter` skill (`or-run`). It gives
  every harness one tool-less completion from any OpenRouter model. The user asked for
  this as a general pattern, starting from the runway prose pipeline.
- **runway `PROSE_MODEL` stays `openai/gpt-6-luna`.** `deepseek/deepseek-v4-pro-0813`
  is the candidate, pending an A/B on real letters.
- **The "Substantial prose" row is unchanged.** It stays on gpt-6.1-sol, which
  `2026-09-24-prose-model-choice.md` chose for writing *quality* (EQ-Bench Elo and
  rubric). The data below measures *how AI-like* text is, a different axis. Docs need
  quality first; a facts-locked letter needs low AI-likeness first.

## Evidence (snapshot 2026-10-23)
**The Slop Index** (`theslopindex.com/bench.json`): 58 models, 112 scenarios, 64,636
generations at default settings, scored against pre-2022 human writing. Lower is
cleaner. `overall` uses mechanical weights only (conciseness 0.35, templating 0.30,
rhythm 0.20, tells 0.15). Its own sensitivity test says report the axes separately:
the exact ranking held in 0% of 500 reweightings.

| model | overall | email | tells | rank spread | $/M in/out (OpenRouter) |
|---|---|---|---|---|---|
| nvidia/nemotron-3.5-lightning | 18.2 | 21.2 | 52.0 | 56–58 | 0.07/0.20 |
| mistralai/mistral-large-4-0 | 18.8 | 24.0 | 34.9 | 55–58 | 1.36/4.18 |
| deepseek/deepseek-v4-pro-0813 | 19.4 | 24.0 | 24.1 | 53–57 | 0.66/1.98 |
| thinkingmachines/inkling-small | 19.4 | 22.4 | 36.4 | 53–57 | 0.45/1.20 |
| moonshotai/kimi-k2.6 | 21.1 | 26.9 | 35.5 | 48–56 | 0.65/3.41 |
| openai/gpt-6-luna | 25.5 | 29.1 | 27.5 | 29–43 | 0.10/0.50 |
| openai/gpt-6.1-sol | 32.6 | 36.1 | 30.1 | 7–18 | 2/10 |
| anthropic/claude-opus-5.5 | 36.7 | 41.3 | 28.0 | 3–6 | — |

- DeepSeek V4 Pro 0813 is the most balanced of the clean group, with the lowest
  tells. Nemotron's overall score hides the highest tells on the board.
- The top five have overlapping rank spreads, so they are statistically tied.

**Live checks, 2026-10-23:** `or-run` with the ZDR filter on (`provider.zdr`,
`data_collection: deny`):
- DeepSeek V4 Pro 0813 routed via Together, and gpt-6-luna via Azure; both answered.
- Mistral Large 4 spent a 60-token budget on reasoning and returned no content. It
  needs ≥1000 max tokens.

## Caveats
- The Slop Index measures default voice with no system prompt, and has no facts-fidelity
  axis. The arena vote has 1–18 games for current models.
- No A/B on our own material yet. Two researchers in
  `~/notes/agent-wiki/raw/2026-10-23-unslop-research-fanout.md` recommend seeded
  factual mutations plus a blind human read before switching.
- Wiki synthesis: `~/notes/agent-wiki/wiki/ai-prose-model-choice.md`.

## A/B result (same day)
Four real runway jobs, luna vs DeepSeek V4 Pro 0813, blind and randomized per job. The user's
style picks split 2–2. In round 1 DeepSeek made three claim-strengthening errors and luna made two
mechanical ones (placeholder, mistagged sentence); both fixed everything in one round. Luna
stays as `PROSE_MODEL`. Detail: `~/notes/agent-wiki/wiki/ai-prose-model-choice.md`.

## Superseded the same evening
The runway prose pipeline (claim tables, tagged sentences, a checker, a fix loop) was removed
at the user's call: under any brief, every model opened by restating the posting, and the
claim tables' resume wording leaked into the letters. The replacement is one plain message
(the JD, `profile/history.toml`, `profile/swe/experience.md`, and "a one-paragraph cover letter
and the Full Stack bullets"), no system prompt. Blind picks over 3 SWE jobs × 4 models:
DeepSeek V4 Pro 2, GPT-6 Astra 1, Opus 5.5 0, Fable 5.1 0; every pick was in the shorter half.
Unchecked output still needs a fact check: all three picks had misattributions (see the wiki).
