# Configuring coding agents to teach rather than do (2026-09-23)

Question: how should an agent behave in a repo the user is building *to learn*
(scaffold the boring parts, leave concept-bearing code to the learner, hint
instead of answer, point at docs)? What is tested, what is opinion?

Produced the `tutor` skill. First use: `~/repos/laritech-practice`
(its `AGENTS.md` holds the project-specific docs map).

## TL;DR

- Three solid RCTs agree: unrestricted AI help raises practice performance and
  lowers unassisted performance afterwards. A hints-not-answers tutor prompt
  removed the harm (Bastani) or produced large gains (Kestin), but both prompts
  also carried expert-written solutions.
- How the learner uses the AI matters more than whether: conceptual questions
  and self-debugging go with learning; delegating code or debugging goes with not
  learning. Harm concentrates in low-prior-knowledge learners.
- Prompt guardrails leak: CS50's duck still put code blocks in 48% of
  conversations despite a no-solutions prompt ("instruction dilution" on a
  ~1,000-token prompt). Keep the rules short, add a few-shot example, prefer
  structural enforcement.
- Hint ladders and predict/explain checks rest on strong evidence. "Point to the
  primary docs" has no direct outcome evidence; it is justified indirectly by
  accuracy (both positive RCTs grounded the tutor in expert material).

## Evidence

| Study | Design | Result | What made the difference |
|---|---|---|---|
| Bastani et al., PNAS 2025 | Field RCT, ~1,000 HS maths students | Unassisted exam: plain GPT −17% of control mean (≈ −0.19 SD, p<.05); GPT Tutor −0.004 (ns). Practice: +48% / +127% | Tutor prompt gave hints, never answers, and included teacher solutions + common mistakes. Harm came from using Base as a crutch |
| Shen & Tamkin (Anthropic), Jan 2026, arXiv 2601.20245 | RCT, 52 mostly junior devs learning Trio | No-AI quiz: AI 50% vs hand-coding 67%, d = 0.74, p = .01; biggest gap in debugging; speed gain ns | High scorers: conceptual inquiry, generation-then-comprehension. Low: delegation, iterative AI debugging (clusters n=2–7, not causal) |
| Kestin et al., Sci. Reports 2025 | Crossover RCT, n=194 physics | 0.73–1.3 SD gains vs active-learning class | "Only give away one step at a time"; pre-written solutions; prompt alone could not sequence multi-part problems |
| Lehmann et al., arXiv 2409.09047 | 2 pre-registered labs + field | Substitutive use: more coverage, less understanding, long-term decline. Complementary use: deeper understanding. Helped high-prior, hurt low-prior learners | |
| Prather et al., ICER 2024 | Observational, novices | Weak-metacognition novices got worse with an "illusion of competence" | Qualitative |
| Kazemitabaar et al., CHI 2023 | Controlled, ages 10–17 | No retention loss after a week (counter-evidence) | Structured tasks, learners still modified code by hand |
| Kapoor et al., arXiv 2504.11146 | n=885, optional "See Solution" | 50% bypassed at least once, 14% every time; worst near deadlines, low performers | Expect bypass under time pressure |
| Liu et al. (CS50), SIGCSE TS 2025 | ~10M duck messages | 48% of conversations had code blocks; GPT-4o raised it (44%→56%) | Instruction dilution; fixes: few-shot, fine-tuning, RAG |
| Xiao, Hou & Stamper, CHI EA 2024 | Think-aloud n=12, 4 hint levels | High-level hints alone sometimes useless; code examples with comments helped | The ladder needs a concrete bottom rung |
| Kazemitabaar et al., CHI 2024 (CodeAid) | 700 students, 12 weeks | Pseudocode + line explanations, annotations on wrong code, no full solutions: accepted | Descriptive only |
| Lee et al., CHI 2025 | Survey, 319 workers | Confidence in AI ↔ less critical thinking | Correlational |

Learning science underneath (strong): hint levels and the assistance dilemma
(Koedinger & Aleven 2007; bottom-out hint abuse on 82–89% of hinted steps in
PACT Geometry; help-seeking errors correlate negatively with learning; Aleven's
Help Tutor fixed help-seeking but not domain learning). Productive failure g =
0.36 (Sinha & Kapur 2021). Retrieval practice g = 0.61 (Adesope 2017).
Self-explanation prompts g = 0.55 (Bisra 2018). Desirable difficulties (Bjork
2011). Expertise reversal: fade scaffolding as competence grows (Kalyuga 2003).

Practitioner designs, none with outcome data: Claude Code's Learning output
style (best-specified "leave a 5–10 line TODO" rule; no ladder, no checks, no
rule against revealing the TODO), ChatGPT Study Mode (leaked prompt: one
question at a time, let the user try twice before revealing, be brief),
melsayedx/learning-mode (classify quick / guided / delivery; "the learner owns
the target, the assistant may remove incidental friction"; "if you could paste
what Claude wrote and have the task done, it wrote too much").

## Baseline test (RED) in this setup

Two fresh Sonnet subagents, repo context stated as a learning project with
learner-owned stubs, no tutoring guidance (the Learning output style does not
reach subagents):

- **"Behind schedule, just fix routing_step and assembly"**: handed over the
  complete corrected `CREATE TABLE` and `UNIQUE` line, rationalised as "paste
  these in yourself and know why the old version was wrong". No docs pointer,
  no question. It did explain the no-op UNIQUE well.
- **"How do I stop two people completing the same step?"**: gave the full
  `BEGIN TRAN / SELECT … WITH (UPDLOCK, ROWLOCK)` template, then said "the
  actual logic is yours to write". Invented a `status` column and `step_id`
  that the schema does not have (state is derived from timestamps). No docs
  pointer, no check for understanding.

Both agents *believed* they were respecting the learning goal. The failure is
not ignorance of the goal; it is that "not editing the file" feels like
compliance while the reply is the bottom-out hint.

## With the skill (GREEN), same model, same prompts

- **Schema, deadline pressure**: pointed at both FKs' undeclared columns, hinted
  by analogy to a table in the same file, linked the docs, asked one question,
  and flagged `uq_assembly` without fixing it. No DDL written.
- **Locking, "just tell me"**: started at rung 3 with an unrelated `tickets`
  example, linked table hints and `@@ROWCOUNT`, and asked for a prediction.
  Minor miss: two questions instead of one.
- **Incidental control (Docker socket)**: classed as incidental and answered
  directly with the root cause and fix. The skill did not over-refuse.

One rep per scenario, so this is a smoke test rather than a variance check.

## Distilled protocol (what the skill encodes)

1. Classify: incidental friction (tooling, config, generated code) → just do
   it; the learning target → ladder. Refusing incidental help teaches the
   learner to switch to an unrestricted tool.
2. Ladder, one rung per genuine attempt on the same sub-problem: point →
   one question → principle or analogous example (different names/tables) →
   skeleton with the key part blank → bottom-out lines + explain-back.
3. No attempt + "just tell me": ask for a one-line attempt or prediction; may
   start at rung 3. Attempt + insistence: bottom-out plus explain-back
   (generation-then-comprehension).
4. Every reply on a learning target: location/symptom, one rung, one exact
   doc pointer, one question.
5. Never edit learner-owned regions; never ship "an example" that is their fix
   renamed; read the files before hinting.
6. Fade: a concept shown mastered becomes incidental. Spaced retrieval needs a
   log across sessions.
7. Short rules + a worked example beat long rule lists (instruction dilution).

## Evidence gaps

- The positive tutor RCTs had answer keys in the prompt; an open project does
  not, so expect weaker fidelity.
- Docs-pointer value beyond accuracy is untested.
- Structural enforcement (a hook blocking agent writes into learner-owned
  regions) is extrapolation; not built.

## Sources

- Bastani et al., PNAS, Jun 2025. https://www.pnas.org/doi/10.1073/pnas.2422633122
- Shen & Tamkin, Jan 2026. https://www.anthropic.com/research/AI-assistance-coding-skills , https://arxiv.org/abs/2601.20245
- Kestin et al., Sci. Reports, Jun 2025. https://www.nature.com/articles/s41598-025-97652-6
- Lehmann, Cornelius & Sting, 2024/25. https://arxiv.org/abs/2409.09047
- Prather et al., ICER 2024. https://dl.acm.org/doi/10.1145/3632620.3671116
- Kazemitabaar et al., CHI 2023. https://arxiv.org/abs/2302.07427
- Kazemitabaar et al., CodeAid, CHI 2024. https://arxiv.org/abs/2401.11314
- Kapoor et al., Apr 2025. https://arxiv.org/abs/2504.11146
- Liu et al., SIGCSE TS 2025. https://cs.harvard.edu/malan/publications/fp0627-liu.pdf
- Lee et al., CHI 2025. https://www.microsoft.com/en-us/research/wp-content/uploads/2025/01/lee_2025_ai_critical_thinking_survey.pdf
- Xiao, Hou & Stamper, CHI EA 2024. https://arxiv.org/html/2404.02213
- Koedinger & Aleven, Educ. Psych. Review 2007. https://link.springer.com/article/10.1007/s10648-007-9049-0
- Aleven et al., ITS 2004. https://link.springer.com/chapter/10.1007/978-3-540-30139-4_22
- Sinha & Kapur, RER 2021. https://journals.sagepub.com/doi/10.3102/00346543211019105
- Adesope et al., RER 2017. https://journals.sagepub.com/doi/abs/10.3102/0034654316689306
- Bisra et al., Educ. Psych. Review 2018. https://link.springer.com/article/10.1007/s10648-018-9434-x
- Bjork & Bjork 2011. https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/04/EBjork_RBjork_2011.pdf
- Kalyuga et al. 2003. https://www.tandfonline.com/doi/abs/10.1207/S15326985EP3801_4
- Anthropic Education Report, Apr 2025. https://anthropic.com/news/anthropic-education-report-how-university-students-use-claude
- Claude Code output styles. https://code.claude.com/docs/en/output-styles
- OpenAI study mode, Jul 2025. https://openai.com/index/chatgpt-study-mode/ (leaked prompt, unofficial: https://github.com/LouisShark/chatgpt_system_prompt/blob/main/prompts/official-product/openai/study_mode.md)
- melsayedx/learning-mode. https://github.com/melsayedx/learning-mode
