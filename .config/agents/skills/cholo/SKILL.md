---
name: cholo
description: House ruleset for building the smallest thing that fully meets the request. Cuts speculative code but never stated requirements, applicable future needs, repo conventions or tests. Injected at session start in every harness; also load it when the user says "cholo", asks for the simplest or minimal solution, or complains about over-engineering or bloat.
---

# Cholo

Build everything that was asked for, and only that.
Over-building is the failure this ruleset guards against. Missing a stated
requirement is worse.

## The floor: never cut these to make a change smaller

- **Stated requirements.** Everything the user, a spec, a ticket or a plan asks
  for. A spec is the minimum, not an opening offer. If an item looks
  unnecessary, build it anyway and note it under **Found**.
- **Implied guarantees.** New state and behaviour get the guarantees the
  component already gives (persistence, ordering, concurrency safety, error
  contracts) unless the request changes them. "The ticket didn't say so" is
  not a reason to drop one.
- **Applicable future needs.** Keep the extension points the code already has.
  Add a seam (a registry, a parameter, a dispatch table) only when a future
  requirement that applies to this work shapes today's design. A roadmap
  mention alone does not call for scaffolding. Never build the future feature.
- **The repo's conventions.** Use its components, design system, error types,
  layering, logging and test style.
- **Lasting tests.** Follow the repo's test conventions. A repo with no tests is
  not a reason to leave security or data-loss behaviour untested: add a focused
  regression test. Test code goes in test files, never in production modules.
- **Safety.** Input validation at trust boundaries, error handling that
  prevents data loss, security, accessibility.

## The cut: leave these out

Anything that serves a future nobody stated:

- options or config for values that never change;
- an interface with one implementation;
- wrappers that only forward one call, or scaffolding "for later";
- files, docs or comments beyond what the task, a skill or the repo's
  conventions call for;
- demo wiring: new code placed into pages, routes or screens nobody named.

## How to choose

First read the code the change touches and trace the real flow. Then take the
first option that holds:

1. **Does it need to exist?** This applies only to things nobody asked for.
2. **Is it already in this codebase?** Reuse the helper, component or pattern.
3. **Does the standard library cover it?**
4. **Does a native platform feature cover it?** If the repo has its own
   component for the job, the repo's component wins.
5. **Does an installed dependency cover it?** Never add a dependency for what
   a few lines can do.
6. **Otherwise**, write the least code that still meets the floor.

**Bugs: fix the cause, not the symptom.** Grep the callers of the function you
are about to touch. Fix the shared code once when they need the same
behaviour, and keep any caller's different contract intact.

## Scope

- Applies to code you write or change, not to prose, research or reports.
- In reviews, put concrete defects and unmet requirements first. Treat excess
  code as a finding only when you can name what it costs.
- In learning projects (the `tutor` skill), complete explanations beat brevity.
