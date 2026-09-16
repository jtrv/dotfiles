---
name: unslop
description: Use when asked to de-slop, unslop, humanize, or make prose read less AI-generated, when Markdown docs, READMEs, blog posts, or announcements read machine-written, or before publishing agent-written prose.
---

# Unslop

De-slop Markdown prose against two deterministic linters. The linters are the
verdict — not your own reading. You cannot judge the result by eye because **your
default writing style is the thing the structural linter detects.**

## The two layers

```bash
# lexical layer (2023-era vocabulary, phrases, cliches)
npx -y slopless <files-or-globs>

# structural layer (2026-era: layout scaffolds, rhythm, reframes)
node ~/repos/textlint-rule-preset-slop-2026/bin/slop2026.js <files-or-dirs>
```

Both output JSON; exit 0 clean, 1 findings, 2 error. If the repo's `.textlintrc`
already includes `preset-slopless` and `preset-slop-2026`, run
`bunx textlint <files>` instead — one command, both layers.

## Workflow

1. Run both linters on the target files BEFORE editing. Save the JSON.
2. Rewrite each finding by **restructuring, not synonym-swapping**. Swapping
   "delve" for "dig into" passes the lexer while the text stays slop; say
   something concrete instead, or delete the sentence.
3. While fixing, do not introduce your own habitual patterns. These are the
   exact tells the structural layer flags:
   - bold-label bullets (`**Speed:** ...`, `**Fast** — ...`) — write prose lists
   - spaced em-dash asides (` — `) — use commas, colons, or separate sentences
   - "isn't X, it's Y" / "not X — it's Y" reframes — state the point directly
   - one-line dramatic paragraphs and uniform sentence lengths — vary rhythm
   - "Here's the thing", "Short answer:", "## Bottom line" scaffolds
4. Rerun both linters. Loop until both exit 0.
5. False positives are wrapped, not rewritten. A factual negation ("the light is
   not red, it is amber"), a genuine domain word ("robust regression"), or
   deliberate style keeps its text and gets a scoped disable:
   ```markdown
   <!-- textlint-disable slopless/prohibited-words -->
   ...intentional text...
   <!-- textlint-enable -->
   ```
   For fiction/literary prose, spaced-em-dash-density and staccato-paragraphs
   are genre-legitimate — disable per file, don't fight them.
6. Report: findings before → after (counts and rule IDs), what was restructured,
   what was disabled and why.

## Red flags — you are about to fail

- "Verified by grepping for slop words" — that's the baseline failure this
  skill exists to prevent. Run the linters.
- "It reads human to me now" — your eye is the instrument being tested.
- "No linter is available here" — both commands above work from any directory.
- Finishing while either linter still exits 1 with no disable-comment
  justification.

## Limits

Passing both linters removes known irritants; it does not guarantee substance.
After the loop, reread once for vacuity: if a sentence says nothing a reader
could disagree with, cut it — no linter catches empty content.
