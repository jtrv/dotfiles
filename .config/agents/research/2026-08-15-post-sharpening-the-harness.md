# Sharpening The Harness

*2026-08-15. Original: portfolio-v2 /blog/sharpening-the-harness. Converted from the site's TSX source; diagrams are referenced by name, not embedded.*

My first `CLAUDE.md` ran to roughly four hundred lines of wish-list instructions: be careful, write clean code, prefer readable solutions, always add tests. Every line was true, and I could not point to a decision the model made differently for having read them.

The global file is sixty-four lines now, backed by 1,321 lines of rules that load only when a task matches one of them, a `watches` directory of one-line probe scripts, and one gate command per repo. What follows is where those pieces came from, what I read afterwards, and the parts I am still unsure about.

## What worked

The single highest-leverage change was moving correctness out of the prompt and into a command. My instructions file no longer says “make sure the types are right.” It says: run `mise run check`, and do not tell me you are done until it is green.

> **Diagram — the-gate.** The gate this site ships with. Timings are this machine, warm, on a repo of this size; the whole run is 3.2 seconds.

That ordering is not an aesthetic preference. When an agent is iterating, feedback loop length is the thing you are optimising, and most failed attempts fail for a boring reason. Format and lint run first because they catch those in under half a second, with output that names the fix; the type check, the slowest step at 1.4 seconds, sees only work that has already cleared them. The order is not strictly by cost: the tests are the cheapest step here at 0.07 seconds and they still run last, behind the checks that can reject a patch before testing it is worth the trouble. At that speed the whole gate stays inside the iteration, and the case for the ordering grows with the codebase, since the type check is the step whose cost scales.

Two properties of this gate matter more than what is in it:

- *It is one command.* Not a README section listing five things to run. An agent that has to assemble its own verification procedure will assemble a different one each time, and the one it picks on a tired afternoon will be the short one.
- *It has no baseline file.* No ignore list of existing violations. A rule that does not fit this stack gets turned off in `.oxlintrc.json` with a written reason, which is a decision someone made and can defend. A list of grandfathered violations is debt made invisible, and an agent reads a passing gate as permission.

## Instructions cannot enforce anything

This is the distinction I got wrong for months. There are two completely different things that both look like “telling the model what to do”:

- *Context:* facts the model needs to decide well. Which package manager this repo uses. That TypeScript is pinned to 6, and why. That `ast-grep` is installed, so a structural rewrite need not go through regex and hand edits.
- *Enforcement:* things that must be true regardless of what the model decided. Formatting. Type safety. Coverage floors.

Enforcement written as prose is a suggestion with extra steps. It works most of the time, which is worse than not working, because the failures are the ones you stop checking for. Enforcement belongs in a hook, a gate, or a CI job, something that returns a non-zero exit code. Once I moved everything enforceable out of the instructions file, the file got much shorter and much more useful, because what was left was only the stuff a command could not express.

> A useful test for any line in a `CLAUDE.md`: could this be a failing exit code instead? If yes, make it one and delete the line.

## Where I started

Two YouTube channels got me to the point where the papers were worth reading. I want to be precise about what each was good for, because “watch these channels” is the same empty advice as “write a good instructions file.”

[Chase AI](https://www.youtube.com/@Chase-H-AI) is where I got the mechanics. Four ideas in particular, all four still load-bearing. The handle is `@Chase-H-AI`; a near-identical empty channel sits at the obvious name.

- *The loop is the unit of work,* not the prompt. Everything you tune is a property of the cycle the agent runs: how long an iteration takes, what it observes at the end of one, whether the next one starts from a known state. Seen that way, the gate stops being a chore bolted on at the end and becomes the observation step of the loop.
- *Gating is how a preference becomes a fact.* His version is stricter than anything I would have arrived at unprompted, and the refusal to grandfather existing violations is the part I would have talked myself out of.
- *Verbosity is a budget with two sides,* and I had been watching one. Input context is the side everyone talks about. Output tokens are the other, and each one is read back as input on every following turn until something compacts it away.
- *A skill you cannot measure is a skill you cannot improve.* This reframed my whole collection of them, and it gets its own section below.

The verbosity point produced two concrete changes. On the input side I run [context-mode](https://github.com/mksglu/context-mode), which does the work in a sandbox and returns only the derived answer, so a hundred-thousand-token log is read by a program and reaches the conversation as the four lines that matter. On the output side I run a `caveman` skill that strips articles, hedging and pleasantries from responses while leaving code, error strings and numbers untouched. Its own benchmark puts the saving at 65%, which is the skill's own figure and not one I have audited. What I can say from using it is that nothing technical goes missing, which tells you what the absent tokens were doing.

[Nate B Jones](https://www.youtube.com/@NateBJones) runs AI News & Strategy Daily, and is where I got the other half: what to do when the work does not fit in one session, and what a claim of done has to cite before anyone believes it. Less tooling, more judgement.

- *The workspace is authoritative and the transcript is not.* A long task keeps a ledger on disk, split by lifecycle: a `PLAN.md` of stable numbered steps that changes rarely, and a volatile cursor file, replaced in place, holding exactly one next executable action.
- *Handoff beats repeated compaction.* Compaction damage is mostly omission, and it surfaces three steps later as confident, coherent, wrong behaviour. A fresh session that reads a restart packet has no such failure mode.
- *A claim of done cites the state that makes it true.* An exit code, a diff, test output, a captured image. Asking a second model whether the work is finished is not verification, because a model asked to bless finished work tends to confirm it, and an agent over-claims hardest on the tasks it failed. This is the rule that decides when any gate counts, and it is the one I underrated longest.
- *Raise effort before raising the budget.* An agent that ran out never gets the same configuration and a larger number; it gets more reasoning effort, a higher model tier, a smaller task, or a different plan.
- *Subagents are context quarantine before they are parallelism.* Noisy work goes out of the main window and only conclusions come back. Anything small enough to read inline is cheaper inline, and the default pull is to over-delegate.
- *Parallel agents on one tree need a lease, not etiquette.* One agent running `git stash` sweeps every other agent's uncommitted edits out of the tree they are working in and into one stash entry under its name, so each brief forbids tree-wide git state changes and a pristine baseline means a separate worktree.

Neither channel is a substitute for the primary sources, and neither claims to be. They are good at what primary sources are worst at, which is telling you what a result means on a Tuesday when you have work to ship. I went to the papers next because these two handed me questions worth taking there.

## What I found

Anthropic's own [best practices for agentic coding](https://code.claude.com/docs/en/best-practices) (April 2025, since folded into the docs) is where I got the pruning test I still use on every line of an instructions file: *would removing this cause Claude to make mistakes?* The same document is blunt about the constraint underneath it. The context window is the most important resource to manage, and performance degrades as it fills. That is the sentence that made me delete three hundred lines.

[Building Effective AI Agents](https://www.anthropic.com/engineering/building-effective-agents) (Schluntz and Zhang, December 2024) is the one I recommend to people who are about to adopt an agent framework. Their finding was that the most successful implementations they saw weren't using complex frameworks. They were built from simple, composable patterns, many of them a few lines of code. That is why my setup is a shell script and a TOML file instead of an orchestration layer.

[Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (September 2025) gave me the idea I stole most directly: just-in-time retrieval. Keep lightweight identifiers in context, such as file paths and queries, and load the actual content at runtime when it is needed. I copied that structure directly.

[Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) (September 2025) is about tool design rather than instruction files, but it carries the verbosity lesson with a number attached: switching a Slack tool to a concise response format cut token consumption roughly threefold, 206 tokens down to 72.

And [how we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (June 2025) has the finding I think about most: on their BrowseComp evaluation, token usage by itself explained 80% of the variance in performance. Number of tool calls and model choice accounted for most of what was left.

## The research underneath it

The blog posts above all lean on the same underlying result, and it is worth reading in the original because the effect is stronger than the summaries suggest.

[Lost in the Middle](https://arxiv.org/abs/2307.03172) (Liu et al., 2023) is the early one: performance is highest when the relevant information sits at the beginning or end of the context, and degrades significantly when the model has to reach into the middle. If you have ever watched an agent ignore a constraint you stated forty messages ago, that is the shape of it.

The more recent and more uncomfortable one is Chroma's [Context Rot](https://www.trychroma.com/research/context-rot) (Hong, Troynikov and Huber, July 2025). They evaluated 18 models across the GPT, Claude, Gemini and Qwen families and found that models do not use their context uniformly: performance degrades as input length grows even on tasks that are trivially simple. The number that stuck with me is from their LongMemEval runs, where focused prompts of roughly 300 tokens beat full prompts of roughly 113,000 tokens across every model family tested. A single distracting passage measurably hurt; four of them compounded.

A long instructions file is a distractor you wrote yourself and then attached to every request you will ever make.

## What counts as green

Shortening the instructions settles what goes into the loop. It says nothing about what should be allowed to end one. For a long time “the gate passed” was the whole of verification for me, and the gate only knows about types, lint and unit tests. I use three forms of evidence now. Chase's gating material suggested their shape, Nate's supplied the standard they have to meet, and they fail in different ways, which is why all three stay.

- *The test comes before the code.* An agent asked to add tests will write tests that pass against the code it has just produced, which demonstrates that it can read its own output and nothing else. Write the assertion first and run it while it still fails. The red state is what proves the test is wired to the thing it claims to check, and once it exists the agent has an exit condition it cannot talk its way around.
- *Give every number a threshold.* A printed number is a dashboard. Compared against a limit, the same number becomes an exit code. Coverage here is gated at 90% of lines and functions across `src/lib` and `src/data`, where the code currently sits at 100. Take the comparison away and the reading survives only as long as I remember to check it.
- *Look at the pixels.* Layout, contrast and spacing survive every check above and still come out wrong. `mise run shots` renders the real pages headless and writes PNGs that get read, one by one, before any UI change is called done. Every capture asserts the state its name claims before it fires, so a shot of an empty box fails as an assertion rather than arriving as a picture nobody questioned.

The captures sit outside the gate on purpose. They are gitignored review artifacts, judged by a person; a green capture run proves the pages rendered and stops there. That division is why the rule about citing state carries more weight than any single check. Evidence for a claim has to be something you can point at, and for a UI change the thing you point at is the image.

## What the setup is

Six things, and only the first two are prose.

```
1. CLAUDE.md          64 lines no command can express
2. contexts/*.md      1,321 lines, loaded on demand
3. mise config        every runnable command as a task
4. tasks/check        the gate, one exit code
5. watches/*.sh       one probe per deferred decision
6. memory/*.md        one fact per file, indexed
```

The global file is an index with trigger conditions, not a rulebook. It names ten context files and says when each one applies, and the instruction attached is to read the file rather than proceed on memory of it. Rust rules cost nothing on a TypeScript afternoon. What stays global is the handful of things that hold everywhere and that no repo can teach: which tools are installed and which generic default each one replaces, that commits never get a co-authorship trailer, that a command I have to run myself should also land on my clipboard.

The mise line is quiet and pays off constantly. When every command is `mise run <task>`, there is exactly one correct way to build, test, format and deploy, and it is discoverable by listing tasks. Before that, the model would reconstruct commands from `package.json` scripts, from the README, or from memory of a similar project. Those three sources drift apart the moment one of them changes. Anything longer than a line or two is an executable file at `.config/mise/tasks/<name>` rather than a string in the TOML, and the filename is the task name. The file also runs on its own with mise absent, so a `package.json` script, a CI step and `mise run` all reach the same bytes.

The `watches` directory is the newest piece and the one I would least have predicted. A deferred adoption — revisit TypeScript 7 at 7.1, relax the exact `oxfmt` pin once it ships 1.0 — used to live in a comment, which meant it lived nowhere. The note never fired, and re-establishing the answer cost a browser session every time it came up. Each one is now a script that prints a single line.

```
$ sh ~/.config/claude/watches/oxfmt.sh
NOT-READY: oxfmt 0.65.0 still pre-1.0 — keep the exact pin
```

Three outcomes, `NOT-READY`, `CHECK` and `UNKNOWN`, and the rule is to run the probe before re-researching the topic and to investigate only on `CHECK`. It is the same move as the gate, pointed at a judgement about timing rather than about code: what would have been an argument is now a command that answers in one line.

## Observable skills

A watch is easy to keep because its answer is observable. Skills are the harder version of the same problem. For a while mine grew the way a bookmarks folder grows: I added things because a video made them look good, and the honest accounting was that I did not know which ones earned their place. A skill is worse than a script in this respect: a script nobody calls is inert, while a skill that fires on the wrong task takes the wheel.

What made this tractable was noticing that a skill has two measurable properties.

- *Does it fire when it should?* That is a property of its description alone, and it is testable with a set of prompts that must trigger it and a set that must not.
- *Does the work come out better when it does?* That needs the same task run with the skill and without, scored on something that already exists. If a skill claims to make a gate pass more often, gate exit codes are the score.

Both numbers move a skill out of taste and into the loop. One with a triggering score can be edited until the score goes up. One whose effect on a gate is zero can be deleted without an argument. The tooling behind that is a couple of prompt sets and a scoring script. What the scores exposed is that unmeasured additions compound in exactly the direction the context-rot research warns about, and every one of them arrived feeling like an improvement.

## What is actually installed

Sort these by who wrote them rather than by what they do, and the question of who owes the evidence sorts itself at the same time.

Off the shelf: [context-mode](https://github.com/mksglu/context-mode) and the [Codex](https://github.com/openai/codex-plugin-cc) plugin, both already doing work above; [ponytail](https://github.com/DietrichGebert/ponytail), which pushes every answer toward the smallest thing that works and publishes benchmark medians for it — across five tasks and three models, 6–20% of the no-skill line count and 23–53% of the cost; `caveman`, whose 65% I have already flagged as unaudited; and `graphify`, for the questions about a codebase that are really questions about relationships. Ponytail is the one I would hold up as an example: it refuses to print a per-repo saving at all, on the grounds that the version it talked you out of writing was never written, so there is no baseline to subtract from.

The ones I wrote are where the actual opinions live.

- *plan-refute* hands a claim, the repo and a kill mandate to a model from another family, and withholds my reasoning for it, because agreement between two models that read the same argument is not evidence. It paid for itself on the companion post to this one, where I had written that nobody measures how far an agent's output degrades as it extends its own work. The refuter came back with a benchmark that measures exactly that, and the section got rewritten around being wrong.
- *geiger* audits structure rather than lines — import cycles, layering violations, churn hotspots — and splits the job the way the dependency-graph work does: the script detects, I judge, and neither re-derives what the other already has. Its findings can come back out as a CI rule, which is the shape this whole post keeps reaching for.
- *handoff* and *grind* are the compaction research turned into procedure: a restart packet written before the window degrades, and a queue worked one fresh context at a time.
- *unslop* is two prose linters over everything this site publishes, in CI rather than the gate, because a seven-sentence paragraph is not a broken build and one contributor means no second reader.
- *grilling* interviews me about a plan before any of it is built, one question at a time, each with its recommended answer.

The last one is a status bar. Every turn, starship renders where the work is, the git state, which model is answering and in what mode, the weekly and five-hour limits, context percentage and the size of the diff so far. Colour carries role rather than decoration, and nothing in it is green, because a second everything-is-fine colour buys no information. It is the cheapest instrument here and the one I look at most: the numbers that decide whether to start something big are on screen before I start it.

What none of them have is a measurement in this repo. A method with a citation behind it and a method with a number behind it are different things, and only the second can tell me whether the thing is working here, on my code, this month.

## The parts I am least sure of

A post that only lists wins is marketing, so here are the three I would have the most trouble defending.

- The comment policy in my instructions file runs to a paragraph on what earns a comment and a list of what never does. The comments it produces are better, and it is still prose doing a job I have found no way to make mechanical, which by the argument above makes it suspect.
- The rule about a dispatch a safety classifier refused — one honestly reworded retry, then do the task inline or park it for me — is the one line in the file I cannot attach a measurement to. I keep it because the alternative it forbids is a habit I would rather not find out I had.
- My context files are drifting toward the four-hundred-line problem one level down. The TypeScript one is 322 lines. It only loads when I am writing TypeScript, which is the whole design, and it is still the longest thing any session of mine reads.

None of that unsettles the method, because the method is what put those three under suspicion in the first place. Write down only what the model cannot infer. Turn everything else into a command that exits non-zero. Then measure whatever you add next, before it earns a permanent seat in the context window — which is the part I got to last, and the part that decides whether any of the rest is still true a year from now.
