# Python verify loop

Stack: `uv` (env/runner) + `ruff` (format + lint) + `basedpyright` (types) + `pytest`.
Everything runs through `uv run` / `uv tool` — never bare `pip`/`python`.

## 1. The gate

One command, ideally a mise task (`mise run check`) so it's discoverable and canonical:

```sh
uv run ruff format --check .
uv run ruff check .
uv run basedpyright
uv run pytest -q
```

No task/script yet → write one before the second change; the loop is only cheap as
one command. `uv run` auto-syncs the env from the lockfile, so the gate also catches
drift a stale venv would hide.

**Strictness parity with clippy `-D warnings`:**

- ruff: broad `lint.select` (at minimum `E,W,F,I,UP,B,SIM,RUF,PTH,FBT,TRY,C4,PIE,PERF`
  — lint rules beat prose: pathlib, boolean traps, exception style, comprehension and
  perf idioms are enforced, not requested), zero violations,
  **no per-file-ignores dumping ground**. `# noqa: RULE` is the `#[allow]` analog —
  rule code mandatory (`lint.unfixable` aside, enforce via `RUF100` unused-noqa +
  ruff's `noqa` requires-code behavior), documented reason, last resort.
- basedpyright: `typeCheckingMode = "recommended"` (or `"all"`), every diagnostic
  `"error"`. Three load-bearing settings:
  - `reportIgnoreCommentWithoutRule = "error"` — bare ignores are a gate failure.
  - `reportUnnecessaryTypeIgnoreComment = "error"` — stale suppressions are a gate
    failure (the RUF100 analog; verified live on 1.39.0).
  - leave `enableTypeIgnoreComments` off (default) so blanket `# type: ignore`
    doesn't work at all; suppressions are `# pyright: ignore[ruleName]` only.
- **Tests are type-checked too** — fixture/mock type drift should be red before
  pytest runs. New code: annotate test params (strict mode requires it). Legacy
  suites: relax *only* the missing/unknown-annotation rules for `tests/` via a
  scoped `executionEnvironments` override — never exclude `tests/` wholesale, which
  hides the drift the check exists to catch.
- pytest runtime warnings are errors:

  ```toml
  [tool.pytest.ini_options]
  filterwarnings = ["error"]
  addopts = "--strict-markers --strict-config"
  xfail_strict = true
  ```

  Expect to curate a small `ignore::...` list for third-party deprecations from day
  one — pytest applies the filter during collection/import too, so upstream noise
  *will* hit the gate; each entry gets a comment, same discipline as `# noqa`.
  `pytest.warns(...)` and `@pytest.mark.filterwarnings` are the per-test escape
  hatches. `xfail_strict` makes an XPASS a failure, not silent green.
- **One version of truth:** `requires-python` (lower bound = oldest supported
  version) plus `.python-version`. ruff infers `target-version` from the
  `requires-python` lower bound automatically; basedpyright **never reads it** — it
  defaults to the venv interpreter, silently approving syntax older supported
  interpreters reject. Set `pythonVersion` explicitly to the same lower bound.
- **No baseline files.** basedpyright has `--writebaseline`; never run it. A baseline
  converts today's entire debt into permanently invisible passes. If a repo already
  has `.basedpyright/baseline.json`, treat it as gate-rot to burn down, and add
  `test ! -e .basedpyright/baseline.json` to the gate meanwhile.
- Exhaustiveness: `match` over enums/unions ends in `case _: assert_never(x)`
  (`typing.assert_never`) — adding a variant must be a type error, the sealed-`when`
  analog.
- Editor = gate: install `basedpyright-langserver`, not Pylance — spec disagreements
  between engines generate noise that trains you to ignore squiggles.

**Large-repo escape hatch:** basedpyright is pyright-speed (minutes on 100k+ LOC).
If the gate crosses ~30s of type checking, switch to `pyrefly` (Rust, ~50x faster,
1.0-stable, same zero-warning discipline) and accept its one gap: suppression codes
can't be *required*, so police bare `# pyrefly: ignore` with a grep step in the gate.
Never adopt pyrefly's baseline/bulk-suppress features (`pyrefly suppress`,
`--baseline`) — same rot, shinier tooling.

**Watchlist:** `ty` (Astral) — re-evaluate when it hits 1.0 *and* closes two gaps:
spec conformance (~76% as of 2026-07) and strict inference on unannotated code.
It's the natural fit for the uv/ruff stack once mature.

## 2. Cadence

Narrow first, gate before commit:

```sh
uv run ruff check --fix path/touched.py && uv run ruff format path/touched.py
uv run basedpyright path/touched.py          # types on touched files
uv run pytest tests/test_touched.py -x -q    # touched tests only
mise run check                               # full gate, pre-commit
```

**Failures:** `pytest --tb=short` for the assertion + first repo frame; add
`--junitxml=build/test-results.xml` in CI so failures are greppable, don't scroll
console output. ruff and basedpyright both print `file:line:rule` directly.

## 3. Named idioms

The un-lintable residue — each names a specific idiom because generic "be pythonic"
prose measurably does nothing (and the checkable subset lives in the ruff select
above). Mostly anti-Java-isms:

- **No class wrappers around functions.** A class with only static/class methods or
  a single `run()` is a module — use module-level functions.
- **Plain attributes, no getters/setters.** `@property` only when behavior is
  actually needed — that's what makes it safe to start with a plain attribute.
- **`Protocol` over ABC inheritance for interfaces.** Structural typing is the
  idiom; skip the `@abstractmethod` ceremony unless shared behavior is inherited.
- **Parse, don't validate.** Convert external data (JSON, DB rows, config) into
  frozen `slots=True` dataclasses at the boundary; don't pass dicts through the
  core — typed objects are what make the strict type gate bite.
- **Let exceptions propagate.** Catch only where you can handle or add context;
  never blanket try/except-log-and-continue. `TRY` lints the shape; where to catch
  is judgment.
- **`collections`/`itertools` before hand-rolling** — `Counter`, `defaultdict`,
  `groupby` over accumulation loops.

## 4. Notes

- **Flake vs regression:** re-run the failing test alone. Passes alone, fails under
  full-suite load = load flake — say so; don't "fix" the test and destroy its signal.
- **A test asserting a default you changed** gets updated to pin the NEW value —
  never loosened or deleted. The assertion is the record of the decision.
- **Fixtures over mocks where a real object is cheap**; a mock that re-implements the
  dependency's behavior is a second copy of the bug surface.
- **Pin the clock** through one injectable seam (`freezegun` or an explicit `now()`
  parameter); a direct `datetime.now()` read in screen/report-facing code is a
  production bug to fix, not a fixture problem.
- **Lockfile is part of the gate:** `uv lock --check` fails if `pyproject.toml` and
  `uv.lock` drifted — cheap, add it to the task.
- **One-off scripts:** PEP 723 inline metadata (`# /// script` block) + `uv run
  script.py` — deps declared in the file, isolated ephemeral env, `requires-python`
  even fetches a matching interpreter. No ad-hoc venvs for quick scripts.

## 5. Shared discipline

- **Never buy gate speed with gate coverage.** Hash-stamps and skip-lanes stop
  checking files that can break the build while still reading green — strictly worse
  than no change. Ask what a speed-up stops checking; measure claimed numbers
  yourself.
- **Independent adversarial review:** fresh agent told to hunt defects, findings back
  to the implementer, re-review; ~3 rounds. Cross-model plan refutation is the
  `plan-refute` skill.
- **Mutation testing** (break wiring, confirm red) and **negative controls** (remove
  the fix, confirm the regression test fails).
- **Reproduce empirically** in a separate `git worktree` — never stash/reset in a
  shared tree.
- **A load-bearing number lives in a runnable assertion**, not a doc comment; then
  mutation-test the assertion.
- **Fix at the root, not the fixture:** when production disagrees with the harness,
  first ask whether production is simply wrong.
- **A subagent's report is evidence, not verdict** — re-derive key claims before
  acting; when a review says you're wrong, verify rather than concede reflexively.
