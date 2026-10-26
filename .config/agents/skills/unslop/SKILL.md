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

# structural layer (2026-era: layout scaffolds, rhythm, reframes, and the
# construction rules: simile-density, tricolon-density, anaphora-run, frame-rotation)
node ~/repos/textlint-rule-preset-slop-2026/bin/slop2026.js <files-or-dirs>
```

The construction rules exist because the tells moved. From Opus 5 to 5.5,
em-dashes fell 72% while over-human similes rose 112%, anaphora 35% and
tricolon 33%, and newer models rotate the word inside a frame ("landed /
struck / hit with a thud") so that no single variant trips a phrase list
(`~/notes/agent-wiki/wiki/ai-prose-tells.md`). Their thresholds are not yet
calibrated against a human corpus, so they report at warning severity
(`"severity": 1`) and don't fail the exit code. Read each warning: fix it when
it is a real tell, and leave it when the list or comparison is literal ("Linux,
macOS, and Windows"; "tools like a profiler").

Both output JSON; exit 0 clean (or warnings only), 1 findings, 2 error. If the repo's `.textlintrc`
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
   - similes and personification ("the silence pressed in", "the data tells
     us") — say the literal thing
   - lists of exactly three, and runs of sentences opening on the same word
   - fixing a flagged phrase with a synonym inside the same frame — that is
     what `frame-rotation` catches next round
4. **Rewrites never add facts.** No new names, numbers, studies, places or
   scope. A de-slop pass that rewards concrete detail invents it: a Qwen
   de-slop run turned out a fabricated university study and a coffee shop "on
   Maple Street" while its slop score fell. If a sentence needs a specific to
   stand up and the source has none, cut the sentence.
5. Rerun both linters. Loop until both exit 0, at most three rounds; then
   rewrite the remaining sentences from scratch rather than patching them again.
   Before finishing, diff the final text against the original for a phrase or
   connector that now repeats where it didn't before (", which", "so",
   one recurring verb). Repeated fixing breeds its own tic: the same Qwen run
   ended up joining sentences with ", which" 28 times as often as the base
   model.
6. False positives are wrapped, not rewritten. A factual negation ("the light is
   not red, it is amber"), a genuine domain word ("robust regression"), or
   deliberate style keeps its text and gets a scoped disable:
   ```markdown
   <!-- textlint-disable slopless/prohibited-words -->
   ...intentional text...
   <!-- textlint-enable -->
   ```
   For fiction/literary prose, spaced-em-dash-density and staccato-paragraphs
   are genre-legitimate — disable per file, don't fight them.
   For resumes, disable sentence-metronome and staccato-paragraphs: uniform,
   terse, verb-first bullets are the convention there, not a tell. The
   construction and lexical rules still apply.
7. Report: findings before → after (counts and rule IDs), what was restructured,
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
could disagree with, cut it — no linter catches empty content. Optimizing
against a detector also flattens voice: the de-slopped Qwen wrote opinion
pieces with no opinion. Check the text still does what it was for.

Personification has no reliable surface form, so no rule catches it. When the
text matters, have a different model from the one that wrote it read once for
figurative constructions only.
