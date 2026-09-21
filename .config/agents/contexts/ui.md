# UI/UX

Any surface a person looks at: app screens, web pages, dashboards, artifacts,
charts. Language contexts own the capture rigs; this file owns how UI
decisions get made.

## Decide from pixels

Never do UI work blind. Render the real screen and read the PNG — prose
descriptions of a layout are imagination, and imagination is where spacing,
overflow and contrast bugs hide. Each platform has a headless rig:
`flutter.md` §2, `kotlin.md` §3 (Roborazzi), `typescript.md` §3 (Playwright).
An artifact is its own rig: publish, open, look.

A **taste call** — a colour, a section prefix, an interaction model, anything
the user will pick rather than derive — gets 2–3 real rendered variants plus
a baseline shot of current behaviour, seeded with real fixture data at the
shipped device size. Send the PNGs (`SendUserFile`) and ask with
`AskUserQuestion` multi-choice, `preview` where it helps. Twice in a row this
produced immediate clean picks where prose comparisons had stalled. Temporary
hacks in production files are fine for the render; `git checkout` exactly
those files after. Before dispatching a render to a sandboxed worker, check
the rig can run there — the Codex sandbox blocks the Flutter test harness's
loopback socket, so app tests abort before the body runs (measured
2026-08-10); a same-model agent with the rig can.

## Verify in bounded passes

Build fully, inspect once with a batched round (desktop and mobile together
on the web; the shipped device classes on native), fix everything that round
shows in one batch, confirm with at most one more round, stop. Open-ended
self-QA burns money doing worse what a finishing pass does better. This is
`impeccable`'s rule and it holds without the skill loaded.

## Skills

- `impeccable` — design, critique, audit, polish, harden, and the rest of its
  command table. Load it for any request that shapes or judges an interface,
  not only when the user names it. It reads `PRODUCT.md`/`DESIGN.md` when
  present; missing ones do not make a project greenfield.
- `color-expert` — every colour choice, including "just pick something":
  OKLCH ramps so lightness is even across hues, reference → semantic tokens
  (surface, on-surface, accent, states), every text/background pair checked
  against APCA or WCAG in both light and dark. A palette chosen by eye in one
  theme is the usual source of the unreadable other theme.
- `dataviz` (Claude only) — charts, stat tiles, dashboards; read it before the
  first line of chart code.
