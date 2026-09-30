---
name: geiger
description: >
  Use when the user asks for an architecture audit, review, or health check of
  a codebase's structure — dependency cycles, tangled modules, hidden
  coupling, layering violations, churn hotspots, architecture drift
  (agent-caused erosion) — or says "geiger", "architectural mistakes", "bad
  patterns in the structure", or wants architecture rules enforced in CI. Covers import/module dependency graphs
  (internal code structure), NOT package-manager dependencies: not for
  npm/pip updates, vulnerability audits, or line-level code review.
---

# geiger

Division of labor (this is the core idea — don't invert it):
**deterministic tools for recall, you for precision.** The script detects;
you judge intent. Never re-derive graph facts by reading files the script
already measured, and never dump a full dependency graph into context.

## Phase 1 — Extract

**Small repo (< ~50 code files): light mode** — still run Phase 2 (it takes
seconds and catches cycles a read-through misses), then read the code
directly and judge; skip Phase 3.5 and the ~12-finding budget.

Detect the repo's language(s) (`git ls-files` extensions) and pick the
extractor. Write extractor output to a temp/scratchpad path, never into the
repo.

| Language | Preferred command | Notes |
|---|---|---|
| JS/TS | From **repo root**: `madge --json --extensions ts,tsx,js,jsx --ts-config tsconfig.json . > /tmp/.../graph.json` | Scan `.`, never a subdir — subdir-relative node ids break the git join. `--extensions` is mandatory for TS (bare madge returns `{}` silently). Monorepo: run package install first (workspace imports drop silently otherwise), still scan from root. `depcruise -T json` also parses if madge unavailable. |
| Python | nothing — built-in ast extractor | default via auto-detect |
| Rust | `cargo modules dependencies --lib --no-externs --no-sysroot --no-fns --no-types --no-traits > graph.dot` (use `--bin <name>` for bin-only crates — `--lib` errors) | The script drops `label="owns"` containment edges (they fabricate cycles). Node ids are `crate::mod` paths — hidden_coupling can't join to git; say so in the report. |
| Dart/Flutter | `scripts/dart_edges.py <repo_root> > edges.json` (madge-format; whole workspace in one run, resolves `package:` URIs across melos packages; parses with **ast-grep** — required, no regex fallback — so wrapped and conditional imports count and strings/comments don't; every conditional branch becomes an edge; `part` files are nodes with an edge from their library; coverage goes to stderr) | Do NOT use lakos for edges: **lakos 2.0.7 drops any import/export whose `show`/`hide` clause wraps to the next line** (dart format wraps at 80 cols — verified single-line-vs-wrapped controls, shiso 2026-08-16: 30% of edges lost, phantom hidden_coupling). lakos remains fine as a per-package NCCD/isAcyclic cross-check. |
| Anything else | none — **git-signals-only mode** | The script still emits hotspots and co-change; graph metrics and hidden_coupling need `--edges` from a native tool (e.g. `goda graph` for Go — not `go mod graph`, which lists module requirements; jdeps for Java). Report the reduced scope explicitly. |

If the native tool isn't installed, offer to install it (`npm i -g madge`,
`cargo install cargo-modules`, `dart pub global activate lakos`) but don't
block — fall back and note reduced accuracy in the report.

## Phase 2 — Compute

```
python3 ~/.config/claude/skills/geiger/scripts/xray.py --repo <repo> [--edges FILE] [--top 10]
    [--baseline geiger-baseline.json] [--changed <base-ref>] [--refresh-baseline]
```

Emits a top-N-capped JSON digest: cycles (with `last_active`, `folder_span`,
and an `example_path` like `a → b → a`), hubs (p90-degree cutoff), orphans,
instability, SDP violations (heuristic delta>0.4; python TYPE_CHECKING
imports excluded — count in `type_only_imports_excluded`),
**feedback_edges** (levelization back-edges from the Eades heuristic: cutting
the *complete* set makes the graph layerable — a displayed top-N subset may
not; one valid cut among several, not the cheapest or the intended one),
`layering_score`, NCCD and **propagation_cost** (closure density —
size-sensitive, compare within one repo over time, not across repos), plus
git signals: hotspots scored `decayed_commit_weight × (loc + indent_units)`
with `recent_share` (dormant-vs-active), line churn, author count +
top-author share, and `hot_functions` (which functions take the churn —
from diff hunk headers; heuristic starting point, not a metric; absent on
blobless partial clones); **hidden coupling** — file pairs that co-change
(≥4 shared commits and jaccard ≥ 0.3) but share no direct import edge:
coupling the import graph doesn't explain (DB schema, wire format,
copy-paste — or an indirect import, or ordinary feature work); a
**knowledge** block (truck_factor, single-owner `islands` flagged
`is_hotspot`, and `stale_ownership` — majority-owned by authors with no
commits in the last ≥12 months of the analyzed window; commit-history
proxies, never claims about who knows what or who left); and
**low_cohesion_folders** (<0.3 of intra-folder pairs share any edge or
co-change — grab-bag candidates; validated phenomenon, unvalidated proxy —
present as leads, not verdicts); and **compound** — files carrying ≥2 smells
at once (in one industrial study 97% of cycles passed through an
unstable-dependency center — a prioritization cue, not a law).
Test/generated files excluded by default, from `--edges` input too
(`--include-tests` to keep them). Numeric cutoffs (p90 hubs, 0.4 SDP delta,
0.3 jaccard/cohesion, 12-month dormancy) are local heuristics, not validated
thresholds — rank by them, don't cite them as standards.

**Baseline ratchet**: `--baseline FILE` creates the file on first run
(structural identities), then marks findings `new`/`known` and reports
new/fixed/known counts per category (orphans: counts only, no per-item
marks). After confirmed fixes, `--refresh-baseline` rewrites it and refuses
growth; accepting new findings into the baseline takes an explicit
`--rebaseline`, which needs the user's say-so. In PR mode `fixed` is null
(indeterminable from a partial view). The baseline stores identities, not
metric values — keep the previous full digest beside it for metric deltas.

**PR mode**: `--changed <base-ref>` scopes every list to files changed since
the merge-base plus their 1-hop graph neighbors (`scope` field reports
sizes). Use with `--baseline` so pre-existing findings show as `known`.
Baselines are never written in PR mode (partial view). Report a finding as
fixed only from a comparable full run (same extractor, exclusions, window) —
absence from a capped or partial view is not a fix.

**Sanity gates — check before judging:**
- `warnings` present or `edges == 0`: extraction failed, degraded, or
  git-signals-only. Treat it as such — never report "no cycles" as health.
  Git signals (hotspots, co-change) remain valid with zero edges; graph
  verdicts don't.
- `node_git_match_rate` / `git.git_join` low: the graph↔git join failed;
  hidden_coupling and `last_active` are unreliable — say so, don't present
  empty hidden_coupling as "no hidden coupling" (absence of evidence).
- `git.enrichment` reports skipped or timed-out enrichment and
  `git.commits_scanned` / `git.window` the history actually used — a
  million-commit repo can yield a handful of qualifying commits.
- A graph with edges can still be incomplete. Check `coverage`
  (per-language discovered/eligible/parsed/failed) and `graph_scope`, and
  spot-check two or three imports you know exist (grep one import line,
  confirm the edge is in the digest's scope). A missed language (C++, Nix…)
  means the graph covers part of the repo — state which part.

Every list reports a `*_truncated` count — mention truncation, never present
a capped list as exhaustive. Raise `--top` only on request.

## Phase 3 — Judge

**Intent first.** Before scoring, collect the stated architecture in ≤10
lines: `ARCHITECTURE.md` (and its `geiger:contract` block), `docs/adr/` or
similar decision records, existing boundary configs (`.dependency-cruiser.*`,
`.importlinter`, `.go-arch-lint.yml`, ArchUnit tests), and layer names the
code itself consistently follows. None found → say so; verdicts then rest on
consequences alone.

Classify each finding: **intentional design / erosion / unclear**. A finding
is **erosion** only when it (a) violates a constraint from that intent list,
or (b) has a concrete consequence you can name from the code or history — a
change that had to touch both ends, a bug, a blocked extraction or test.
Structure alone (folder layout, graph shape) is a hint, not proof: in
SmellBench (2026) experts rejected 41 of 65 hard-severity smell findings as
false positives. No constraint and no consequence → `unclear`, even if
ugly.

Judge at most ~12 findings total, prioritized: violations of a stated
constraint, then hidden coupling, then largest cycles, then SDP violations
by `from_fan_in`, then hubs. Within each category, a finding whose file
appears in `compound` outranks its peers. List the rest as **unjudged** — no
code reading for them. Budget is a default: spend extra reads when a verdict
hinges on missing evidence, and say so. Cite the ADR a finding violates or
confirms — "violates ADR-012" beats any structural argument.

Triage hints — starting presumptions to test, not verdicts:
- **Intentional hub**: plugin/handler registry, DI composition root, public
  facade or barrel re-exporting a package — high fan-in is its job. Hubs
  tagged `role: aggregator` are facade-shaped: presume intentional and skip
  the file read unless it's a cycle member, a stated-constraint violation,
  or other evidence contradicts.
- **Erosion hub**: grab-bag `utils`/`helpers`/`common`, a domain module that
  accreted callers from unrelated domains, **or a core module whose fan_out
  reaches into presentation/IO layers** (dependency-direction violation —
  judge fan_out accretion, not just fan_in).
- **Intentional cycle**: parent↔child in one data structure, or a declared
  mutual recursion within one folder — `folder_span: 1` cycles lean this
  way; deprioritize them. **Erosion cycle**: `folder_span > 1` leans erosion
  when it crosses a stated layer or domain boundary — folders are not always
  layers.
- **Hidden coupling**: "no direct import" means the import graph doesn't
  explain it, not that nothing does. Rule out an indirect import path and
  one-off feature work first. Erosion if the pair shares an invisible
  contract (schema, wire format, mirrored API, copy-paste) with no check
  keeping the two in sync; intentional if the co-change has a benign cause
  (release chores, version bumps).
- **Managed coupling**: a mediation registry, codegen needing manual list
  updates, a docstring acknowledging the cycle, or a requirement-driven
  mirror (two platforms/languages) is intentional coupling with an
  **enforcement gap** unless CI checks it. Classify erosion when the history
  or code shows the manual step already slipped (a missed update, a parity
  fix commit); otherwise intentional with fix "automate/enforce the
  mitigation (parity test, generator in CI)" — never "decouple" for a
  product-required mirror.
- For same-folder hidden-coupling pairs, read **both** ends before ruling —
  one end often reveals an explicit DI/interface boundary the other implies.
- **Dormancy**: cycle `last_active` over a year ago → dormant (report,
  deprioritize); recent → active erosion.
- NCCD: lower is better, but it is not a cycle signal — a fully acyclic
  31-node chain scores ~3.8. Read cycles from `cycles`, not NCCD. NCCD and
  propagation_cost share one numerator, so their agreement is not
  corroboration.
- Smell counts scale with repo size — rank, don't count.

Rules of engagement:
- **Commit first, then read**: before any file read for a finding, write the
  metric-only hypothesis plus its strongest rival explanation and the code
  fact that would tell them apart. Then read for that fact; if the verdict
  flips, say so in the evidence line. (Keeps the read from becoming post-hoc
  rationalization.)
- Read only the files at the two ends of one edge per finding, or a hub's
  interface — and only the **import block + exported signatures** (Read with
  `limit` ~120 lines), not whole files. When a hotspot lists
  `hot_functions`, read those functions instead of the file head. Exception:
  hidden-coupling findings may need body reads — that coupling lives in
  implementations (shared SQL, wire formats), not imports.
- Knowledge signals are cross-cutting context, not separate verdict rows:
  a judged finding whose file is also a knowledge island (`is_hotspot`) or
  majority-stale gets that noted in its evidence — island ∩ hotspot ∩ cycle
  member is the highest-priority combination in the digest.
- **Dedupe reads across findings**: the same file often recurs as hotspot,
  hub, cycle member, and coupling endpoint. Read it once; cite it in every
  finding it appears in.
- Every verdict's evidence line must cite the concrete metric values
  (fan_in, jaccard, last_active…) plus one code fact you actually read — no
  vibe sentences.

**Deliverable**: verdict table (ID, finding, class, confidence high/med/low,
violated constraint or named consequence, evidence, suggested fix direction)
+ 3-line summary (extractor used and coverage, caps/warnings hit, headline
verdict) in chat. Where relevant, price findings in agent terms — a high
fan-in hub or wide propagation_cost plausibly means an agent editing there
must read more files to be safe (a reasoned cost, not a measured one). If the digest has `tier3_triggers`, append one final
**Tooling** line listing them — these are pre-agreed build conditions for
parked geiger features (not findings about the repo); offer to build the
triggered feature. Two judge-side triggers to watch for and report the same
way: (a) a module recurring in cycles/feedback_edges but absent from hubs →
"pagerank hub-ranking trigger"; (b) a low_cohesion folder that materially
informed an erosion verdict → "misplacement-tag trigger". Erosion first, sorted by severity proxy: cycle `size`,
SDP `from_fan_in`, hub `fan_in+fan_out`, hotspot `score`, hidden-coupling
`jaccard`. Number the rows `F1`, `F2`, … in final table order (first column);
the unjudged list continues the same sequence. Phase 3.5, Phase 4, and any
follow-up chat refer to findings by these IDs — "fix F2 and F4" must resolve
unambiguously, so never renumber. Don't paste the raw digest. If the user wants a document, use the
html-report skill.

## Phase 3.5 — Refute (on "thorough" request, or when any erosion verdict is high-impact or low-confidence)

Adversarially re-test every **erosion** verdict, plus one or two
`intentional` verdicts on high-signal findings (false negatives hide
there). For each: spawn a refuter that gets the digest + the finding + the
claimed class + the intent list + read access to the repo — **never the
judge's reasoning or evidence lines** (context asymmetry against anchoring;
a design choice, not a measured effect). Mandate: "refute this
classification with a concrete metric value or code fact, or fail." Prefer a *different model family* as refuter — the
"cross-family refuter" route in `AGENTS.md`'s dispatch table (invocation
shapes in the `plan-refute` skill); cross-model refuters catch
correlated-training errors that same-model review endorses. Otherwise a
same-model fresh-context worker still helps.
Refuted → downgrade to `unclear`, noting the refutation in the table.
Unrefuted stays erosion — never upgrade confidence on agreement; agreement
is not evidence.

## Phase 4 — Freeze (only on request)

Turn confirmed verdicts into CI-enforceable rules:

| Ecosystem | Rule target |
|---|---|
| JS/TS | `.dependency-cruiser.cjs` `forbidden` rules (+ `depcruise-baseline` for its own ratchet) |
| Turborepo monorepo | `turbo boundaries` with tags (experimental, ≥2.4.2) — native to the build tool |
| Python | `.importlinter` — `layers` / `forbidden` / `independence` / `acyclic_siblings` contracts. Tach is an alternative (maintained again: 0.35.1, Sept 2026) |
| Rust | `cargo modules dependencies --acyclic` in CI; module privacy (`pub(crate)`) for boundaries |
| Dart | `import_lint` / `architecture_linter` in `analysis_options.yaml` (check installed version's rule schema — it changed across majors) |
| Go | `go-arch-lint` (`.go-arch-lint.yml` `mayDependOn` model); extractor for `--edges`: `goda graph` |
| Java | ArchUnit rules as unit tests — `FreezingArchRule` is the built-in ratchet; extractor: `jdeps -dotoutput` |
| Kotlin | Konsist (pre-1.0), or ArchUnit — it runs on Kotlin bytecode |
| C# | ArchUnitNET (xUnit/NUnit/MSTest integrations) |
| PHP | deptrac layers + its baseline formatter |
| Any | ast-grep rule for code-pattern-shaped findings |

Rules encode the intended boundary, not whatever the graph heuristic cut.
`feedback_edges` are candidates: keep one only when it points against the
stated or confirmed layering direction, and consider alternative cuts
before freezing it. SDP violations are a noisier source. **Never emit a rule
unvalidated.** For each generated rule: run the tool and confirm (a) it
fires on the known violation, (b) it passes on a clean path or after
whitelisting — and that the whitelist names specific imports, not a blanket
pattern that makes the rule vacuous. On validation failure, retry once with the failing
output quoted in context; then drop the rule and report it as unfrozen.
Stay on the well-known formats above.

Also write/update `ARCHITECTURE.md` with the confirmed layering rules
(prose; the machine ratchet is the `--baseline` JSON) — and make it
**agent-consumable**: a marker-delimited contract section
(`<!-- geiger:contract -->` … `<!-- /geiger:contract -->`, ≤20 lines,
replaced on rerun) stating layering direction, forbidden dependencies,
known-tangled areas not to grow, and "run geiger PR mode after structural
edits". Wire it to coding agents explicitly — auto-loading is NOT automatic:
add a single `@ARCHITECTURE.md` import line to CLAUDE.md (Claude Code only
auto-loads CLAUDE.md; keep it under its ~200-line guidance — one line, never
a section) and, if AGENTS.md exists, one reference line there for
Codex-family agents (they read AGENTS.md natively, 32 KiB cap). Prevention
at generation time beats inspection after.

On later runs with a baseline, the deliverable is **drift only**: new
violations / fixed / metric deltas (cycle_count, nccd, propagation_cost,
against the saved previous digest) — not a re-audit. If the extractor,
exclusions, or `--top` changed since the baseline, say the runs aren't
comparable instead of reporting deltas. For continuous drift watch, note the user can schedule it:
`geiger` with `--baseline` in CI cron (weekly) posts only the delta.

## Cautions

- Static graphs miss runtime coupling: DI containers, reflection, dynamic
  dispatch, message buses. Hidden coupling (git) partially compensates.
- Co-change granularity follows commit conventions: squash-merge repos
  measure PR-level coupling (tangled PRs overcount); fine-grained-commit
  repos undercount work split across commits. Bot commits are filtered;
  renames are followed (`-M`) within the analyzed window.
- Analysis caps: last 2000 non-merge commits *before* bot/language
  filtering (a big repo may yield only a handful of qualifying commits —
  check the count before trusting git signals), 3000 nodes for NCCD,
  co-change skips commits touching >20 files. "Recent" and "stale" are
  relative to the newest analyzed commit, not today.
