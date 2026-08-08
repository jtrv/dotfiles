# Kotlin verify loop

## 1. The gate

One command, from the root so every subproject's `check` runs:

```sh
./gradlew --console=plain -q check
```

Module discovery comes free from `settings.gradle.kts` — never a hand-maintained
list. If a wrapper script (e.g. `tool/verify.sh`) adds discovery or summaries, the
wrapper is the gate; keep it one command either way.

**Everything attaches to `check`:** ktlint, detekt, Android Lint, unit tests. The
gate never hardcodes task names, so a plugin not attached to `check` is silently
unverified — prove new attachments by mutation: break a rule, watch `check` go red,
revert.

**Strictness parity with clippy `-D warnings`:**

- Kotlin compiler: `allWarningsAsErrors = true`.
- ktlint: fail on any violation, **no baseline**.
- detekt: `warningsAsErrors: true`, **no baseline**; `@Suppress` is the `// ignore:`
  analog — last resort, documented reason. Enable the inactive-by-default rules
  `UnsafeCallOnNullableType` (with `excludes: ['**/test/**']` —
  assertion-adjacent `!!` is tolerated there, production code never) and
  `GlobalCoroutineUsage`. Not `NamedArguments`: it gates total
  argument count, not the boolean/adjacent-same-type ambiguity this policy
  targets.
- Android Lint: `warningsAsErrors = true`, `abortOnError = true`.
- `when` over sealed types: **no `else` branch** — adding a subtype must be a compile
  error.

A baseline file is gate-rot's special case: it converts today's entire debt into
permanently invisible passes. Never generate one to get green.

**Named idioms** (only what the gate can't check — don't restate ktlint/detekt rules):

Kotlin:

- **Guard clauses / early return** over nested `if` pyramids.
- **Sealed hierarchies + `when` expression** for state modeling (loading/error/data)
  — make illegal states unrepresentable; no status-enum + nullable-fields combos.
  (Exhaustiveness itself is gated above; this is the modeling choice.)
- **Data classes + `copy`** for value semantics; immutable by default.
- **`require`/`check`/`error`** for preconditions over hand-rolled if-throw;
  `requireNotNull`/`checkNotNull` with a message over `!!`.
- **Extension functions** over `Utils` classes of static helpers.
- **Named arguments** at call sites with boolean or adjacent same-typed parameters.
- **Scope-function discipline**: `apply` for configuration, `let` for
  null-shielding/transforms, `also` for side effects — and **no nesting**; name
  the receiver or extract a function instead.

Coroutines:

- **Structured concurrency** — every created scope has a documented owner and
  cancellation point (`GlobalCoroutineUsage` above gates only
  `GlobalScope.launch`/`async`; ownership it can't see).
- **Inject dispatchers** (constructor parameter), never hardcode
  `Dispatchers.IO`; suspend functions are **main-safe** — blocking or CPU-heavy
  work moves via `withContext(injectedDispatcher)` inside the function, never
  at the call site.
- **Immutable exposure**: private `MutableStateFlow` behind public `StateFlow`
  (`asStateFlow()`).

Compose:

- **State hoisting + unidirectional data flow** — composables take state and emit
  events; state lives above.
- **`modifier: Modifier = Modifier`** as every public composable's first optional
  parameter, applied to its root.
- **`remember(keys…)`** only for expensive calculations whose inputs are the
  keys; **`derivedStateOf`** only when inputs change more often than the UI
  needs to update — cheap derived values are computed directly.
- **Keys on lazy list items** (`items(key = ...)`).
- **`CompositionLocal`** only for tree-wide ambient dependencies (theme, locale);
  screen- or component-specific dependencies are explicit parameters.

Naming and layout follow the official **Kotlin coding conventions**; cite
**Effective Kotlin** item names when in doubt.

## 2. Cadence

Narrow first, gate before commit:

```sh
./gradlew -q :app:ktlintCheck :app:detekt              # touched module style/lint
./gradlew -q :app:testDebugUnitTest --tests 'TouchedClass*'  # touched tests only
./gradlew --console=plain -q check                      # full gate, pre-commit
```

**Failures:** the assertion and stack live in `build/test-results/**/TEST-*.xml`
(grep for `<failure`) and `build/reports/tests/**/index.html` — don't scroll console
output. Lint: `build/reports/lint-results-*.html`; detekt prints file:line directly.

## 3. See the UI: Roborazzi headless screenshots

Compose analog of the Flutter capture rig: **Roborazzi** on Robolectric Native
Graphics renders real Compose screens to PNGs on the JVM — no emulator. Same iron
rules, translated:

- `captureRoboImage()` in a Robolectric test writes the PNG;
  `-Proborazzi.test.record=true` switches record mode. Shots are gitignored review
  artifacts, not committed goldens.
- **Out of the normal gate:** separate source set or test filter so `check` never
  runs record mode; a dedicated `tool/shots.sh` drives it.
- Real device profile (`@Config(qualifiers = RobolectricDeviceQualifiers.Pixel7)`) so
  size/density/insets are honest; dark/light explicit per shot.
- **Every capture proves the state its name claims** — assert something that exists
  only in that state, never just the root composable.
- **Pin the clock** via an injectable seam; a direct `System.currentTimeMillis()`
  read is a production bug to fix, not a fixture problem.
- Seed realistic data; refuse to capture loading states; read **every** PNG and
  confirm it shows what its name claims.

## 4. Shared discipline

- **Never buy gate speed with gate coverage.** Hash-stamps and skip-lanes stop
  checking files that can break the build while still reading green — strictly worse
  than no change. Ask what a speed-up stops checking; measure claimed numbers
  yourself.
- **Flake vs regression:** re-run the failing test alone. Passes alone, fails under
  full-suite load = load flake — say so; don't "fix" the test and destroy its signal.
- **A test asserting a default you changed** gets updated to pin the NEW value —
  never loosened or deleted.
- **Review goes cross-model:** hand the diff to Codex (`codex:codex-rescue`), told
  to hunt defects and not praise. Findings back to the implementer; re-review only
  what changed. A same-family reviewer mostly confirms — leaving the family is the
  point. Plans get the same treatment via the `plan-refute` skill.
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
