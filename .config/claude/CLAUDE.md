# User-global instructions

@~/.config/agents/AGENTS.md

The sections below are Claude Code only. Everything shared with other agents
lives in the imported file above — put new cross-agent rules there, not here.

## Agent dispatch
A classifier-blocked Agent dispatch gets ONE honestly reworded retry
(loop/load-test and scraping-adjacent phrasing are known triggers). Blocked
again: do the task in the main loop or park it for the user — never
disguise it to slip past.

## Routing
| Situation | Route |
|---|---|
| Sufficient context, straightforward | Stay here. Bulky byproduct (long test/log/grep output) → `ctx_execute`, printing the derived answer, never the dump; broad search → Explore; need your own context but not the dump → fork. A fresh subagent when the task needs fresh context (`grind` workers) or must not see your reasoning (refuters) |
| Nontrivial plan or design ready, not yet built | `plan-refute` (its small-tactical-plan exemption applies) |
| Implementation ready | Suggest the user run `/codex:review`, or `/codex:adversarial-review` when the approach itself is in question — both are user-invoked only |
| Repeated attempts have failed | `codex:codex-rescue` with the repro, evidence, and failed approaches; ask for a testable alternative explanation |
| Substantial separable task, clear inputs and acceptance check | `codex:codex-rescue` with `--model gpt-5.6-luna` (mechanical, near-zero judgment: fixtures, extraction, doc updates, isolated helper — not general coding) or `--model gpt-5.6-terra` (bounded coding or investigation needing judgment). Inspect the result. Quick tasks stay inline |
| Demanding coding work — multi-file implementation, nontrivial refactor, sustained reliability over a long task | `codex:codex-rescue` with `--model gpt-5.6-sol`. Inspect the result |
| Ambiguous, hard debugging, substantial independent review | Codex with `-m gpt-6-astra` or stay on Fable |
| Ordered queue of separable tasks | `grind` |

Codex tiers for delegated tasks: Luna → Terra → Sol → Astra; a blocked worker
gets more effort before a higher tier. Luna is the mechanical tier, not a
cheap coding default — start coding work at Terra. Skill-owned dispatch
(`grind` workers, `plan-refute` refuters) is unchanged. Same-model Claude
subagents (Explore, forks, `grind` workers) buy context isolation.

## graphify
- **graphify** (`~/.config/agents/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
