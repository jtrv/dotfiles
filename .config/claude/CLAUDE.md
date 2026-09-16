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
Claude Code additions to the “Sufficient context, straightforward” row of the
routing table in AGENTS.md:
broad search → Explore; need your own context but not the dump → fork; a fresh
subagent when the task needs fresh context (`grind` workers) or must not see
your reasoning (refuters). Same-model Claude subagents buy context isolation,
not a different model's judgment.

## graphify
- **graphify** (`~/.config/agents/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
