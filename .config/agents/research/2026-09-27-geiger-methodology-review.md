# Geiger methodology review — 2026-09-27

Reviewer: Codex `gpt-6-astra` (delegated). Companion: `2026-09-27-geiger-scripts-review.md`.

Scope: the full 248-line `SKILL.md`, metric-related portions of `xray.py`, the Dart extractor, the July research record, and its index. No delegation or skill/script edits occurred. External evidence below was checked through web search; recommendations and mathematical observations are identified as reviewer judgments. This is a targeted review, not an exhaustive literature survey.

**Overall finding**

Geiger has a sound foundation: deterministic extraction, bounded evidence gathering, explicit uncertainty, and executable architecture rules. This matches Thoughtworks’ April 2026 account of combining static analyzers with LLM evaluation and a verification loop. However, that Radar entry is an **Assess** recommendation and practitioner experience, not proof that Geiger’s particular thresholds or judging protocol are optimal. [Thoughtworks](https://www.thoughtworks.com/en-ca/radar/techniques/architecture-drift-reduction-with-llms)

The largest improvement is better separation of **observed structure, architectural intent, and demonstrated harm**. Adding more metrics should come after correcting premature classifications and making longitudinal comparisons reproducible.

**Research findings**

- **Architecture-smell detection needs contextual validation.** SmellBench, submitted May 7, 2026, evaluated 65 hard-severity findings in scikit-learn. Experts classified 41 as false positives, 13 as partially valid, and 11 as genuine. Its most aggressive repair configuration introduced 140 new smells. These results support cautious judgment and checking net impact, but their single-project scope does not establish Geiger’s expected error rate. [SmellBench](https://arxiv.org/html/2605.07001v1)

- **Agent-caused degradation has relevant empirical evidence, with limited generalizability.** SlopCodeBench studies repeated extensions across 20 problems and 93 checkpoints, measuring duplication and concentration of complexity. It reports worsening trajectories and finds that prompting improvements do not stop degradation. These are benchmark-specific structural measures, not validation of import-graph thresholds or proof that every agent-assisted repository deteriorates. [SlopCodeBench, March 2026](https://arxiv.org/abs/2603.24755)

- **Another directly relevant May paper studies generated architectural smells.** Its authors report increasing coupling and code volume across their evaluated generation settings. This supports inspecting structural quality independently of functional correctness; its claimed “Volume-Quality Inverse Law” should remain an attributed study conclusion, not become a universal skill rule. [AI-Generated Smells](https://arxiv.org/abs/2605.02741)

- **Temporal coupling is not inherently erosion.** CodeScene explicitly treats its meaning as contextual and supports same-commit, same-author/time-window, and ticket-linked analyses. Code Maat exposes minimum individual/shared revision counts, changeset-size filtering, temporal grouping, and component aggregation. These provide useful comparison points for Geiger’s simpler history model. [CodeScene](https://docs.enterprise.codescene.io/versions/6.6.0/guides/technical/change-coupling.html), [Code Maat](https://github.com/adamtornhill/code-maat)

- **Adversarial review remains a hypothesis worth testing.** A July 2026 survey of 141 debate studies finds that many configurations reflect convention rather than controlled comparison. A June medical-QA study demonstrates that apparent consensus can conceal reasoning disagreement; transfer to architecture auditing is an inference. Neither validates Geiger’s exact claim that hiding evidence lines prevents anchoring. [Debate survey](https://arxiv.org/abs/2607.26212), [The Consistency Illusion](https://arxiv.org/abs/2606.08457)

**Ranked recommended SKILL.md changes**

1. **Replace automatic verdicts with evidence requirements.**

   Change the same-folder-cycle default, cross-folder-cycle erosion rule, automatic aggregator exemption, and “managed-manual means erosion” rule to **triage hints**.

   Suggested instruction: “Classify erosion only when the finding violates an applicable architectural constraint or has a concrete adverse consequence. Record intended coupling and the adequacy of its controls separately.”

   Why: folder layout is not an architectural specification; a facade-shaped graph is not proof of a facade; absence of CI is an enforcement gap rather than proof of unintended design. These are reviewer judgments supported by contextual false positives in [SmellBench](https://arxiv.org/html/2605.07001v1) and CodeScene’s explicitly neutral treatment of [change coupling](https://docs.enterprise.codescene.io/versions/6.6.0/guides/technical/change-coupling.html).

2. **Add a short architecture-and-extraction contract before scoring.**

   Record intended components/layers, authoritative ADRs, source roots, graph node granularity, dependency kinds, build configuration, exclusions, and unresolved imports. Separate runtime, type-only, test, and generated-code views where available.

   Suggested instruction: “A graph with edges can still be incomplete. Verify representative known dependencies and report extraction coverage before interpreting absence.”

   Why: current zero-edge and Git-join gates catch important failures but do not establish completeness. Excluding type-only edges can be appropriate for runtime cycles while hiding compile-time boundary violations. This recommendation follows the explicit component/rule models supported by [dependency-cruiser](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md) and [Import Linter](https://import-linter.readthedocs.io/en/latest/).

   Local observation: `dart_edges.py` handles wrapped `show`/`hide` differently from conditional URIs; its conditional matching is restricted to the directive’s line. Describe it as a limited extractor rather than broadly “wrapping-proof.” Implementation review belongs to the separate reviewer.

3. **Correct metric interpretations and label thresholds as local heuristics.**

   Retain instability as a structural signal, but distinguish file-level fan-in/fan-out from component-level Martin metrics. Where meaningful, optionally report abstractness `A` and normalized main-sequence distance `|A + I − 1|`; do not force class-based abstractness onto every language.

   Remove “NCCD <1 … fine” and “>2 likely tangled/cyclic” as verdict guidance. NCCD compares cumulative reachability with a balanced binary tree; it does not identify cycles. [ArchUnit’s metric definitions](https://www.archunit.org/userguide/html/000_Index.html#_software_architecture_metrics)

   **Reviewer calculation:** a 31-node acyclic chain has CCD `496`; Geiger’s denominator is `129`, giving NCCD ≈ `3.84`. Thus a high value can describe a completely acyclic structure.

   Mark p90 hubs, instability delta `0.4`, Jaccard `0.3`, cohesion `0.3`, twelve-month dormancy, and the 50-file cutoff as configurable operational choices. This review found no primary validation establishing those exact values as generally optimal.

4. **Strengthen temporal-coupling interpretation before increasing its priority.**

   Document the existing **four-shared-commit minimum**, which the script implements but the skill omits. Report both files’ revision counts, shared count, history dates, excluded changesets, and support limitations.

   Suggested instruction: “No direct import means the relationship is unexplained by a direct import—not that it lacks a legitimate architectural explanation.”

   Inspect indirect dependencies, common schemas, feature work, and coordination conventions. Add optional directional conditional rates to expose asymmetric relationships; do not silently equate Jaccard with another tool’s coupling percentage.

   Why: fixed commit caps cover different calendar periods across repositories, while commit conventions change what co-change measures. [Code Maat](https://github.com/adamtornhill/code-maat) and [CodeScene](https://docs.enterprise.codescene.io/versions/6.6.0/guides/technical/change-coupling.html) expose relevant controls. The recommended interpretation is reviewer judgment.

5. **Treat feedback edges as candidate interventions, not architectural prescriptions.**

   Replace “best forbid-rule candidates, better than SDP” with: “Candidate cycle-breaking edges; validate the intended boundary, alternative cuts, and implementation consequences before proposing a rule.”

   Why: the Eades–Lin–Smyth method is a graph heuristic with a performance bound, not an optimizer of architectural intent or refactoring cost. Removing a selected set can produce a DAG without producing the desired architecture. [Original algorithm and author manuscript](https://researchportal.murdoch.edu.au/esploro/outputs/journalArticle/A-fast-and-effective-heuristic-for/991005543112107891)

   Also state that the **complete computed cut set**, not necessarily a displayed top-N subset, is relevant to the acyclicity claim.

6. **Make judgment and refutation evidence-seeking rather than verdict-seeking.**

   Replace “commit a metric-only hypothesis verdict” with “record competing explanations and the observation that would distinguish them.” Remove “measurably reduces false-positive agreement” unless a directly applicable evaluation is cited.

   Refute high-impact or uncertain findings regardless of whether four erosion findings exist. Include a small sample of intentional/dismissed findings to check false negatives. Provide architectural constraints and independent source access; a finding label and digest alone are insufficient.

   Retain “agreement is not evidence.” A different model family is an optional diversity technique, not a guarantee. These are reviewer recommendations; current [debate research](https://arxiv.org/abs/2607.26212) does not establish Geiger’s exact protocol as optimal.

7. **Make the baseline a reproducible comparison contract.**

   Record revision, extractor/version, configuration, inclusion rules, graph granularity, history window, thresholds, and metric values alongside structural identities. Mark incompatible snapshots as non-comparable.

   Local observations: the current baseline stores identities, not the historical metric values needed for the promised metric deltas. `--refresh-baseline` replaces its contents; “should only shrink” is a policy instruction, not an enforced invariant. PR mode correctly emits `fixed: null`, contradicting the nearby unconditional instruction to report fixed findings.

   Suggested instruction: “Report fixes only from comparable full snapshots or an explicit base/head comparison. Never interpret capped or partial absence as resolution.”

   The rationale follows established baseline enforcement practice, including [ArchUnit freezing](https://www.archunit.org/userguide/html/000_Index.html#_freezing_arch_rules), but the proposed snapshot schema is reviewer judgment.

8. **Refresh the enforcement table and correct dependency scope.**

   | Ecosystem | Recommended instruction |
   |---|---|
   | JS/TS | Keep dependency-cruiser; prefer an existing validated configuration and explicit architectural rules. [Documentation](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md) |
   | Python | Keep Import Linter; its current documented contracts also include protected modules and acyclic siblings. Reconsider Tach rather than prohibiting it. [Import Linter](https://import-linter.readthedocs.io/en/latest/), [Tach](https://github.com/tach-org/tach) |
   | Java/Kotlin JVM | Keep ArchUnit; it supports architectural rules, freezing, and Kotlin usage. Avoid unsupported “de-facto standard” claims for alternatives. [Guide](https://www.archunit.org/userguide/html/000_Index.html) |
   | Go | Keep `go-arch-lint` component rules. Remove `go mod graph` as an example of internal-source extraction: it reports module requirements. [go-arch-lint](https://github.com/fe3dback/go-arch-lint/blob/master/docs/syntax/README.md), [Go reference](https://go.dev/ref/mod#go-mod-graph) |
   | Rust | Keep cargo-modules for internal structure. Describe cargo-deny as complementary dependency policy, not an internal module-boundary checker. [cargo-modules](https://github.com/regexident/cargo-modules), [cargo-deny](https://embarkstudios.github.io/cargo-deny/) |

   **Verified stale statement:** “Tach — unmaintained since mid-2025.” PyPI lists **0.35.1 released September 14, 2026**, and the repository redirects to `tach-org/tach`. Gauge’s discontinued-product notice does not establish that the open-source project is unmaintained. [PyPI](https://pypi.org/project/tach/), [Gauge notice](https://www.gauge.sh/open-source)

   Retain positive/negative validation of generated rules, but require proof that the rule matched relevant code; a vacuous pass or blanket whitelist is insufficient.

9. **Add targeted DSM/component analysis without duplicating metric weight.**

   Keep propagation cost, but pair it with affected components, SCC membership, transitive fan-in/out, and an optional component-level DSM or condensation graph. Avoid mandatory full-graph dumps.

   Propagation cost measures visibility-matrix density; core/periphery analysis examines the organization behind that scalar. The HBS paper’s indexed primary-source excerpt verified the definition; direct PDF retrieval was blocked. [Baldwin, MacCormack and Rusnak, *Hidden Structure*](https://www.hbs.edu/ris/download.aspx?name=13-093.pdf)

   **Reviewer observation:** Geiger’s NCCD and propagation cost share the same CCD numerator. At fixed node count they are rescalings, not independent evidence. Do not count their agreement as corroboration. Adding unrelated nodes can also lower propagation cost without untangling an existing core.

10. **Make the audit budget adaptive and the output auditable.**

    Replace “skip below 50 files” with a lightweight mode that retains cheap boundary/cycle checks. Keep twelve findings as a default budget, but allow additional reads when a verdict depends on missing evidence.

    Add confidence, violated constraint, practical consequence, coverage, and validation status to the deliverable. Prioritize explicit boundary violations and consequential changes before an unconditional “hidden coupling first” ordering.

    Keep stable finding IDs and unjudged counts. Describe truck factor and ownership as history-derived proxies, not actual knowledge or employee departure. Describe the “per-task token tax” as a hypothesis unless task-level token measurements exist.

    These are reviewer recommendations motivated by the gap between functional success and later extensibility measured in [SlopCodeBench](https://arxiv.org/abs/2603.24755).

**What the July 30 sweep missed or cannot support**

The sweep was useful for discovery but heavily populated by social posts, code-mapping products, and broader agent discussion. It did not substantively establish Martin metrics, DSM/core-periphery methods, threshold calibration, temporal-coupling semantics, or the exact refutation protocol.

It missed the directly relevant May [SmellBench](https://arxiv.org/abs/2605.07001) and [AI-Generated Smells](https://arxiv.org/abs/2605.02741) papers. It mentioned SlopCodeBench through a benchmark-news item, but did not analyze its longitudinal methodology. These were **existing omissions**, not discoveries that required waiting until September.

The sweep already identified Thoughtworks’ hybrid approach and [The Spec Growth Engine](https://arxiv.org/abs/2606.27045). The latter proposes a workflow; its presence does not validate Geiger’s numerical cutoffs.

The skill’s “97% of cycles” statement does have a source. However, it is an observation from a particular industrial study, whose authors caution about contextual applicability—not a universal probability or validation of Geiger’s different unstable-dependency heuristic. Keep compound findings as prioritization context with that qualification. [Industrial study](https://link.springer.com/article/10.1007/s10664-022-10132-7)

No verified August–September architecture-review paper found in this targeted search establishes a superior complete replacement workflow. The clearest verified September tooling correction is Tach’s release. Search absence is not evidence that no newer research exists.
