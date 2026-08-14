# End-to-end tests

E2E runs the real thing — real browser, device, binary, backing services. The most
expensive signal you have and the easiest to corrupt; it earns its place per test,
never per layer.

- Pick the smallest scope that still crosses the seam you doubt. Flake rate rises
  with test size, and there's no evidence bigger tests catch more defects.
- Two lanes: a deterministic mocked lane gates commits; a small real-dependency lane
  on a schedule catches the contract drift the mocks hide.
- Cut before you add. Halving a flaky suite buys more than any retry policy.

## Under an agent

The suite is the agent's only sensor.

- **Both directions or it isn't green:** the test failed before the fix, and nothing
  previously passing regressed. The anti-regression half is what catches "made it
  pass by breaking something else".
- **Report failures one at a time, with expected *and* actual value.** An assertion
  message that omits what was actually computed is the hardest kind to repair. Run
  the whole suite — this is presentation, not fail-fast. Prose is fine; keyed JSON
  isn't better.
- **A retry buys complete results, not tolerance.** It stops one flake masking
  everything behind it, and then the run still fails (`--fail-on-flaky-tests`): a
  newly-flaky test is a real bug about 1 in 6 times. Quarantine needs an owner and
  an expiry date, or it's deletion with extra steps.
- **Judge the pixels, not the narration.** A deliberate capture, asserted against the
  state it claims, can gate. The agent's own account of what it did cannot.
- **Agent-written tests earn their place through a filter:** compiles → passes N× →
  fails when the fix is reverted. Coverage and mutation score only track real
  defect-detection when the code under test is assumed correct — not the agent's
  situation.
- **Affected-only selection speeds the loop, never the gate.** >95% recall is not
  100%, and the language files' coverage rule is absolute: full suite before merge.
- **Read the trace first** — DOM snapshots plus network, higher-yield per token than
  any image. A failure screenshot *is* admissible once you crop in and confirm what
  it shows; reading it is cheaper than another round of reasoning. Video is human
  triage.

## Per ecosystem

**TypeScript/bun — Playwright** (the capture rig's sibling runner, in the gate this
time; `bun test` has no browser driver):

```sh
PLAYWRIGHT_JUNIT_OUTPUT_FILE=.reports/e2e.xml \
  bunx playwright test --project=e2e --reporter=junit --fail-on-flaky-tests
```

`use: { trace: 'on-first-retry', screenshot: 'only-on-failure' }`. Determinism:
`page.clock.install()` *before* `goto`, `page.routeFromHAR(h, {update:false})` for
third-party calls, per-test seeded data the test creates and tears down — shared
golden data is the top source of order-dependent flake. `networkidle` stays banned.
`--only-changed=origin/main` and `--last-failed` tighten the loop (not the gate).

**Python — pytest + pytest-playwright** (no first-party E2E; E2E-ness is entirely
third-party plugins):

```sh
uv run pytest tests/e2e --junit-xml=.reports/e2e.xml \
  --tracing=retain-on-failure --screenshot=only-on-failure --output=.reports/e2e
```

**pytest has no built-in retry** — `pytest-rerunfailures` (`--reruns`) if you want
one, and then the counting rule above applies. `-n auto` (xdist) for parallelism.

**Kotlin/Android — AndroidX instrumented tests.** Prefer build-managed devices so CI
provisions and tears down the emulator itself; on a GPU-less runner you must pass
`-Pandroid.testoptions.manageddevices.emulator.gpu=swiftshader_indirect` or it hangs.

```sh
./gradlew --console=plain -q <deviceName><Variant>AndroidTest
```

Results in `<module>/build/outputs/androidTest-results/connected/`. No built-in
retry (the Gradle test-retry plugin covers JVM tests only); Espresso/Compose idling
resources are the auto-wait analogue. Needs SDK + system image + KVM.

**Flutter — `integration_test`** (first-party, in-SDK):

```sh
flutter test integration_test -d <device> --file-reporter json:build/e2e.json
```

Three sharp edges: **no auto-wait** (you call `pumpAndSettle()` yourself), **no
retries**, and **no automatic artifacts** — screenshots need
`IntegrationTestWidgetsFlutterBinding.takeScreenshot()` wired by hand plus a driver
script. Reach for **patrol** only when the flow must touch native UI (permission
dialogs, notifications, platform views).

## Where there is no E2E story

**Go, Rust, and generic CLI/server projects have no E2E convention. Do not invent
one, and do not add a rule pretending otherwise.** What exists is the ordinary test
command pointed at a real binary or real dependency, and it belongs in the
language's own gate, not a separate tier:

- Go: `go test` with a build tag, plus testcontainers-go (needs a Docker-compatible
  runtime).
- Rust: `assert_cmd`/`trycmd` driving the built binary under `cargo nextest`
  (`--flaky-result fail` with `--retries`, 0.9.131+, is the counting rule above).
- Shell: `bats -r tests/`, if the surface genuinely is shell.
