---
name: html-report
description: Generate a polished, self-contained single-file HTML report with an editorial look (Tailwind via CDN, optional Mermaid diagrams, card-based sections, badge rows, sparse prose). Use this whenever the user asks for "a report", "an html report", "a visual summary", "a review document", "a writeup I can open in a browser", or wants findings/results/inventories/comparisons presented as a document rather than chat text — even if they don't say "HTML". Covers audit results, migration status, package inventories, benchmark summaries, incident reviews, decision records.
---

# HTML Report

One self-contained `.html` file. Tailwind and (only if diagrams are needed) Mermaid from CDNs; no other scripts, no interactivity. The file must render offline-ish (CDN-only deps) and survive being emailed or committed.

Ask where to save only if no location is implied; default to a `reports/` dir next to the work, else the OS temp dir. Open it for the user afterwards when a display exists: use `$BROWSER "$file"` if `$BROWSER` is set, else fall back to `xdg-open` / `open`.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{{Report title}} — {{subject}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- only when a diagram earns its place: -->
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>/* small custom layer only for what Tailwind can't do cleanly */</style>
    <!-- for reports that will be shared or kept: pin exact versions on jsdelivr and add
         integrity="sha384-..." crossorigin="anonymous" (cdn.tailwindcss.com is mutable and
         can't be pinned - use https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4 instead).
         Throwaway local reports may skip SRI. -->

  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section class="space-y-10"><!-- item cards --></section>
      <section><!-- summary / verdict --></section>
    </main>
  </body>
</html>
```

## Structure

**Header** — title, subject, date, and a compact legend explaining the badge colors you chose. No introduction paragraph — straight into the content.

**Item cards** — one `<article>` per finding/item/candidate:

- **Title** — short, active, names the thing (not "Item 3").
- **Badge row** — 2–4 semantic states mapped to colors: emerald = good/ready/strong, amber = caution/partial/worth-exploring, red = broken/blocking, slate = neutral/speculative/skip. Define the mapping in the legend; keep it consistent.
- **Details line** — monospaced (`font-mono text-sm`) for the concrete artifacts: file paths, package names, commands, versions.
- **Visual** (only when it earns its place) — see diagram patterns.
- **Problem** — one sentence. What hurts or what's missing.
- **Resolution** — one sentence. What to do, or why nothing.
- **Notes bullets** — ≤6 words each, concrete gains or caveats.

**Summary section** — one larger card at the end: the single most important takeaway or recommended next action, with anchor links to relevant cards. Tables are fine here for enumerable facts (counts, statuses); explanations stay in the cards.

If a card needs a paragraph to be understood, restructure the card. No paragraphs of explanation anywhere.

## Diagram patterns

Skip diagrams entirely for inventory/status reports — badges and tables carry those. When relationships or before/after shapes are the point, mix these; variety is part of the look:

- **Mermaid flowchart/sequence** — for "X depends on Y, look at the mess" or "before: 6 round-trips, after: 1". Wrap in `rounded-lg border border-slate-200 bg-white p-4`. Use `classDef` to color problem edges red.
- **Hand-built boxes-and-arrows** — divs with borders, inline SVG arrows over a relative container, when Mermaid's layout fights you or you need weight (thick border = the important thing, faded internals).
- **Cross-section** — stacked horizontal bands (`h-12 border-l-4`) for layered structures.
- **Before/after pairs** — two columns side by side, each diagram ≤~320px tall so the pair fits without scrolling.

Label things inside diagrams with `text-xs uppercase tracking-wider` — schematic, not UI.

## Visual examples (design reports)

When the report recommends something the reader must *see* to judge — a font, a color, a component shape, a spacing scale — **render the real thing, don't just name it.** A design/typography/color report that says "use Fraunces" or "primary #E8590C" in plain text has failed: the reader can't compare options they can't see. Show, don't list.

- **Fonts** — load each candidate from the Google Fonts CSS CDN in `<head>` (same CDN-only rule as Tailwind/Mermaid) and set a real specimen in it: the actual recipe title, a section header, a body line, and sample numerals — in the actual family, at the proposed weights/sizes. Verify each family loads first (`curl -s -o /dev/null -w '%{http_code}' 'https://fonts.googleapis.com/css2?family=<Family>:wght@400;600;700'` returns `200`). For a variable font, exercise the axis (`font-variation-settings: 'wght' 600`). Put each pairing option in its own card so specimens sit side by side for comparison.
  ```html
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600&family=Inter:wght@400;600&display=swap" rel="stylesheet">
  <!-- then: <h3 style="font-family:'Fraunces',serif;font-weight:600">Roast Chicken</h3> -->
  ```
- **Colors** — render a real swatch for every value with its **literal hex printed on/under it**, not a prose list. Show light AND dark rows. Then apply the palette in context — a small mock (a recipe card, a button, a chip) painted with the actual roles — because a palette is judged by how roles interact, not as isolated squares.
  ```html
  <div style="background:#E8590C" class="h-14 rounded flex items-end p-1">
    <span class="text-white text-[10px] font-mono">#E8590C primary</span>
  </div>
  ```
- **Components / shape / spacing** — CSS-approximate the actual widget (card, chip, button, app bar) with the *exact* proposed tokens — corner radius, elevation/shadow, border width+opacity, padding — so "Soft 16dp / no shadow" vs "Editorial 8dp / hairline" are compared as rendered objects, not adjectives. Render a spacing scale as literal gap bars labeled with their dp.
- **Layout** — give each option (pairing, palette, shape personality) its own card, and where practical show the same mock content rendered through each option so only the variable under review changes. This is the design-report analog of before/after pairs.

Still no interactivity and no JS beyond Mermaid — these specimens are pure HTML/CSS. Keep the page self-contained; CDN fonts are fine (they're the subject).

## Style

- Editorial, not corporate-dashboard: generous whitespace, `font-serif` optional for headings, stone/slate base.
- One accent color (emerald or indigo) plus red for problems and amber for warnings. Nothing else.
- Dark cards (`bg-gradient-to-br from-slate-900 to-slate-800 text-stone-100`) sparingly, for the one thing that must dominate the page.

## Tone

Plain, concise, no hedging, no "it's worth noting". Sentences that could be bullets become bullets; bullets that could be cut get cut. Use the domain's own precise vocabulary consistently — if the work has established terms (from a glossary, a skill, the codebase), use exactly those and never synonyms; a report that drifts between "module/component/service" for one concept reads as sloppy thinking. Numbers over adjectives: "45 unresolved" not "many unresolved".
