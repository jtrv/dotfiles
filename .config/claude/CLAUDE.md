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

## Workflow
A workflow agent's outcome is its `state` field in `workflowProgress` or
the `<failures>` block of the task notification — never inferred from which
agents wrote a `result` line in `journal.jsonl`. An agent killed mid-response
writes no record at all, so the journal shows it as still running; three
dead agents were once reported as "nothing failed". Re-run dead agents in a
fresh focused workflow, and forbid `WebFetch` in the re-run if that is where
they hung.

## graphify
- **graphify** (`~/.config/agents/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
