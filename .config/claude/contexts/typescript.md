# TypeScript/JavaScript verify loop (bun + oxlint/oxfmt)

## 1. The gate

One command (package script `check` or `tool/verify.sh`), run from the root:

```sh
mkdir -p .reports                           # reporters don't create parent dirs
bunx oxfmt --check .                        # format, no writes
bunx oxlint --type-aware --deny-warnings    # lint incl. type-aware rules
bunx tsc --noEmit                           # types — tsc stays the ground truth
bun test --parallel --only-failures --no-env-file --coverage --randomize \
  --reporter=junit --reporter-outfile=.reports/junit.xml
```

`--parallel` (≥1.3.13, stabilized in 1.4) implies `--isolate`: fresh
`globalThis` + module registry per file, coverage and JUnit merged across
workers, `JEST_WORKER_ID` set per worker. Trade-off: `--isolate` hides "passes
alone, fails in suite" cross-file-leak signals — when hunting one, re-run
single-process `bun test --no-isolate --randomize`. Switch the gate back to
that if parallel proves flaky. `--only-failures` mutes passing/skipped console
output (JUnit stays complete); `--no-env-file` keeps a dev's stray `.env` out
of the gate — suite env is an explicit `--env-file=.env.test`.

CI fan-out: `bun test --parallel --shard=i/N --timings=timings.json` (record
with `--update-timings`, ≥1.4) — coverage-neutral, unlike a skip-lane. The
timings file is written slowest-first: it doubles as the slow-test report.

Never add `--coverage-reporter=lcov` to the gating run — it silently disables the
coverage-threshold exit code (bun#32118); lcov upload is a separate pass.

Monorepo: derive the package list from the workspace manifest (`package.json`
`workspaces`), never hand-maintain it — a forgotten package is unverified forever,
silently. Fail loudly if the list parses to nothing. Fan out with
`bun run --parallel --filter '*' check` (dependency-aware: `--filter 'pkg...'`
= pkg + its deps, `'...pkg'` = its dependents); `bun test --pass-with-no-tests`
keeps empty packages from failing the sweep while the parses-to-nothing check
still catches the real hazard. `--no-exit-on-error` runs every package and
still exits non-zero overall (verified on 1.4.0) — safe in a gate.

**Strictness parity with clippy `-D warnings`:**

- oxlint: `--type-aware --deny-warnings`; categories
  `correctness`/`suspicious`/`pedantic` at `"error"`; plugins `import`,
  `typescript`, `unicorn`, `promise`, `oxc`; `import/no-cycle: "error"`.
  **No ignore-file baselines.** Disable comments are the `// ignore:` analog —
  last resort, documented reason.
- Version coupling: `oxlint-tsgolint` pins an exact TypeScript patch — upgrade
  `typescript` and `oxlint-tsgolint` together. `tsc --noEmit` is the type
  gate's ground truth, period — `oxlint --type-check` is not a replacement.
- oxfmt is pre-1.0 — **pin the exact version** (watch:
  `~/.config/claude/watches/oxfmt.sh`). It formats JSON/JSONC/CSS/
  GraphQL too: one formatter formats the repo.
- TypeScript ≥7 — the native Go compiler now ships as the plain `typescript`
  package (~10× faster). Exception: frameworks whose tooling needs the TS6
  programmatic API (Vue/Svelte/Astro/Angular template checking) pin TS6
  side-by-side per Microsoft's documented arrangement until TS 7.1 (watch:
  `~/.config/claude/watches/typescript7.sh`). `strict`
  defaults on; keep it explicit anyway and pin `target`/`module` explicitly
  rather than inherit new inference defaults. `baseUrl` is removed. tsconfig: `strict`, `noUncheckedIndexedAccess`,
  `exactOptionalPropertyTypes`, `noImplicitOverride`, `noImplicitReturns`,
  `noFallthroughCasesInSwitch`, `noPropertyAccessFromIndexSignature`,
  `noUnusedLocals`, `noUnusedParameters`, `verbatimModuleSyntax`,
  `erasableSyntaxOnly`. `isolatedDeclarations` only on published libraries —
  app-side it's annotation churn for zero payoff. `@ts-ignore` never;
  `@ts-expect-error` with a documented reason only. Since bun 1.4 the runtime
  honors `useDefineForClassFields: false` (previously ignored — class-field
  emit changes) and `"jsx": "react-jsx"` selects the **production** runtime
  (`jsx`/`jsxs`, not `jsxDEV`) — a test relying on React dev warnings needs
  `"jsx": "react-jsxdev"` explicitly.
- `any` is banned, and the type-aware `no-unsafe-*` family stays on; boundaries
  take `unknown` and narrow.
- Coverage thresholds live in `bunfig.toml` and gate **lines + functions only**
  (~0.9) — bun has no reliable statement/branch reporting (bun#7100, #5307;
  watch: `~/.config/claude/watches/bun-coverage.sh`, also covers the lcov
  trap above); coverage is a smoke alarm, not proof.
- `bunx knip --strict` (dead code, unused deps/exports) joins the gate once its
  config is settled — clear every configuration hint before it gates anything.
  For *published* packages only, the release job adds `bunx publint --strict` and
  `bunx @arethetypeswrong/cli --pack` — meaningless for apps.
- Never run the gate after a production-only install — the gate tools are
  devDependencies and simply aren't there. If tsc errors turn mysterious right
  after adding `@types/bun`, the `@types/node` conflict (bun#15481) is the
  first suspect; scope globals with an explicit `compilerOptions.types` list
  (1.4 ships `@types/bun` against `@types/node@25` — remaining conflicts are
  version skew from a dep pinning older).
- Lockfile/deps hygiene (bun ≥1.4): `bun dedupe --check` in CI fails on
  duplicate versions; `bun audit fix` for vulns; `bun prune --production`
  after build in deploy images. Pin `linker = "isolated"` **plus**
  `hoist = false` — isolated alone still resolves undeclared deps through the
  hidden `node_modules/.bun/node_modules` fallback; `hoist = false` (≥1.4)
  turns a phantom dependency into `MODULE_NOT_FOUND`, which is the point.
- Before accepting a non-patch dependency bump, `bun pm diff <pkg>` (≥1.4) —
  it names new install scripts and new `child_process`/`fs`/`net`/`vm` imports
  before the diff (minified files un-minified). Packages whose postinstall you
  don't need go in `ignoreScripts`; prebuilt-binary packages in
  `nativeDependencies` so no script runs at all. `bun pm ls --trusted` lists
  what may run scripts.
- bunfig.toml is strictly parsed since 1.4 — every string value quoted
  (`linker = "isolated"`, not `linker = isolated`) or Bun fails at startup
  with a TOML parse error before anything runs.

A baseline/ignore file is gate-rot's special case: it converts today's entire debt
into permanently invisible passes. Never generate one to get green.

**Named idioms** (only what oxlint/tsc can't check — don't restate their rules):

TypeScript:

- **Guard clauses / early return** over nested `if` pyramids.
- **Discriminated unions + exhaustive `switch`** for state modeling
  (loading/error/data) — make illegal states unrepresentable; no status-string +
  nullable-fields combos. Close the switch with an `assertNever(x: never)` default
  so adding a variant is a compile error.
- **Parse, don't validate** — schema-parse (`zod`/`valibot`) at trust boundaries
  (API responses, env, user input); everything inward trusts the types.
- **Derive types from values**: `as const` + `typeof`/`keyof` over hand-written
  parallel types that can drift.
- **`satisfies`** to check a value against a type while keeping its inferred
  (narrower) type.
- **Union of literals over `enum`** (`erasableSyntaxOnly` bans enums anyway; the
  idiom is what to write instead: `as const` object + derived union).
- **Readonly by default**: `readonly` fields, `ReadonlyArray`/`readonly T[]` on
  public signatures; return new values over mutating arguments.

Async (floating/misused promises are gated by the type-aware rules; these are
the rest):

- **Parallelize independent awaits** with `Promise.all`; sequential `await` in a
  loop is a decision, not a default.
- **`AbortSignal` plumbing** for cancellable work — accept a signal, pass it down.

Bun:

- **Default to Bun built-ins — a dependency duplicating one needs a stated
  reason** (a contract the builtin can't meet, e.g. Playwright's determinism
  layer over `Bun.WebView`): `bun test`, `Bun.file`, `Bun.serve`,
  `bun:sqlite`, `Bun.env` — the ladder's stdlib rung. Dep → builtin triggers
  (bun 1.3–1.4): npm-run-all/concurrently→`bun run --parallel`,
  node-cron→`Bun.cron`, sharp→`Bun.Image`, node-tar→`Bun.Archive`,
  path-to-regexp→`URLPattern`, express.static/sirv→`Bun.serve` `{ dir }`
  routes, node-pty→`Bun.Terminal`, Puppeteer→`Bun.WebView` (capture rig
  excepted, §3), string-width/slice-ansi/wrap-ansi and
  markdown/JSON5/XML/TOML/JSONL/JSONC parsers→`Bun.*` namesakes, zlib stream
  wrappers→`CompressionStream`, Babel react-compiler and
  babel-plugin-import→bundler `reactCompiler`/`optimizeImports`.

Layout follows oxfmt's output — don't argue with the formatter.

## 2. Cadence

Narrow first, gate before commit:

```sh
bunx oxfmt --check path/to/touched/        # touched files only
bunx oxlint --type-aware path/to/touched/
bunx tsc --noEmit                          # types are whole-program anyway
bun test --changed                         # tests reached by the diff (≥1.3.13)
bun run check                              # full gate, pre-commit
```

`--changed[=ref]` walks the import graph backward from the git diff (tsconfig
paths work) — strictly better than hand-picking touched test files, which
misses tests that import what you edited.

**Failures:** grep `.reports/junit.xml` via a small summarizer (test name,
assertion, first non-`node_modules` stack frame) — don't scroll console output.
JUnit is bun test's only structured test-result reporter (no JSON). A *timeout*
failure carries no stack at all — re-run that file alone. Flake lane:
`bun test --rerun-each 3 --randomize`. `--retry`/`{ retry: n }` never gates —
it converts flakes to green instead of surfacing them.

**Slow or leaky, not failing:** `bun --cpu-prof-md` and `bun --heap-prof-md`
write grep-able Markdown (hot functions by self time, top types by retained
size, retention chains) — read those, never a raw
`.cpuprofile`/`.heapsnapshot`. `BUN_CPU_PROFILE=1` profiles a process you
can't pass flags to (a `--parallel` test worker). `bun build --metafile-md`
answers "why is the bundle big". Since 1.3.12 errors from
`fs.promises`/`fetch`/S3/DNS/crypto carry an async stack pointing at your
`await`.

Notes:

- **`mock.module()` state is process-global** under `--no-isolate`; the gate's
  `--parallel`/`--isolate` (documented + stabilized in 1.4) gives each file a
  fresh global. Still prefer injecting the dependency — isolation hides the
  coupling, injection removes it. An unavoidable spy goes in a `using` binding
  (`using spy = spyOn(obj, "m")` restores on scope exit, ≥1.3.9); per-test
  cleanup goes in `onTestFinished()` (runs after every `afterEach`). Neither
  depends on `--isolate` doing the cleanup for you.
- **Frontend packages:** `bun test` has no layout engine (happy-dom) — use
  Vitest 4 browser mode. Since bun 1.4, vitest (incl. `--coverage`) runs under
  Bun, so bun-run is fine; if a suite exits 0 suspiciously fast or short,
  fall back to Node execution — that's where the silent-exit-0 class lived.
- **Mutation lane** (nightly, not per-commit): Stryker has no official bun
  runner — the generic `command` runner works but re-runs everything per mutant;
  run the mutation lane under Vitest if it's too slow (watch:
  `~/.config/claude/watches/stryker-bun.sh`).
- **Property-based:** fast-check works plain under `bun test`;
  `fc.configureGlobal({ seed })` for reproducible CI runs.

**Upgrading a repo to bun 1.4** — assertion semantics changed; a new failure is
the runtime telling the truth for the first time. Pin the new value, never
loosen:

- `jest.resetAllMocks()` now drops implementations too (Jest parity) —
  `clearAllMocks()` for history-only.
- `toContain()` compares `===` (`[NaN]` no longer contains `NaN`; `toBe` stays
  `Object.is`); `expect.any(Object)` matches `null`, rejects functions.
- `Temporal` is defined by default, and `toEqual` compares Temporal by value —
  old green was vacuous (any two same-class instances compared equal).
- `assert.deepStrictEqual` compares prototypes; `fs.rmdir({recursive})` throws
  (cleanup uses `fs.rm({recursive, force})`).
- `Request`/`Response.clone()` throws after the body is read — clone first;
  `fetch()` network errors are `TypeError`; duplicate response headers join
  with `", "` (was last-wins).
- TLS defaults tightened: missing `servername` fails cert identity against
  `host` (`ERR_TLS_CERT_ALTNAME_INVALID`, transitively via pg/ioredis), and
  `Bun.connect`/`upgradeTLS` default `rejectUnauthorized: true` — failing
  *quietly* (`socket.authorized === false`, empty reads, close). Triage as
  config, not flake; fix is `servername`/`tls.ca`, not
  `rejectUnauthorized: false`.
## 3. See the UI: headless screen capture

Web analog of the Flutter/Roborazzi rigs: render real pages headlessly to PNGs and
read them — never do UI work blind. The rig lives in **Playwright's own runner** as
a tagged project (`grep: /@capture/`) driven by `tool/shots.sh`, **out of the
normal gate**. `bun test` reaches pixels only through `Bun.WebView` (below),
which can't yet meet the determinism contract — a second runner for capture is
the Roborazzi pattern, not a smell. Since bun 1.4 Playwright runs under Bun,
so `bun --bun playwright test` is allowed; on hangs or zombie processes (the
pre-1.4 failure mode) fall back to `bunx playwright test` (Node execution).
Under `--bun`, Bun behaves as node and does **not** auto-load `.env` (1.4) —
pass `--env-file` explicitly.

**`Bun.WebView`** (built-in headless browser, ≥1.3.12, **experimental**) is
the default for everything *below* the rig — one-off screenshots, DOM poking,
smoke checks — anywhere an agent would otherwise install Puppeteer. Its
`.cdp()` hatch reaches the determinism knobs (`Emulation.setEmulatedMedia`
for colorScheme/reducedMotion, `setTimezoneOverride`, `setLocaleOverride`,
`setDeviceMetricsOverride` for DPR, `Accessibility.getFullAXTree`), and
`backend: { type: "chrome", path, argv }` pins binary + flags. Not the
capture rig: defaults inherit the host, no clock pinning, no
`animations: 'disabled'`, no assertion layer, API unstable — before
re-litigating, run `~/.config/claude/watches/webview.sh` (one line: NOT-READY
/ CHECK); investigate only on CHECK.

- Raw `page.screenshot()`, no `toHaveScreenshot`/committed goldens — shots are
  gitignored review artifacts. Trap: `page.screenshot()` defaults `animations:
  'allow'` (only `toHaveScreenshot` disables) — pass `animations: 'disabled'` and
  `caret: 'hide'` explicitly.
- **Determinism lives in context options, not env vars** — `colorScheme`,
  `reducedMotion: 'reduce'`, `locale: 'en-US'`, `timezoneId: 'UTC'`, device
  profile viewport + DPR; never inherit the host OS. Dark/light explicit per shot.
- Cross-machine pixel stability: pin the capture environment (the Playwright
  container image) first, then the known Chromium args —
  `--font-render-hinting=none --disable-font-subpixel-positioning
  --disable-lcd-text --force-color-profile=srgb --disable-skia-runtime-opts
  --use-gl=swiftshader`. They trade GPU fidelity for determinism; that's the
  point.
- **Every capture proves the state its name claims** — `expect(proof).toBeVisible()`
  on something that exists *only* in that state, **plus**
  `expect(loadingLocator).toHaveCount(0)` — refuse to capture loading.
  `toMatchAriaSnapshot` is a stronger whole-tree proof, and it's cheap text an
  agent reads next to the PNG.
- **`networkidle` is banned** — officially discouraged; fires too early on slow
  single calls, never on websockets/long-polling. No stable oxlint rule covers
  this — enforce in review (optional: `eslint-plugin-playwright`'s
  `no-networkidle` via oxlint's alpha jsPlugins support; watch:
  `~/.config/claude/watches/oxlint-jsplugins.sh`).
- **Fonts:** `await page.evaluate(() => document.fonts.ready)` before the shot;
  never set `PW_TEST_SCREENSHOT_NO_FONTS_READY`. CI images need real fonts
  (`fonts-noto-core/-cjk/-color-emoji` + `fc-cache`) — the Playwright image ships
  Latin-only, so CJK/emoji render as tofu, silently green.
- **Pin the clock:** `page.clock.install({time})` *before* `goto`, `pauseAt` after
  navigation, resume after the shot. `animations: 'disabled'` covers only
  CSS/Web-Animations — canvas/video/rAF motion needs the paused clock and an
  app-level RNG seed.
- **Safe-area insets are not emulated** (`env()` resolves to 0): inject CSS vars
  via `addInitScript`, CSS reads `var(--sat, env(safe-area-inset-top))`.
- Scrollbars don't paint in Chromium headless screenshots — content renders
  wider than a real desktop user sees; prefer viewport captures over `fullPage`
  (whose headless software raster also silently truncates very tall pages).
- **`webServer` takes its own port and never reuses.** `command: 'bun run build &&
  PORT=3100 bun run start'`, with `webServer.url` *and* `use.baseURL` both on 3100 —
  moving one and not the other reads as a broken app. `reuseExistingServer: false`:
  the command contains the build, so reuse skips it and shoots the previous build.
  Playwright kills the spawned shell, not the server under it — run the command
  under `bun run --no-orphans` (or `[run] noOrphans = true` in bunfig, ≥1.3.14):
  Bun SIGKILLs the whole descendant tree on exit. `tool/shots.sh` still frees
  the port first as belt-and-braces against `EADDRINUSE`.
- Seed realistic data — empty states flatter the layout. Read **every** PNG and
  confirm it shows what its name claims — green runs still capture the wrong
  thing.
- Component-level capture, if ever needed: Playwright ≥1.62's story-gallery model —
  `experimental-ct-*` and Storybook test-runner are both superseded/removed.

## 4. Shared discipline

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
- **Reproduce empirically** in a separate `git worktree` — never stash/reset in a
  shared tree.
- **A load-bearing number lives in a runnable assertion**, not a doc comment; then
  mutation-test the assertion.
- **Fix at the root, not the fixture:** when production disagrees with the
  harness, first ask whether production is simply wrong.
- **A subagent's report is evidence, not verdict** — re-derive key claims before
  acting; when a review says you're wrong, verify rather than concede reflexively.
