# Flutter verify loop + visual capture

Three parts: a cargo/clippy-style correctness loop, a screenshot rig that makes UI
visible, and the review pass that keeps both honest.

## 1. The verify loop

One script is the whole gate (e.g. `tool/verify-fast.sh`), run over every workspace
package:

```sh
dart format --output=none --set-exit-if-changed .          # repo-wide
(cd "$pkg" && dart analyze --fatal-infos --fatal-warnings)  # flutter analyze for app pkg
(cd "$pkg" && dart test)                                    # flutter test for app pkg
```

No such script → write one before the second change; the loop is only cheap as one
command.

**Gate hygiene** — each of these rots the gate in the direction that reads green:

- **Generated output stays out of format/analyze.** `flutter test` writes unformatted
  Dart into `app/build/` on every run. Format git's view of the tree (tracked plus
  untracked-but-not-ignored) and give the analyzer an *anchored* `build/**` exclude —
  `**/build/**` would also hide a legitimate `lib/build/` source dir that `.gitignore`'s
  unanchored `build/` already misses.
- **Derive the package list from the workspace manifest** (`pubspec.yaml` `workspace:`
  or `melos.yaml`), never hand-maintain it — a forgotten package is unverified forever,
  silently. Split Flutter- from Dart-tooled by whether the pubspec depends on the
  Flutter SDK; fail loudly if the list parses to nothing.
- **Make failures findable:** `--file-reporter json:build/test-results.json` plus a
  small summariser (test name, assertion, first repo stack frame) auto-invoked when the
  test step fails.
- **Preconditions live in the script**, not your head — e.g. the `TMPDIR` check below.

**Never buy gate speed with gate coverage.** Hash-stamps and lanes skip files that can
break the build (`pubspec.lock`, `analysis_options.yaml`, l10n, the gate script itself,
sibling packages) while still reading green — strictly worse than no change. Ask what a
speed-up stops checking, and measure its claimed numbers yourself (a handoff doc's "80%
is the compiler" measured at 28%).

**Standing rules** (with `very_good_analysis` or any strict lint set): zero warnings
*and* zero infos; exhaustive `switch` with no `default` arm; explicit null handling.
`// ignore:` is a last resort with a documented reason; respect any ignore budget — and
if that budget is a `grep -c` for a literal string, the string counts inside prose
comments too, so don't write it in explanatory text.

**`!` is a claim, not a smell.** A blanket "no bang operators" rule doesn't survive
contact with real Dart — `Map[]` is unconditionally nullable, so every SQL row read is
`row['col']!`, and Dart can't promote a non-local field or carry a `.where` filter into
the closure that follows it. Those bangs are the language, not sloppiness. The rule that
holds: **a `!` the reader can't verify from the adjacent lines needs a comment naming the
invariant it relies on** (`// Safe: PowerSync only omits opData for delete`). One that
asserts an invariant nothing establishes is the bug — fix it at the type. Audit for the
uncommented, unguarded ones; leave the mechanical ones alone.

**Named idioms** (only what the lint set can't check — don't restate lints):

Dart:

- **Guard clauses / early return** over nested `if` pyramids.
- **Sealed class + switch expression** for state modeling (loading/error/data) —
  make illegal states unrepresentable; no status-enum + nullable-fields combos.
- **Records** for multi-value returns, not one-off tuple classes.
- **Pattern matching / destructuring** over chained field access and `is`+cast.
- **Extension methods** over `Utils` classes of static helpers.
- **Named constructors** over boolean mode parameters on constructors.
- **`unawaited()`** to mark fire-and-forget futures explicitly.

Flutter:

- **Widget classes over helper methods returning widgets** — a class gets its
  own element and can skip rebuilds via const/identity; a `_buildFoo()` helper
  always rebuilds with its caller.
- **Composition over inheritance** — never subclass a concrete widget; wrap it.
- **Lift state up**; default to `StatelessWidget`.
- **Lazy children**: `ListView.builder` for unbounded lists, never
  `children: [...]`.
- **Keys on reorderable list items** (`ValueKey`/`ObjectKey`).
- **Dispose pairing**: every controller created in `initState` has a matching
  `dispose`; every listener added has a matching remove.
- **Targeted rebuilds**: when a `setState` would rebuild unchanged sibling
  subtrees, isolate the changing part in a
  `ValueListenableBuilder`/`ListenableBuilder` instead.
- **Aspect-scoped lookups**: `MediaQuery.sizeOf(context)` over
  `MediaQuery.of(context).size` (rebuilds only on that aspect).
- **Tokens through `Theme.of` / `ThemeExtension`** — no color/TextStyle
  literals in build methods.
- **`RepaintBoundary`** only where profiling shows an expensive subtree
  repainting independently of its surroundings — a redundant boundary is a
  cost, not a precaution.

Naming and layout follow **Effective Dart** — cite its rule names when in doubt.

**Cadence:** format → analyze → *touched* test files → full gate before commit. Narrow
first; the full gate is slow.

Notes:

- **Flake vs regression:** re-run the failing file alone. Passes alone, fails under
  full-suite load = load flake — say so; don't "fix" the test and destroy its signal.
- **A test asserting a default you changed** gets updated to pin the NEW value — never
  loosened to `isNotNull` or deleted. The assertion is the record of the decision.
- **`TMPDIR` must exist** or `flutter test` dies with an unrelated-looking error.

**Race idioms are mandatory, not stylistic.** Each of these is a test that passes on your
machine and fails in CI:

- **Poll, don't assume, after an un-awaited write.** A `waitFor()` helper that retries the
  read until it matches (or times out) — never a bare read on the next line, and never a
  fixed `pump(Duration(...))` tuned until it went green.
- **Pump until the target is on screen before tapping it.** SnackBar actions are the
  classic: the tap lands on nothing while the bar is still animating in, and the failure
  reads as "action didn't fire" rather than "wasn't there yet".
- **Fire-and-forget db work outlives the test.** Wrap it best-effort — an unhandled async
  error after teardown fails a *different*, innocent test, which is the worst possible
  place to spend debugging time.
- **Real IO inside a `testWidgets` body must be synchronous or under `tester.runAsync`.**
  The fake clock doesn't drive real async, so anything else hangs until timeout.

## 2. See the UI: headless screen capture

Never do UI work blind — render real screens to PNGs and read them.

A widget test pumps the real screen; `matchesGoldenFile` under `--update-goldens`
*writes* the PNG:

```dart
await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
```

Driver (`tool/shots.sh`):

```sh
flutter test test/visual --update-goldens --run-skipped --tags visual
```

Shots are gitignored review artifacts, not committed goldens.

### Faithfulness checklist

An unfaithful shot is worse than none — the run stays green while you decide from
wrong pixels. Every item below was a real silent failure:

- **Load real fonts** — app TTFs *and*
  `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`;
  otherwise every glyph is an Ahem box. **Throw** on a missing font.
- **Capture through the real app shell** so nav bar and persistent chrome are present.
- **Real safe-area insets:** `tester.view.padding = FakeViewPadding(top: 47, bottom:
  34)` plus `physicalSize` and `devicePixelRatio = 1` (PNG comes out exactly WxH).
  Missing insets + nav bar once overstated usable height by ~19%.
- **Seed realistic data** (ideally a real export) — empty states flatter the layout.
- **Shipped default settings**; overrides explicit per capture.
- **Refuse to capture loading:** assert no `CircularProgressIndicator` before capture —
  settle helpers time out and return anyway.
- **Every capture proves the state its name claims** — make the finder required:

  ```dart
  Future<void> capture(String name, {required Finder showing}) async { … }
  ```

  Assert something that exists *only* in that state (the sheet's own title, the
  selection bar's exit button), never `find.byType(TheScreen)`. Highest-value assertion
  in the rig: a step that lands on the wrong screen is silent and its PNG gets reviewed
  as real — adding this once exposed a 5-shot family capturing a blank screen.
- **Pin the clock.** Route screen-facing `DateTime.now()` through one overridable seam,
  pin in `setUp` with an `addTearDown` reset (the override is process-global). Keep the
  seam narrow — DB timestamps, logs, notification schedules keep the real clock. Verify
  by capturing at two dates and diffing: every changed shot explainable, and a screen
  still on the system clock shows up as one that *didn't* change when it should have.
- **`matchesGoldenFile` OUTSIDE any `tester.runAsync`** — it opens its own and nesting
  throws "Reentrant call to runAsync() denied". Interact inside `runAsync`, capture
  after it returns.
- **Rig out of the normal gate:** `@Tags(['visual'])` plus a `skip:` in
  `dart_test.yaml`; the driver passes `--run-skipped --tags visual`. The tag is
  load-bearing — living under `test/visual/` protects nothing, and an untagged capture
  file reddens the gate on a fresh clone with no `shots/` dir.
- **Shadows are disabled** under `flutter_test` — everything renders flat. Don't chase
  it.

### Interaction states, not just first paint

Menus, sheets, dialogs, multi-select, scrolled positions, dark mode — where layout
actually breaks. Compose small step helpers (tap, long-press, type, scroll), each
followed by a settle. Two traps:

- Long-press inside `runAsync` needs a **real** held gesture (`startGesture` + 800 ms
  delay + `up`) — `tester.longPress` uses a fake clock `runAsync` isn't driving,
  releases early, and registers as a plain tap.
- A single large `drag` gets clamped short of its delta; loop smaller drags.

### Read every shot

Non-negotiable — green tests still capture the wrong thing (tap-instead-of-long-press,
permanent spinners from unanswered platform channels, clamped scrolls). Confirm each
PNG shows what its name claims; only then reason about the design.

## 3. Review discipline

- **Review goes cross-model:** hand the diff to Codex (`codex:codex-rescue`), told
  to hunt defects and not praise. Findings back to the implementer; re-review only
  what changed. A same-family reviewer mostly confirms — leaving the family is the
  point. Plans get the same treatment via the `plan-refute` skill.
- **Mutation testing:** break each piece of wiring on purpose; if no test fails, the
  test defends nothing.
- **Negative controls:** remove the fix, confirm the regression test fails.
- **Reproduce empirically** in a separate `git worktree` — never stash/reset in a
  shared tree.
- **Ask what the fix's own failure mode is** — fixes can be worse than the bug (a
  timeout lock that expired during a modal dialog re-armed the exact double-insert it
  prevented).
- **Verify confident "why" comments** — a wrong rationale is worse than none; the next
  reader trusts it.
- **Verify against real data** — it tells you what must change and what must *not*.
- **A load-bearing number lives in a runnable assertion**, not a doc comment (two
  confidently-stated figures were off 2× and 8×). Then mutation-test the assertion:
  reintroduce the defect it prevents, confirm red.
- **Fix at the root, not the fixture:** when production disagrees with the harness,
  first ask whether production is simply wrong.
- **A subagent's report is evidence, not verdict** — re-derive the key claims before
  acting; and when a review says you're wrong, verify rather than concede reflexively.
