---
name: flutter-verify-loop
description: Tight verify loop and headless screen-capture workflow for Flutter/Dart repos — format/analyze/test after every edit under strict lints, plus a widget-test rig that renders real screens to PNGs the agent then reads, so UI decisions come from pixels instead of imagination. Use whenever editing Dart or Flutter code in any package, before committing Flutter work, when a strict-lint gate (very_good_analysis, --fatal-infos) is red, and especially for any Flutter UI/UX/layout/design task — "does this fit on a phone", spacing, density, dark mode, a new screen, sheet, menu or empty state. Also covers the review discipline around both — adversarial re-review rounds, mutation testing, and negative controls.
---

# Flutter verify loop + visual capture

Two halves of one idea. Half 1 is a cargo/clippy-style loop that keeps correctness
cheap to check. Half 2 applies the same looping discipline to UI by making the UI
*visible* to you. Half 3 is the review pass that keeps both honest.

## 1. The verify loop

Every Flutter/Dart repo should have one script that is the whole gate — e.g.
`tool/verify-fast.sh`. Its shape, run over every workspace package:

```sh
dart format --output=none --set-exit-if-changed .          # repo-wide, covers Dart + Flutter alike
(cd "$pkg" && dart analyze --fatal-infos --fatal-warnings)  # flutter analyze for the app package
(cd "$pkg" && dart test)                                    # flutter test for the app package
```

If the repo has no such script, write one before the second change — the loop is
only cheap if it is one command.

**Gate hygiene — four things that silently rot a gate.** Each of these has been
found live, and each fails in the direction that reads as green:

- **Keep generated output out of format and analyze.** `flutter test` writes
  unformatted Dart into `app/build/` (isolate-spawner shims) on *every* run, so
  `dart format .` makes the gate permanently red the moment anyone runs the tests.
  Format git's view of the tree instead — tracked *plus*
  untracked-but-not-ignored, so a brand-new file can't skip the gate on the commit
  that introduces it — and add an anchored `build/**` to the analyzer's `exclude`.
  Anchored, not `**/build/**`: the recursive form also hides a legitimate
  `lib/build/` source directory, and since `.gitignore`'s `build/` is unanchored
  too, such a directory would then be checked by nothing at all.
- **Derive the package list from the workspace manifest**, never hand-maintain it
  in the script. A package added to `pubspec.yaml`'s `workspace:` (or `melos.yaml`)
  and forgotten in the script's array is unverified *forever*, silently. Split
  Flutter- from Dart-tooled packages by whether the pubspec depends on the Flutter
  SDK, and fail loudly if the list parses to nothing.
- **Make failures findable.** The human reporter interleaves every test name, print
  and stack frame; a red app suite is thousands of lines and finding *which* test
  failed means grepping backwards through all of it. Add
  `--file-reporter json:build/test-results.json` and a ~40-line summariser that
  prints the test name, the assertion and the first repo stack frame, invoked
  automatically when the test step fails.
- **Put preconditions in the script, not in your head** — the `TMPDIR` check below
  is three lines at the top and saves the same ten minutes every time.

**Never buy gate speed with gate coverage.** Proposals to skip the gate on a
content hash, or to split it into lanes, are the dangerous ones: a stamp keyed on
`lib/` + `test/` ignores `pubspec.lock`, `analysis_options.yaml`, the l10n files,
the gate script itself and every sibling package — each a change that can break the
build while the gate reports green in 0 s. A gate that stops checking something is
strictly worse than no change, because it still reads as a pass. Before adopting any
speed-up, ask what it stops checking, and measure rather than accept the claimed
numbers: a handoff doc's headline "80% of the gate is the compiler" measured at 28%,
and three of its proposals rested on it.

**Standing rules** (with `very_good_analysis` or any strict lint set):
zero warnings *and* zero infos; no `!` bang operators; `switch` exhaustive with no
`default` arm (so adding a case is a compile error, which is the point of sealed
types); explicit null handling. A `// ignore:` is a last resort — if the repo has an
ignore budget, respect it and document the reason.

**Cadence after every change:** format → analyze → run the *touched* test files →
full gate before commit. Run the narrow thing first; the full gate is slow and you
will run it many fewer times if the narrow one catches the mistake.

Practical notes that save real time:

- **Flakes vs. regressions.** Re-run the failing file in isolation. A test that
  passes alone and fails only under full-suite load is a load flake, not a
  regression you caused — say so plainly instead of "fixing" it. Changing a test to
  chase a flake destroys the signal it was there to give.
- **A test that asserts on a default you changed must be updated to pin the NEW
  behavior deliberately** — asserting the new value, not loosened to `isNotNull` or
  deleted. The updated assertion is the record of the decision.
- **`TMPDIR` must exist** or `flutter test` dies with an unrelated-looking error.
  Check it first when a run fails before any test output appears.

## 2. See the UI: headless screen capture

Do not do UI/UX work blind. Render the real screens headlessly and write PNGs you
can then read — you can read image files, so review the actual pixels.

**Mechanism.** A widget test pumps the real screen, then `matchesGoldenFile` run
with `--update-goldens` *writes* the PNG:

```dart
await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
```

Driver script (e.g. `tool/shots.sh`):

```sh
flutter test test/visual --update-goldens --run-skipped --tags visual
```

These are review artifacts, not committed goldens — `shots/` is gitignored build
output.

### Faithfulness checklist

An unfaithful shot is worse than no shot: you will confidently make wrong decisions
from it, and the test run stays green either way. Every item below was a real
silent failure.

- **Load real fonts** — the app's bundled TTFs *and* the SDK's icon font from
  `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`.
  Without them `flutter_test` silently substitutes Ahem and every glyph and icon is
  a filled box: a green run producing a full set of unreadable PNGs. **Throw** on a
  missing font rather than skipping it, so the failure is loud.
- **Capture through the real app shell**, not the bare screen, so the bottom nav bar
  and any persistent chrome are present.
- **Set real safe-area insets**: `tester.view.padding = FakeViewPadding(top: 47,
  bottom: 34)` for a phone, alongside `physicalSize` and `devicePixelRatio = 1` (so
  the PNG comes out exactly WxH). A missing nav bar plus missing insets overstated
  usable height by ~19% in one case — enough to invalidate any "does this fit on a
  phone" judgement made from the shot.
- **Seed realistic data**, ideally from a real export the project already has. Empty
  states and placeholder images flatter the layout and hide the true density,
  wrapping and overflow.
- **Use the shipped default settings**, and pass overrides explicitly per capture, so
  a shot shows what a user actually sees rather than whatever the dev flags are.
- **Refuse to capture a still-loading screen** — assert that
  `find.byType(CircularProgressIndicator)` finds nothing before capturing. Settle
  helpers time out and return anyway, so a stuck spinner otherwise gets written out
  as a "successful" shot.
- **Require every capture to prove the state its name claims.** Make the finder a
  *required* parameter, so it can never be omitted and forgotten:

  ```dart
  Future<void> capture(String name, {required Finder showing}) async { … }
  ```

  Assert something that exists **only** in the named state — the open sheet's own
  title, the selection bar's exit button, the timer chips. Never
  `find.byType(TheScreen)`, which matches whether or not the interaction landed.
  This is the single highest-value assertion in the rig: a step that *throws* is
  loud, but a step that succeeds and leaves you on a different screen is silent,
  and the resulting PNG gets reviewed as if it were real. Adding this to an
  existing 100-shot rig immediately exposed a whole 5-shot family that had been
  capturing a blank screen.
- **Pin the clock.** Anything rendering a date — calendars, "today" highlights,
  agendas, relative timestamps — makes the shot a function of the day it was
  captured, so two runs differ for reasons unrelated to the code and comparing a
  shot to an earlier one is worthless. Route the screen-facing `DateTime.now()`
  calls through one overridable seam and pin it in the rig's `setUp` (with an
  `addTearDown` reset, since the override is process-global). Keep the seam narrow:
  database timestamps, log lines and notification schedules should keep the real
  clock, or a pinned test will silently write fake `created_at`s. Verify the pin by
  capturing at two different dates and diffing — every shot that changes should be
  one you can explain, and any screen still reading the system clock shows up as a
  shot that *didn't* change when it should have (or a blank one, which is how the
  5-shot family above was found).
- **Call `matchesGoldenFile` OUTSIDE any `tester.runAsync` block** — it opens its own
  `runAsync` and nesting throws "Reentrant call to runAsync() denied". Do the setup,
  pumping and interaction steps inside `runAsync`; capture after it returns.
- **Keep the rig out of the normal gate** with a test tag plus a `skip:` in
  `dart_test.yaml`; the driver passes `--run-skipped --tags visual`. The
  `@Tags(['visual'])` annotation is load-bearing — living under `test/visual/` protects
  nothing, and an untagged capture file reddens the gate on a fresh clone where the
  gitignored `shots/` dir does not exist yet.
- **Shadows are disabled** under `flutter_test` (`debugDisableShadows`), so every
  elevation renders flat. Document it once; do not chase it.

### Capture interaction states, not just first paint

Menus, bottom sheets, dialogs, multi-select, scrolled positions, dark mode — those
are where layout actually breaks. Compose small step helpers before the capture
(tap by key / by key prefix / by icon / by text, long-press, type, scroll by delta,
scroll to bottom), each followed by a settle. Two traps:

- A long-press inside `runAsync` needs a **real** held gesture
  (`startGesture` + `await Future.delayed(800ms)` + `up`), because
  `tester.longPress` relies on a fake clock that `runAsync` is not driving — it
  releases early and registers as a plain **tap**, which usually navigates instead
  of selecting.
- A single large `drag` gets **clamped** far short of its delta; loop several
  smaller drags to reach the bottom of a long list.

### Verify every shot by looking at it

Non-negotiable. In one 20-shot run, 5 shot families captured the wrong thing and all
of them were green tests: a long-press that registered as a tap and showed the
opened detail screen instead of selection mode; a settings screen frozen on a
permanent spinner because platform channels never answer under test; deep-scroll
shots clamped far short of their delta. Read every PNG and confirm it shows the
state its name claims. Then, and only then, reason about the design.

## 3. Review discipline

- **Get an independent adversarial review.** A fresh agent with no stake in the
  code, told to hunt defects and not to praise. Send findings *back* to the original
  implementer, then re-review. Three rounds is typical and every round tends to find
  something real.
- **Mutation testing.** Break each piece of wiring on purpose and confirm a test
  fails. If nothing fails, the "test" defends nothing.
- **Negative controls.** Remove the fix and confirm the regression test fails.
- **Reproduce empirically.** Build a pristine pre-fix copy (a separate `git
  worktree`, never a stash or reset in a shared tree) and observe the bug rather
  than reasoning about it.
- **Watch for fixes worse than the bug.** Real examples: a reactive rewrite made a
  firing timer silently vanish; a timeout-based lock expired while a modal dialog
  waited on the user and re-armed the exact double-insert it existed to prevent. Ask
  what the fix's own failure mode is.
- **Watch for false claims in comments and docs** — confidently-worded rationales
  that are simply untrue. A wrong "why" is worse than no comment, because the next
  reader trusts it. Verify the claim, or delete it.
- **Verify against real data** where possible. It tells you both what must change
  and what must *not*.
- **If the justification is a number, pin it in a test.** A rationale that lives
  only in a doc comment rots, and worse, is usually never checked in the first
  place. Two of my own confidently-stated figures were off by 2× and by 8× — the
  reviewer recomputed them independently and both were wrong. Put the measurement
  behind a runnable assertion, then mutation-test *that*: reintroduce the exact
  defect the number exists to prevent and confirm it goes red.
- **Fix at the root, not in the fixture.** When a test or capture goes wrong
  because production code disagrees with the harness, the tempting fix is to bend
  the fixture to match. Ask first whether production is simply wrong — a Cook tab
  reading the wall clock while the rest of the app reads an injectable one is wrong
  in the app too, not just under test, and the fixture workaround would have hidden
  it permanently.
- **A subagent's report is evidence, not verdict.** Reports arrive confident and
  are often right in substance while wrong in detail — check the load-bearing
  numbers and re-derive the key claims yourself before acting on them. Equally,
  when a review says you were wrong, verify rather than concede reflexively: it is
  as cheap to check as to argue, and it is what tells you which of the two of you
  to trust next time.
