---
name: openrouter
description: >
  Use when a session in any harness (Claude Code, Codex, Pi) needs one text
  generation from a model it cannot reach natively — a model outside the
  Claude, Codex and Gemini families, or a specific model id such as DeepSeek,
  Mistral, Kimi or Nemotron. Typical case: drafting a cover letter or
  resume bullets. Also use when the user says "via openrouter",
  "ask deepseek/mistral/kimi", or names an OpenRouter model id.
---

# openrouter: one completion from any OpenRouter model

`scripts/or-run` sends one chat completion and prints only the reply. Stats
(model, provider, tokens, cost) go to stderr. It is a single turn with no tools
and no file access: the model sees exactly what you send, nothing else.

## Quick reference

```sh
S=~/.config/agents/skills/openrouter/scripts
$S/or-run --model deepseek/deepseek-v4-pro-0813 "TASK"
$S/or-run --model M --system-file brief.md - < material.md   # brief as system, material as user
$S/or-run --model M --max-tokens 2000 --temperature 0.7 "TASK"
```

Exit 0 means stdout is the reply. Non-zero means no reply, and stderr says why.
Model ids and prices come from the keyless `https://openrouter.ai/api/v1/models`.

## Which model

| Job | Model | Why |
|---|---|---|
| Polished prose that must not read AI-written (letters, messages, docs) | `deepseek/deepseek-v4-pro-0813` | Clean Slop Index score (19.4 overall, 24.0 email) with the lowest tells of the clean group, at $0.66/$1.98 per M tokens. Not yet A/B'd against `openai/gpt-6-luna`, the current runway pick. |
| Fallback for that | `mistralai/mistral-large-4-0` | 18.8 overall. It is a reasoning model, so give it ≥1000 `--max-tokens` or its reasoning eats the reply. |

Evidence and re-check steps: `~/notes/agent-wiki/wiki/ai-prose-model-choice.md`.
For coding, review or investigation, use the routing table in `AGENTS.md`, not
this skill: it has no tools, so it can't read a repo.

## Data

The default request sets `provider.zdr: true` and `data_collection: "deny"`, so it
only routes to providers that neither retain nor train on prompts. A model with no
such provider fails with an error instead of falling back.
`--allow-retention` lifts that. Use it only for material you would post publicly.
Never send `*.local.*` files, contact details or keys. The key stays out of argv:
curl reads the auth header from a process substitution.

## Setup

- `OPENROUTER_API_KEY` must be in the environment, globally or from a project's
  untracked `.config/mise/config.local.toml`.
- Needs `curl` and `jq`. A Codex sandbox without network can't run it; call it from
  the steering session instead.
- Self-check after editing the script: `scripts/or-run.test.sh` (fake curl, no
  network, no key).
