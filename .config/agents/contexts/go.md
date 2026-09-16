# Go verify loop

## 1. The gate

One command (`tool/verify.sh` or a mise task), from the module root:

```sh
mkdir -p .out        # reporters don't create parent dirs
golangci-lint run    # ONE step: format check (gofumpt/gci as v2 formatters),
                     # vet (govet enable-all), staticcheck & friends
gotestsum --format pkgname --junitfile .out/junit.xml --jsonfile .out/test.jsonl -- \
  -race -shuffle=on -count=1 -fullpath -timeout 5m \
  -covermode=atomic -coverprofile=.out/cover.out -coverpkg=./... ./...
go-test-coverage --config=.testcoverage.yml
```

`-count=1` states the no-cached-results invariant mechanically (`-shuffle`
happens to defeat the cache too, but that's a side effect, not a guarantee).
`-covermode=atomic` is pinned explicitly (`-race` would flip it anyway; numbers
must not shift between lanes). Coverage thresholds live in `.testcoverage.yml`
(`threshold.file`/`package`/`total`); an `override:` entry is visible,
hand-written, reviewed debt — never auto-generated, and it only ever ratchets
*up*.

golangci-lint v2 with a `formatters:` block reports unformatted files as
ordinary issues and exits 1 — no separate gofumpt or `go vet` step.
`golangci-lint fmt` (no `--diff`) is the developer's *fix* command, not a gate
step.

Multi-module repo: neither `golangci-lint run` **nor `go test ./...`** works
from a `go.work` root without a root module (verified: `pattern ./...:
directory prefix . does not contain modules listed in go.work`). golangci's
failure mode is the worse trap: it prints `0 issues` while exiting 7 — gate on
`$?`, never on output. Fan the *whole gate* out per module, deriving the list
from the workspace (never hand-maintained — a forgotten module is unverified
forever, silently; fail loudly if it parses to nothing):

```sh
ROOT=$PWD
for m in $(go work edit -json | jq -r '.Use[].DiskPath'); do
  (cd "$m" && golangci-lint run --config "$ROOT/.golangci.yml" --path-mode=abs ./...) || exit 1
done
```

Per-module coverage profiles merge via go-test-coverage's comma-separated
`profile:` list. Only `golangci-lint fmt` is file-based and workspace-safe.

**Strictness parity with clippy `-D warnings`:**

- **Baselines wear four costumes in Go — ban all of them:** `--new-from-rev`
  (diff-only linting), `linters.default: all` (each release silently adds
  linters, so a green repo goes red on upgrade — curate the enable list
  instead), issue truncation (`max-issues-per-linter: 0`,
  `max-same-issues: 0` — truncation is a silent baseline), and a floating
  golangci-lint version (a version range is a baseline in a hat; pin exactly).
- Enable list: `default: standard` plus a curated set — `errorlint`,
  `exhaustive`, `gocritic`, `revive`, `unparam`, `copyloopvar`, `modernize`,
  `nilerr`, `bodyclose`, `noctx`, `gochecksumtype`, `musttag`, `usetesting`,
  `nolintlint`. The repo's `.golangci.yml` is the authoritative full list; the
  maratori "golden config" is the reference to consult when extending it and,
  equally, for what *not* to enable (`wrapcheck`,
  `contextcheck`, `varnamelen`, `err113` etc. are documented FP-heavy — they
  drive blanket `//nolint`, defeating the whole contract).
- revive gotcha: `enable-default-rules: true` fires `exported` and
  `package-comments` on every undocumented exported symbol — adopt mandatory
  doc comments as policy or disable those two rules *deliberately*.
- `nolintlint` settings, exactly: `allow-unused: false`,
  `require-explanation: true`, `require-specific: true` — every `//nolint`
  names its linter, carries a reason, and errors if it suppresses nothing. The
  machine-checked `// ignore:` analog, strictly stronger than Rust's
  `#[allow]`.
- errcheck: `check-type-assertions: true`, `check-blank: true`, no exclude
  lists; an intentionally dropped error is a visible `_ =` at the call site,
  not a config entry.
- Exclusions: `generated: strict` (not `lax`) and `warn-unused: true` — an
  exclusion that stops matching is itself an error.
- **Not in the gate:** `govulncheck` runs nightly, not per-commit — the vuln DB
  mutates independently of the repo, so an unchanged commit can flip red,
  breaking reproducibility. NilAway (untagged, custom-binary build, active FP
  warning), `deadcode` (whole-program from `main`; wrong shape for libraries),
  and `betteralign`/govet-`fieldalignment` (layout churn) stay out entirely.
- Tool pinning: gate tools via `mise.toml` (golangci-lint as a pinned binary);
  go-run-able analyzers via the go.mod `tool` directive (Go 1.24+), not a
  `tools.go` blank-import file.
- `exhaustive` on `switch` over enum-style types, no `default` escape — adding a
  value must go red (the sealed-`when` parallel).
- Test-focused linters: `paralleltest`, `tparallel`, `thelper`, `usetesting`
  (supersedes the deprecated `tenv`), `copyloopvar`, `testpackage`;
  `testifylint` only where testify already exists.

**Named idioms** (only what the linters can't check — don't restate lint rules):

Go:

- **Happy path left-aligned** — guard clauses and early returns; `else` is
  usually a smell. ("Line of sight" coding.)
- **Accept interfaces, return structs** — and define the interface at the
  consumer, not next to the implementation.
- **Small interfaces**: "the bigger the interface, the weaker the abstraction" —
  one- and two-method interfaces compose (`io.Reader` model).
- **Make the zero value useful** — a struct should work without a constructor
  when possible (`sync.Mutex`, `bytes.Buffer` model).
- **Errors are values**: wrap with `fmt.Errorf("…: %w", err)`, branch with
  `errors.Is`/`errors.As`; sentinel errors only for conditions callers must
  branch on.
- **Don't panic** in library code — return errors; panic is for unrecoverable
  programmer errors only.
- **Functional options** for constructors with many optional knobs; a plain
  config struct when they're few. Never a boolean parameter list.
- **Composition via embedding**, never pseudo-inheritance.
- **Context flows down**: first parameter, threaded through, never stored in a
  struct field.
- **"A little copying is better than a little dependency."**
- **Channels orchestrate; mutexes serialize** — channels for ownership transfer
  and pipelines, `sync.Mutex` for simple shared state; neither is the default.
- **`errgroup`** for concurrent fan-out with error propagation and cancellation
  over hand-rolled WaitGroup + error channel.

Testing:

- **No assertion libraries** (Google style, by name: "use Go itself") — plain
  `if got != want` with `got`/`want` variable names, **`go-cmp`**
  (`cmp.Diff`) for structured values. go-cmp is test-only: comparing structs
  with unexported fields panics without explicit options — keep it out of
  non-test code. In a repo that already has testify, keep it and gate with
  `testifylint` — never migrate for its own sake.
- **Table-driven tests + `t.Run` subtests**; `t.Parallel()` where safe — but
  `t.Setenv`/`t.Chdir` panic under a parallel *ancestor*, not just a parallel
  test.
- **`t.Cleanup` in helpers** — a `defer` there fires when the *helper*
  returns, not when the test ends.
- **Golden files** under `testdata/` with a hand-rolled `-update` flag (four
  lines; no goldie/autogold dependency); **`txtar`** for multi-file cases;
  `-update` output is reviewed in the diff, never blessed reflexively.
- **testscript** (rogpeppe/go-internal) for CLI integration tests — coverage
  attribution works through it, unlike exec-ing a built binary.
- **Native fuzzing** for parsers/codecs (byte-shaped inputs); **rapid** for
  structured/stateful properties — rapid checks run in the normal suite (it
  persists its own minimized failures), fuzz runs in a budgeted nightly lane.
  **Commit `testdata/fuzz/`** — crashers land there and become plain
  regression tests.
- **`testing/synctest`** for time-dependent code — kills sleep-based flakes.

The **Google Go Style Guide** is the naming/layout authority when the linters
are silent; **Go Proverbs** supplies the idiom names above.

## 2. Cadence

Narrow first, gate before commit:

```sh
golangci-lint fmt path/to/touched/               # fix formatting
golangci-lint run ./pkg/touched/...              # touched package only
go test -json -race -fullpath -timeout 60s ./pkg/touched/...  # cache-warm
tool/verify.sh                                   # full gate, pre-commit
```

Every narrow-loop flag is in go's cacheable set (`-json` replays cached results;
`-race` is cacheable as a separate binary) — unchanged packages return
instantly. **Never** put `-shuffle`, `-count=1`, or coverage in the narrow loop;
they belong to the gate.

**Failures:** a ~50-line summarizer over the test2json JSONL (streaming
`TestEvent` decode): test name, first `_test.go:NN:` output line (absolute via
`-fullpath`), first in-module stack frame for panics/races. Build failures ride
the same stream since Go 1.24 — one parser covers both. JUnit XML is for CI
dashboards only.

**Nightly lanes:**

- Flake hunt: `-race -shuffle=on -count=5`; the shuffle seed is reported —
  reproduce with `-shuffle=<seed>`.
- Fuzz: `-fuzz` matches exactly one test in one package, so loop over targets
  with `-fuzztime` budgets; persist `$GOCACHE/fuzz`; new crashers in
  `testdata/fuzz/**` get committed or they die with the runner.
- Mutation: gremlins, advisory first (`--threshold-efficacy 0`), gate on
  efficacy only after a few weeks of observation — it's 0.x and slow on big
  modules.

## 3. Shared discipline

- **Never buy gate speed with gate coverage.** Hash-stamps and skip-lanes stop
  checking files that can break the build while still reading green — strictly
  worse than no change. Ask what a speed-up stops checking; measure claimed
  numbers yourself.
- **Flake vs regression:** re-run the failing test alone. Passes alone, fails
  under full-suite load = load flake — say so; don't "fix" the test and destroy
  its signal.
- **A test asserting a default you changed** gets updated to pin the NEW value —
  never loosened or deleted.
- **Review goes cross-model:** hand the diff to Codex (`codex:codex-rescue`), told
  to hunt defects and not praise. Findings back to the implementer; re-review only
  what changed. A same-family reviewer mostly confirms — leaving the family is the
  point. Plans get the same treatment via the `plan-refute` skill.
- **Mutation testing** (break wiring, confirm red) and **negative controls**
  (remove the fix, confirm the regression test fails).
- **Reproduce empirically** in a separate `git worktree` — never stash/reset in
  a shared tree.
- **A load-bearing number lives in a runnable assertion**, not a doc comment;
  then mutation-test the assertion.
- **Fix at the root, not the fixture:** when production disagrees with the
  harness, first ask whether production is simply wrong.
- **A subagent's report is evidence, not verdict** — re-derive key claims before
  acting; when a review says you're wrong, verify rather than concede
  reflexively.
