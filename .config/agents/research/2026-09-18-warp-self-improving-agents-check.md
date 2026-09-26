# Warp's self-improving-agent pattern vs this setup — 2026-09-18

Source: https://claude.com/blog/how-warp-builds-self-improving-agents-on-claude
(Anthropic customer post; webinar FAQ included). Warp's pattern: an inner
skill does the work, humans leave feedback where the work happens, an outer
"improver" skill runs on a schedule, pulls the feedback, and proposes the
smallest edit to the inner skill as a PR a human merges.

## Applied well

- **Principles with the why.** `AGENTS.md` comments rule, `contexts/harnesses.md`
  (every rule carries the incident behind it), memory template mandates
  `**Why:**` / `**How to apply:**`.
- **Small skills, progressive disclosure.** `AGENTS.md` is 109 lines and an
  index; contexts load on demand; language skills are 6-line pointers;
  watches are bundled scripts, not re-derived each run. Only `typescript.md`
  (322 lines) is heavy among hand-written files; the big ones are vendored.
- **Skills vs memory kept apart** (the FAQ's first warning). Memory is
  auto-written per project; contexts/skills change deliberately, with an
  evidence requirement and the strongest-model rule.
- **Feedback is expert and detailed.** One senior user, corrections written
  with the why at the moment they happen — the lowest-friction capture there is.

## The gap: no improver

- 22 `type: feedback` memories across 19 project memory dirs; 12 sit in
  `shiso` and most of those are about harness behaviour (Codex dispatch,
  classifier blocks, batch protocol), not shiso. Feedback lands where the
  session was, not where the rule lives, and no other project's session
  sees it.
- Promotion to a loaded file happens, but only when a human remembers:
  `harness-code-strongest-model` → `AGENTS.md` strongest-model rule
  (2026-09-15); `agent-dispatch-classifier-blocks` → `CLAUDE.md` agent
  dispatch rule. `lessons-from-memory.md` was one manual improver run,
  never re-run, and nothing loads it.
- Nothing reports "N feedback memories not yet folded into a context or
  skill". The memory instructions say when to write a memory and never say
  when one graduates.
- No verification harness for skills. `writing-skills` (vendored) demands a
  baseline scenario before writing a skill; no hand-written skill has one.
  `harnesses.md` verifies wiring by interrogation, which checks loading, not
  behaviour.
- No global metric (turns, wall time, retries) is tracked or fed back;
  `2026-08-25-post-counting-agent-turns.md` argues for one.

## Smallest next step — built

`../watches/feedback-graduation.sh`: lists `type: feedback` memories across
every project memory dir newer than the last `ack`, with the context/skill
each names. First run listed 22, five of them the same no-coauthor rule in
five repos that `AGENTS.md` had already absorbed — the graduation is not
recorded anywhere, which is what the marker now does. Pointer in
`../contexts/harnesses.md` (fold feedback before changing instructions). Not scheduled; it runs when a
session is about to change a loaded file.

## First improver pass (2026-09-18)

22 memories reviewed. Already graduated (left in place): the five
no-coauthor duplicates, comment style, classifier blocks, Codex dispatch,
verify loops (flutter/kotlin), plan-refute's origin. Project-only (stay as
memory): scan triage board, mise builds, mise pre-1.0 no-compat, mise model
split. Folded, seven:

| memory | into |
|---|---|
| `commit-messages-via-file` | `AGENTS.md` Commits: `-F <file>` beyond a one-line subject |
| `harness-code-strongest-model` | `AGENTS.md` strongest-model rule covers harness code; `harnesses.md` Changing delegate: Codex scratch-copy workflow |
| `refute-the-refuters-numbers` | `skills/plan-refute`: derived vs chosen constants |
| `mise-agent-batch-protocol` | `contexts/parallel-agents.md`: return docs only, one owner per shared file, lead runs the gate |
| `mise-decision-bundling` | `contexts/long-tasks.md` Open questions |
| `mise-render-for-decision` | `contexts/ui.md` (new, platform-neutral): taste calls from rendered variants; `flutter.md` §2 points at it |
| `workflow-failure-detection` | `CLAUDE.md` Workflow (Claude-only tool) |

Marker acked. The five duplicate no-coauthor memories could be deleted; not
done, they are harmless and in other projects' dirs.
