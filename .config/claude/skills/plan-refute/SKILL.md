---
name: plan-refute
description: >
  Adversarial cross-model refutation of plans before implementation. Use
  whenever a plan, design, architecture decision, or multi-step implementation
  strategy is produced — before writing the code it describes — and when the
  user says "refute this", "plan-refute", or asks to stress-test a plan's
  claims. Adapted from the geiger skill's Phase 3.5 refute protocol.
---

# Plan refutation protocol

Every plan gets adversarially refuted before implementation. Agreement is not
evidence; only surviving a kill attempt is.

## Protocol

1. **Decompose** the plan into discrete, load-bearing claims/steps. A claim is
   load-bearing if being wrong about it would change the design (API exists and
   behaves as assumed, size/perf number, platform capability, library
   maintenance status, licensing, ordering constraint). Skip trivialities —
   refuting "we will create a directory" is theater.
2. **Spawn one refuter per claim** with context asymmetry: the refuter gets the
   claim, the repo, and the relevant docs/URLs — **never the planner's
   reasoning or evidence**. Anchoring on the planner's argument is how
   correlated errors survive.
3. **Kill mandate**, verbatim in every refuter prompt: *"Refute this claim with
   a concrete code fact, doc citation, metric, or runnable check — or fail.
   Do not evaluate plausibility; attempt to kill."*
4. **Prefer a different model family.** If the Codex CLI is available
   (`command -v codex`), use `codex exec` with read access to the repo
   (sandbox read-only) as the refuter. Cross-model refuters catch
   correlated-training errors that same-model review endorses. Fall back to a
   same-model subagent otherwise.
5. **Disposition:**
   - Refuted → revise the plan step, or downgrade it to an open question in
     the plan doc. Note the refutation inline.
   - Unrefuted → stays as planned. Never upgrade confidence on agreement.
6. **Record** a short refutation table in the plan doc or PR description:
   claim | refuter verdict | disposition. A plan isn't done until the table
   exists.

## Scope calibration

- Small tactical plans (single-file change): refute only if a claim rests on
  an unverified external fact. Otherwise the verify gate is the check.
- Feature/architecture plans (new module, data pipeline, platform hook,
  dependency choice): full protocol, one refuter per load-bearing claim,
  refuters run in parallel.
- Anything citing a number (DB size, rate limit, API cap, store size limit):
  always refute — confidently-stated figures have measured wrong by 2–8× in
  past reviews; a refuter must recompute or re-source it independently.

## Codex invocation shape

```sh
codex exec --sandbox read-only \
  "Claim under test: <claim>. Refute this claim with a concrete code fact, \
   doc citation, metric, or runnable check — or output exactly UNREFUTED \
   with one line of what you checked. Do not evaluate plausibility; attempt to kill." \
  </dev/null
```

Notes (smoke-tested 2026-07-29, codex-cli 0.144.6): `</dev/null` is required or
codex blocks reading stdin; the repo must be a git repository or codex refuses
the directory without `--skip-git-repo-check`.

Parallelize refuters via background Bash or the codex-rescue agent when there
are several claims.
