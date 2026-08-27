---
name: handoff
description: >
  Write or resume from a verified HANDOFF.md so a fresh session can continue work
  without inheriting a degraded context. Use when the user says "handoff",
  "write a handoff", "wrap up this session", "prepare to continue later", or when
  starting a session in a repo whose root contains HANDOFF.md ("resume", "pick up
  where we left off"). Prefer this over /compact for long tasks: fresh session +
  handoff beats another compaction cycle.
---

Two modes. If HANDOFF.md exists and the user is starting/resuming work → RESUME.
Otherwise → CREATE.

## Core rule: verify, don't remember

Every factual claim in a handoff is tagged:
- `[V]` — verified NOW, during this handoff run, by a command or fresh file read
- `[?]` — from conversation memory, unverified

A handoff written purely from memory is worse than none: it launders a degraded
session's confusion into an authoritative-looking document. When tempted to skip
verification ("I remember clearly", "tests were passing earlier"), that's the
signal to verify: run it again, read it again.

## CREATE mode

1. If HANDOFF.md exists: move it to `.handoffs/<YYYY-MM-DD-HHMM>-handoff.md`
   (create dir, ensure `.handoffs/` is gitignored). Carry its still-relevant
   "Failed approaches" entries forward into the new file.
2. Verify before writing: `git status`, `git log --oneline -5`, `git diff --stat`;
   re-run the relevant test/build command and capture the tail of its output;
   fresh-read any file you're about to make claims about.
3. Write HANDOFF.md at project root, sections in this order:

```markdown
# Handoff — <task title> (<date>)

## Goal
What we're doing and explicit non-goals.

## Verified state
Branch, SHA `[V]`, working-tree status `[V]`, uncommitted files `[V]`.
Test/build result: paste the actual output tail `[V]` — never "tests pass" from memory.

## Decisions
- [accepted] ... — rationale
- [provisional] ... — revisit when X
- [superseded] ... — replaced by Y

## Failed approaches
What was tried, the observed failure, condition under which it could be reconsidered.

## Known traps
Gotchas the next session will hit.

## Side effects already performed
Migrations run, packages installed, services restarted, pushes made —
anything that must NOT be repeated.

## Next steps
Ordered. Step 1 concrete enough to execute immediately.

## Open questions
```

4. Budget: ≤250 lines, hard cap 400. When cutting, cut in this order:
   prose → old decisions → traps. Never cut Failed approaches or Side effects.
5. Tell the user the path and that they can `/clear` or start a fresh session
   pointing at it.

## RESUME mode

1. Read HANDOFF.md. Do not trust it yet. Name the two or three claims whose
   being wrong would most change Next steps; step 2 verifies those first.
   "Side effects already performed" is binding regardless — never re-run one.
2. Re-verify: compare recorded SHA/branch against `git log -1` and `git status`;
   re-run the recorded test command. Report drift explicitly:
   "handoff says X, repo shows Y."
3. Surface Open questions and any `[?]`-tagged claims that matter to the next step.
4. State the plan (from Next steps, adjusted for drift) and confirm before
   large or destructive actions.
5. Never repeat anything listed under Side effects already performed.
