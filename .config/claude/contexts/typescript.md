# TypeScript/JavaScript verify loop (bun + oxlint/oxfmt)

## 1. The gate

One command (package script `check` or `tool/verify.sh`), run from the root:

```sh
mkdir -p .reports                           # reporters don't create parent dirs
bunx oxfmt --check .                        # format, no writes
bunx oxlint --type-aware --deny-warnings    # lint incl. type-aware rules
bunx tsc --noEmit                           # types — tsc stays the ground truth
bun test --coverage --randomize \
  --reporter=junit --reporter-outfile=.reports/junit.xml
```

Never add `--coverage-reporter=lcov` to the gating run — it silently disables the
coverage-threshold exit code (bun#32118); lcov upload is a separate pass.

Monorepo: derive the package list from the workspace manifest (`package.json`
`workspaces`), never hand-maintain it — a forgotten package is unverified forever,
silently. Fail loudly if the list parses to nothing.

**Strictness parity with clippy `-D warnings`:**

- oxlint: `--type-aware --deny-warnings`; categories
  `correctness`/`suspicious`/`pedantic` at `"error"`; plugins `import`,
  `typescript`, `unicorn`, `promise`, `oxc`; `import/no-cycle: "error"`.
  **No ignore-file baselines.** Disable comments are the `// ignore:` analog —
  last resort, documented reason.
- Version coupling: `oxlint-tsgolint` pins an exact TypeScript patch — upgrade
  `typescript` and `oxlint-tsgolint` together. `tsc --noEmit` is the type
  gate's ground truth, period — `oxlint --type-check` is not a replacement.
- oxfmt is pre-1.0 — **pin the exact version**. It formats JSON/JSONC/CSS/
  GraphQL too: one formatter formats the repo.
- TypeScript ≥7 — the native Go compiler now ships as the plain `typescript`
  package (~10× faster). Exception: frameworks whose tooling needs the TS6
  programmatic API (Vue/Svelte/Astro/Angular template checking) pin TS6
  side-by-side per Microsoft's documented arrangement until TS 7.1. `strict`
  defaults on; keep it explicit anyway and pin `target`/`module` explicitly
  rather than inherit new inference defaults. `baseUrl` is removed. tsconfig: `strict`, `noUncheckedIndexedAccess`,
  `exactOptionalPropertyTypes`, `noImplicitOverride`, `noImplicitReturns`,
  `noFallthroughCasesInSwitch`, `noPropertyAccessFromIndexSignature`,
  `noUnusedLocals`, `noUnusedParameters`, `verbatimModuleSyntax`,
  `erasableSyntaxOnly`. `isolatedDeclarations` only on published libraries —
  app-side it's annotation churn for zero payoff. `@ts-ignore` never;
  `@ts-expect-error` with a documented reason only.
- `any` is banned, and the type-aware `no-unsafe-*` family stays on; boundaries
  take `unknown` and narrow.
- Coverage thresholds live in `bunfig.toml` and gate **lines + functions only**
  (~0.9) — bun has no reliable statement/branch reporting (bun#7100, #5307);
  coverage is a smoke alarm, not proof.
- `bunx knip --strict` (dead code, unused deps/exports) joins the gate once its
  config is settled — clear every configuration hint before it gates anything.
  For *published* packages only, the release job adds `bunx publint --strict` and
  `bunx @arethetypeswrong/cli --pack` — meaningless for apps.
- Never run the gate after a production-only install — the gate tools are
  devDependencies and simply aren't there. If tsc errors turn mysterious right
  after adding `@types/bun`, the `@types/node` conflict (bun#15481) is the
  first suspect; scope globals with an explicit `compilerOptions.types` list.

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

- **Prefer Bun built-ins over dependencies that duplicate them**: `bun test`,
  `Bun.file`, `Bun.serve`, `bun:sqlite`, `Bun.env` — the ladder's stdlib rung.

Layout follows oxfmt's output — don't argue with the formatter.

## 2. Cadence

Narrow first, gate before commit:

```sh
bunx oxfmt --check path/to/touched/        # touched files only
bunx oxlint --type-aware path/to/touched/
bunx tsc --noEmit                          # types are whole-program anyway
bun test path/to/touched.test.ts           # touched tests only
bun run check                              # full gate, pre-commit
```

**Failures:** grep `.reports/junit.xml` via a small summarizer (test name,
assertion, first non-`node_modules` stack frame) — don't scroll console output.
JUnit is bun test's only structured test-result reporter (no JSON). A *timeout*
failure carries no stack at all — re-run that file alone. Flake lane:
`bun test --rerun-each 3 --randomize`.

Notes:

- **`mock.module()` state is process-global** and leaks across test files in one
  process — prefer injecting the dependency over reaching for `--isolate`
  (undocumented, grows memory linearly on big suites).
- **Frontend packages:** `bun test` has no layout engine (happy-dom) — use Vitest
  4 browser mode, installed by bun but **executed by Node**; the Bun-runtime path
  is where the silent-exit-0 class of bugs lives.
- **Mutation lane** (nightly, not per-commit): Stryker has no official bun
  runner — the generic `command` runner works but re-runs everything per mutant;
  run the mutation lane under Vitest if it's too slow.
- **Property-based:** fast-check works plain under `bun test`;
  `fc.configureGlobal({ seed })` for reproducible CI runs.

## 3. See the UI: headless screen capture

Web analog of the Flutter/Roborazzi rigs: render real pages headlessly to PNGs and
read them — never do UI work blind. The rig lives in **Playwright's own runner** as
a tagged project (`grep: /@capture/`) driven by `tool/shots.sh`, **out of the
normal gate**. `bun test` has no pixel path (happy-dom, no layout engine) — a
second runner for capture is the Roborazzi pattern, not a smell. Bun is package
manager/script runner only: `bunx playwright test`, **never** `bun --bun
playwright test` (hangs, zombie processes).

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
  `no-networkidle` via oxlint's alpha jsPlugins support).
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
