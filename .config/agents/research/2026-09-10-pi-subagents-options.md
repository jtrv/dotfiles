# Pi delegation: recommendation and evidence

Research date: 2026-09-10. Requested compatibility target: Pi 0.84.4.

## Executive recommendation

Pilot **`@tintinweb/pi-subagents@0.19.0` for ordinary Pi delegation, bounded search, and scripted workflows**, but use a **small, separate fresh-process launcher for blind refuters and Codex-tier workers**. This is a recommendation to evaluate a pinned package, not certification for unrestricted production use. Tintinweb has a relatively coherent feature set, recent releases, tests, and a peer range covering 0.84.4; its source also reveals defaults and worktree behavior that conflict with your stricter workflows. Keep `grind` sequential unless the supervisor has successfully provisioned separate worktrees, and require workers to run gates and make their own scoped commits. Do not substitute the package's automatic commit for that contract. `pi-subagents` is the strongest richer alternative, including an external Codex adapter and durable execution machinery, but its latest release has compatibility and tool-discovery questions that warrant a separate pilot. The ecosystem is useful enough not to rewrite orchestration wholesale; the narrow independence/CLI boundary is worth owning.

## Scope and verification limits

I read the installed Pi usage, extension, and bundled subagent-example material, your `plan-refute` and `grind` skills, and the versioned upstream 0.84.4 documentation. **The installed package at the supplied path reports 0.85.1, not 0.84.4.** I made no installation or configuration changes. Compatibility below distinguishes source/manifest evidence from execution: no candidate was installed, authenticated, or runtime-tested.

Direct npm verification was attempted for all named packages through registry metadata endpoints, plus the ecosystem search endpoint and download endpoints. Those requests were unavailable through this environment's web fetcher; shell network requests also failed DNS. Consequently, **the versions, publication dates, and weekly download figures below are Pi catalog observations, not independently verified npm-registry measurements**. GitHub manifests and source provide a separate cross-check where available. This is a material gap against the requested registry verification, not evidence that packages are missing. In particular, a catalog listing is not proof that the tarball matches the inspected source.

Sources were accessed through a web index/cache with differing crawl times. Mutable branches sometimes lag catalog releases. I used an exact tag for the recommended tintinweb release, and identify mismatches for other finalists. Download figures measure distribution, not unique users or successful deployments. Release activity, tests, and issue examples support a maintenance assessment; they do not establish a support SLA or a bus factor greater than one.

Pi explicitly leaves subagents and background execution to extensions. Its documented extension API supports the necessary tools, events, messages, and state entries; it does not supply durable process supervision automatically. [Pi 0.84.4 usage](https://raw.githubusercontent.com/earendil-works/pi/v0.84.4/packages/coding-agent/docs/usage.md), [extension API](https://raw.githubusercontent.com/earendil-works/pi/v0.84.4/packages/coding-agent/docs/extensions.md).

## Ranked shortlist

“Fresh” below means a separate model conversation; it does **not** mean a filesystem sandbox. “Background” and “survives reload” are separate properties.

| Rank / option | Context and result path | Models / external CLI | Background and reload | Workflows / worktrees | Assessment for your use |
|---|---|---|---|---|---|
| **1. `@tintinweb/pi-subagents` 0.19.0** | Separate in-process Pi sessions; fresh task or optional textual parent-context projection; result text, task handles, notifications | Native Pi model selection; no dedicated external-CLI adapter established | Background completion supported; shutdown/reload aborts active work | Built-in scripted parallel/pipeline orchestration; worktree helper has unsafe fallback for your contract | Best bounded parity pilot; custom clean roles, no mentions for refuters, externally provision writer worktrees |
| **2. `pi-subagents` 0.67.0** | Fresh or filtered session fork; own child sessions; structured/artifact results | Native Pi models and documented `codex-exec` profiles; four-tier override not verified | Detached runner and recovery machinery; foreground sessions disposed on shutdown | Scripted workflows, gates, worktrees, substantial result/provenance system | Broadest one-package alternative; greater complexity and current-version uncertainty |
| **3. `@gotgenes/pi-subagents` 21.5.x** | Separate in-process sessions; optional textual parent-context projection; typed service and joins | Native Pi providers; external CLI adapter not established | Background and parent notifications; active sessions aborted/disposed on shutdown | Composable service; worktrees are a separate package | Focused core, but several pieces needed for full parity; ambient inheritance needs care |
| **Narrow custom launcher** | Fresh OS process, explicit task packet, bounded final result | Explicit Pi provider/model or exact `codex exec -m` tier | Foreground simple; durable background is additional engineering | Small fixed fan-out/sequence; supervisor-created worktrees | Best boundary for blind review and existing Codex routing; not a free replacement for the entire package |

These rankings weight fit and inspectability, not download rank. No finalist earns an unconditional pass for “must never see parent reasoning”: accessible files and prompt construction must also be controlled.

### 1. Tintinweb: useful parity, with meaningful exceptions

**Isolation and prompts.** The runner calls `createAgentSession`, using a separate session manager inside the parent process. The task is supplied to that session. With inheritance enabled, `buildParentContext` prepends a projection of user/assistant text and compaction summaries; tool results are skipped. This is **not a full-fidelity fork**. An append-mode role can inherit the parent's system prompt even without conversational inheritance. Isolated mode suppresses extensions and skills; resource loading suppresses automatic context files. For clean work, explicitly replace the system prompt, disable ambient extensions/skills, and disable inheritance. [Tagged runner](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/agent-runner.ts), [context projection](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/context.ts).

**Do not use `@agent` dispatch for blind refutation.** The default model-mediated mention path uses parent conversation to formulate delegation. A fresh destination cannot undo a contaminated brief. Use a separate launcher whose input excludes planner rationale. The built-in Explore role also includes `bash`; its read-only description is not a write-prevention mechanism. Use an explicit read/search tool allowlist instead. [README](https://github.com/tintinweb/pi-subagents), [default roles](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/default-agents.ts), [inheritance issue #300](https://github.com/tintinweb/pi-subagents/issues/300).

**Worktrees are not fail-closed.** In tagged `src/worktree.ts`, creation catches failures and returns `undefined`, permitting execution in the normal cwd. Cleanup stages all changes and commits with `--no-verify`; error cleanup attempts forced worktree removal. These are source findings, not reproduced incidents. They make this helper unsuitable as the enforcement boundary for your parallel writers or worker-owned verification/commit requirement. Provision worktrees outside it, verify cwd before dispatch, and retain failed worktrees for diagnosis. [Tagged worktree implementation, especially lines 78–108 and 115–175](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/worktree.ts).

**Execution and lifecycle.** Its workflow facility offers scripted `agent`, `parallel`, and `pipeline` composition with controlled orchestration. Deterministic sequencing does not make LLM outputs deterministic. Foreground execution returns results; background execution supplies handles and later completion/result retrieval. The shutdown handler aborts/disposes active agents and workflows, so saved settings/transcripts are not continued execution across `/reload`. Treat reload as cancellation, not a background-resume feature. [Workflow documentation](https://github.com/tintinweb/pi-subagents#readme), [extension lifecycle source](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/index.ts).

**Compatibility and maintenance.** Version 0.19.0 declares Pi coding-agent/AI/TUI peers `>=0.84.0`, develops against 0.84.2, and registers `./src/index.ts` in its `pi.extensions` manifest. It has Vitest, typecheck and other verification scripts. Releases 0.17.1, 0.18.0, 0.18.1, 0.18.2 and 0.19.0 appeared August 18–27. That is positive API-tracking evidence, not a tested 0.84.4 guarantee. [Manifest](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/package.json), [releases](https://github.com/tintinweb/pi-subagents/releases).

Issue #242 documents a child-extension lifecycle leak and is closed, supporting responsiveness to a real integration problem. Conversely, #276 reports a macOS `/agents` crash with package 0.19.0 and Pi 0.84.4 and was unresolved in the accessed snapshot; it is labeled as not reproduced, so it is not proof of a general defect. Reload and limit-related requests remain relevant. There is no measured median response time or demonstrated multi-maintainer continuity here. [#242](https://github.com/tintinweb/pi-subagents/issues/242), [#276](https://github.com/tintinweb/pi-subagents/issues/276), [#294](https://github.com/tintinweb/pi-subagents/issues/294), [#285](https://github.com/tintinweb/pi-subagents/issues/285).

### 2. Nico's `pi-subagents`: most complete alternative, larger commitment

**Context.** Native children use separate Pi SDK sessions. Foreground sessions live in the extension process; background sessions run under a detached runner. The workflow documentation distinguishes fresh and fork modes. Worker/oracle/advisor defaults can fork an existing persisted session, falling back to fresh when unavailable. Fork filtering removes parent-only orchestration artifacts, not ordinary planner prose. Therefore explicitly request fresh mode for independent reviewers; default roles are not blind by construction. [Workflow/context documentation](https://github.com/nicobailon/pi-subagents/blob/main/docs/workflows.md), [child-session source](https://raw.githubusercontent.com/nicobailon/pi-subagents/main/src/runs/shared/child-session.ts).

**External execution.** The documented `codex-exec` and `codex-exec-writer` profiles use an installed, authenticated Codex CLI with read-only or workspace-write policy, ephemeral execution, and final-result artifacts. Native Pi model overrides are not automatically external-adapter options. I could not verify from the adapter source that the package exposes all four requested `-m` choices; do not assume it does. This is nevertheless a more direct external-CLI facility than a Pi child improvising a shell invocation. [Agent/adapter documentation](https://github.com/nicobailon/pi-subagents/blob/main/docs/agents.md).

**Orchestration and persistence.** The package supports scripted runs, parallel groups, lanes, worktrees and host verification gates. It distinguishes model assertions from stronger evidence in its result contract. Startup/reload/resume handling reconstructs state; detached children are handled differently from disposed foreground children. This is credible source evidence of recovery infrastructure, not an executed guarantee that every notification survives every crash. Results include inspectable artifacts as well as parent-facing output. [Tool reference](https://github.com/nicobailon/pi-subagents/blob/main/docs/tool-reference.md), [observability](https://github.com/nicobailon/pi-subagents/blob/main/docs/observability.md), [lifecycle](https://raw.githubusercontent.com/nicobailon/pi-subagents/main/src/extension/index.ts).

**Compatibility risk.** Inspected main declares 0.67.0, extensions plus skills/prompts, permissive optional Pi peers, and a dependency on `@earendil-works/pi-server` 0.85.0. Tests include unit/integration scripts, but broad peer ranges do not prove compatibility with 0.84.4. SDK/runtime/resource-loader coupling is appreciably larger than a subprocess launcher. The changelog shows 0.66.0 September 6 and 0.67.0 September 10: active, but moving quickly. [Manifest](https://raw.githubusercontent.com/nicobailon/pi-subagents/main/package.json), [changelog](https://github.com/nicobailon/pi-subagents/blob/main/CHANGELOG.md).

New September 10 issues describe child tool-discovery/pruning problems involving overridden built-ins and extension tools. These are reports, not independently reproduced bugs; their relevance is precisely your shared, customized configuration. Pilot with the actual extensions, not an empty installation. Popularity does not settle this risk, and the project still presents lead-maintainer concentration. [#2133](https://github.com/nicobailon/pi-subagents/issues/2133), [#2134](https://github.com/nicobailon/pi-subagents/issues/2134), [#2135](https://github.com/nicobailon/pi-subagents/issues/2135).

### 3. Gotgenes: composable core, not a drop-in equivalent to current tintinweb

The former repository moved to `gotgenes/pi-packages`. Its published catalog version is 21.5.1; the fetched package manifest reports **21.5.0**, so this is not an exact published-artifact audit. The manifest registers `./src/index.ts`, requires coding-agent `>=0.81.0` and AI/TUI `>=0.75.0`, develops against Pi 0.84.4, requires Node 22+, and includes Vitest/typecheck scripts. The changelog shows repeated September releases and integration fixes. These are encouraging signals, with residual single-maintainer and rapid-change risk. [Current package](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-subagents), [manifest](https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-subagents/package.json), [changelog](https://github.com/gotgenes/pi-packages/blob/main/packages/pi-subagents/CHANGELOG.md).

A child gets its own SDK session and task; an optional parent snapshot supplies text context. The context builder retains user/assistant text and compaction summaries rather than complete tool history. Session construction can inherit ambient extensions/skills and append the parent system prompt, so disabling transcript inheritance alone is insufficient for your refuter. Provider/model state is carried into the child runtime; no general external-CLI runner was established. [Session creation](https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-subagents/src/lifecycle/create-subagent-session.ts), [snapshot](https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-subagents/src/lifecycle/parent-snapshot.ts), [context builder](https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-subagents/src/session/context.ts).

The typed service supports spawn/join and parent communication; background agents can notify or ask the parent. Shutdown aborts/disposes live sessions rather than preserving execution. Worktrees are split into a companion package, and the core does not provide the same built-in workflow suite as tintinweb. Its upstream-comparison document compares older versions and should not be read as a current feature ranking. [Service](https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-subagents/src/service/service.ts), [entrypoint](https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-subagents/src/index.ts), [comparison document](https://github.com/gotgenes/pi-packages/blob/main/packages/pi-subagents/docs/comparison-with-upstream.md).

## Full candidate screening and maintenance signals

Dates and weekly downloads in this table come from the linked **Pi catalog**, with the registry-verification limitation above. Dates are 2026. “Not selected” means poorer fit for this request, not defective software. README-only capabilities have not received the finalists' source-level scrutiny.

| Package / catalog | Version; latest date; weekly downloads | GitHub evidence and disposition |
|---|---|---|
| [`@tintinweb/pi-subagents`](https://pi.dev/packages/@tintinweb/pi-subagents) | 0.19.0; Aug 27; 6,458 | [Repository](https://github.com/tintinweb/pi-subagents). First pilot; tagged source and tests inspected. |
| [`pi-subagents`](https://pi.dev/packages/pi-subagents) | 0.67.0; Sep 10; 116.4K | [Repository](https://github.com/nicobailon/pi-subagents). Largest observed distribution; extensive machinery and active issues. |
| [`@gotgenes/pi-subagents`](https://pi.dev/packages/@gotgenes/pi-subagents) | 21.5.1; Sep 10; 4,117 | [Current monorepo](https://github.com/gotgenes/pi-packages). Independent fork; current source location matters. |
| [`@henryqw/pi-subagent`](https://pi.dev/packages/@henryqw/pi-subagent) | 15.0.2; Sep 7; 5,305 | [pi-harness](https://github.com/HenryQW/pi-harness). Fresh ephemeral sessions, bounded delegation/flows, required task-model routing companion; reload aborts work. Promising but more opinionated than the shortlist. |
| [`@ferris1225/pi-subagents`](https://pi.dev/packages/@ferris1225/pi-subagents) | 4.3.17; Sep 7; 2,217 | [Repository](https://github.com/MCapricorns/pi-subagents). Fresh Pi RPC children and worktrees; requires **Pi >=0.85.0**. Documented child policy forbids commits, conflicting with `grind`. |
| [`@arhen/pi-core-subagent`](https://pi.dev/packages/@arhen/pi-core-subagent) | 1.3.54; Sep 10; 521 | [pi-extensions](https://github.com/arhen/pi-extensions). Single/parallel/DAG and mailbox machinery. Dependency edges transmit upstream output; do not feed planner reasoning to a refuter through such edges. Not deeply audited. |
| [`pi-background-tasks`](https://pi.dev/packages/pi-background-tasks) | 2.5.0; Sep 4; 26.6K | [Repository](https://github.com/ismailsaleekh/pi-background-tasks). Useful durable shell-job add-on. Its delegated inspection path uses a frozen current-conversation projection: not a blind refuter. Fixed review/merge machinery is not general worker orchestration. |
| [`@quintinshaw/pi-dynamic-workflows`](https://pi.dev/packages/@quintinshaw/pi-dynamic-workflows) | 3.10.1; Sep 3; 5,365 | [Repository](https://github.com/QuintinShaw/pi-dynamic-workflows). Scripted workflows, journals, worktrees and resume. Consider only if workflow durability becomes the central requirement; avoid duplicating orchestrators. |
| [`pi-fabric`](https://pi.dev/packages/pi-fabric) | 0.92.4; Sep 9; 5,621 | [Repository](https://github.com/monotykamary/pi-fabric). Full code-mode/actor/mesh runtime; catalog 15 dependencies and 9.4 MB. Too broad for this requirement. Guest-code sandboxing does not imply host-tool confinement. |
| [`@agwab/pi-workflow`](https://pi.dev/packages/@agwab/pi-workflow) | 0.13.8; Sep 7; 2,892 | [Repository](https://github.com/AgwaB/pi-workflow). Persisted named workflows with another subagent layer; catalog 50.2 MB. Larger operational commitment than a bounded dispatcher. |
| [`pi-claude-bridge`](https://pi.dev/packages/pi-claude-bridge) | 0.7.0; Aug 9; 9,001 | [Repository](https://github.com/elidickinson/pi-claude-bridge). Claude SDK/provider bridge, not upstream Anthropic's package. Exclude under your named-upstream rule. |
| [`@fractaal/pi-claude-bridge`](https://pi.dev/packages/%40fractaal/pi-claude-bridge?page=7) | 1.6.8; Aug 16; 231 | [Manifest/source](https://raw.githubusercontent.com/fractaal/pi-extensions/main/packages/claude-bridge/package.json). Same policy exclusion; broad peers but development uses a Pi fork. Tests exist; provider bridging is not itself orchestration. |
| [`pi-goal-x`](https://pi.dev/packages/pi-goal-x) | 0.31.2; Sep 8; 18.9K | [Repository](https://github.com/tmonk/pi-goal-x). Persistent goals and optional auditing; continuing a goal does not establish fresh worker-per-task semantics. |
| [`pi-harness-runtime`](https://pi.dev/packages/pi-harness-runtime) | 1.1.50; Sep 2; 3,547 | [Repository](https://github.com/ManotLuijiu/pi-harness-runtime). Explicit beta/runtime expansion; unsuitable as the smallest stable delegation layer. |
| [`pi-agent-suite`](https://pi.dev/packages/pi-agent-suite) | 2.10.0; Sep 8; 460 | [Repository](https://github.com/n-r-w/pi-agent-suite). Broad suite touching prompts, UI, model accounting and workflows. Excess scope for one shared config; catalog license metadata was unclear. |

Additional discovery did not displace the shortlist: [`@mjakl/pi-subagent`](https://github.com/mjakl/pi-subagent) is a narrower subprocess option, and [`pi-agents-pool`](https://github.com/minghinmatthewlam/pi-subagents) exposes a small Pi-RPC agent-pool interface. Neither received enough source/release verification here to recommend over the finalists. The **bundled Pi subagent example** is the most relevant starting point for a custom launcher, because it avoids introducing an unrelated framework.

For the long tail, I verified repository/catalog presence and screened documentation; I did **not** establish issue-response statistics, tested compatibility, or test coverage for every package. Recent publication across this table indicates an active ecosystem, not uniform maturity. Do not infer a maintenance winner from semver numbers across independent projects.

## What the evidence supports

### Fresh orchestrator–worker sessions: useful for separable work, not a universal default

Anthropic's multi-agent research system reported a **90.2% relative improvement** over its single-agent research baseline using an Opus lead and Sonnet workers. The work concerns research, uses a vendor's internal evaluation, and does not isolate orchestration from model/token-budget changes. The post reports roughly 15 times chat token use for multi-agent systems versus roughly four times for individual agents—**not 15 times a comparable single coding agent**. Its strongest transferable lesson is bounded, parallel information gathering with compressed results, not unrestricted coding swarms. [Anthropic engineering, June 2025](https://www.anthropic.com/engineering/multi-agent-research-system).

Kim et al.'s *Towards a Science of Scaling Agent Systems*, revision 3 (April 2026), evaluates 260 configurations across six benchmarks, five architectures and three model families with standardized components. It finds sharply task-dependent outcomes, including gains on decomposable tasks and losses on sequential ones. Its predictive model is useful but incomplete, not a universal dispatch formula. This supports choosing topology by dependency structure and measuring total cost/latency, rather than assuming more workers improve results. [Paper, version 3](https://arxiv.org/abs/2512.08296v3).

**Recommendation derived from these results:** start with two independent Explore tasks returning file/line evidence and conclusions. Keep tightly coupled implementation on one strong worker unless there is a concrete separable boundary. Parent synthesis should retain uncertainty and evidence references rather than merely vote across confident summaries.

### Forked context: a different tool for a different task

Forking preserves decisions, tool evidence and constraints that are expensive to reconstruct; it also preserves mistakes and anchoring. Cognition's *Don't Build Multi-Agents* argues from engineering experience that context fragmentation and coordination are major hazards. That is a valuable counterexample to universal fresh-context advice, but not a controlled benchmark proving forks always win. [Cognition engineering essay](https://cognition.com/blog/dont-build-multi-agents).

Use forks for continuing closely related implementation, not for an independent verdict. Distinguish an actual serialized session fork from a textual recap: tintinweb and gotgenes inheritance omit tool-result history; Nico's fork deliberately filters some material. Neither “inherit context” nor “fork” should be accepted as a promise that every parent event, image, reasoning field and tool result reaches the child unchanged. Provider/harness representations also constrain what can be replayed.

### Independent reviewers, debate and self-consistency

Du et al.'s multi-agent debate work finds benefits on reasoning/factual tasks by letting agents propose answers and then exchange arguments. Once that exchange begins, agents are no longer blind. It supports a possible **second-stage deliberation**, not exposing your refuter to the planner before its first assessment. [Debate paper](https://arxiv.org/abs/2305.14325).

Wang et al.'s self-consistency work samples multiple reasoning paths and aggregates answers, with substantial improvements on mathematical/commonsense benchmarks. That is evidence for sampling diversity under suitable answer structure, not evidence that multiple named coding personas independently verify software. [Self-consistency paper](https://arxiv.org/abs/2203.11171).

Zheng et al.'s LLM-as-judge study documents position, verbosity and self-enhancement biases alongside strong agreement with human preferences in its setting. Preference agreement is not code correctness. For your review workflow, obtain the initial verdict without the planner's rationale, anonymize competing outputs where practical, and ground adjudication in source and executed checks. [MT-Bench/Chatbot Arena judge paper](https://arxiv.org/abs/2306.05685).

**Important distinction:** fresh sessions remove conversational contamination; they do not make model errors statistically independent. Four Codex tiers remain within one model family. Sending Pi's OpenAI-backed work to Codex diversifies harness execution, not necessarily the underlying model. Without another ready provider/authenticated CLI, genuine cross-family review is unavailable; do not silently request Anthropic models that Pi cannot authenticate.

### Parallel writes, merge and verification

Anthropic's compiler project demonstrated sustained parallel coding with 16 agents, separate containers/clones, task coordination and extensive tests. It also encountered workers converging on the same bottleneck, requiring better task partitioning and a compiler oracle. This is a substantial capability demonstration, not a controlled finding that its roughly $20,000 run was cheaper or better than a single-agent alternative. Its relevant lesson is the importance of verifiable, separable work and integration feedback. [Compiler engineering report, February 2026](https://www.anthropic.com/engineering/building-c-compiler).

Git worktrees prevent accidental shared-index/file collisions; they do not solve semantic merge conflicts, shared external services, common generated assets, or incorrect patches. A supervisor must establish a base commit, partition ownership, collect child commits, integrate deliberately and rerun the combined gate. “Each branch passed” is insufficient evidence that the merged result passes.

Cemri et al.'s MAST analysis covers more than 1,600 traces across seven frameworks, identifying failures in system design, inter-agent alignment and verification. It supports explicit task contracts, termination conditions and external checks; adding reviewers without fixing orchestration can multiply failure modes. [MAST paper, version 3](https://arxiv.org/abs/2503.13657v3).

Agentless demonstrates that a comparatively simple localization/repair/validation pipeline can compete with more elaborate coding systems in its historical SWE-bench Lite setting. Its results are not a current leaderboard claim or a clean single-versus-multi-agent ablation. It is good evidence against complexity as a proxy for capability. [Agentless paper](https://arxiv.org/abs/2407.01489).

### Current practitioner direction—and its limits

Official Claude Code documentation presents scoped subagents and worktree isolation; Codex documentation emphasizes bounded delegation, read-heavy parallel work and caution around conflicting edits; OpenCode documents specialized agents including exploration. These establish available design patterns, not measured industry consensus. [Claude subagents](https://code.claude.com/docs/en/sub-agents), [Claude worktrees](https://code.claude.com/docs/en/worktrees), [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents), [OpenCode agents](https://opencode.ai/docs/agents/).

Pi's deliberate minimal core coexists with requests for native isolated subagents and several actively released third-party implementations. That is evidence of demand and competing designs, not an upstream commitment to adopt one. Package issues increasingly concern inheritance, reload, tool propagation and provider fidelity—the hard integration edges rather than just spawning another model. [Pi issue #7412](https://github.com/earendil-works/pi/issues/7412), [tintinweb issues](https://github.com/tintinweb/pi-subagents/issues), [Nico issues](https://github.com/nicobailon/pi-subagents/issues).

A recent Hacker News discussion of Pi's minimalism contains opposing firsthand accounts: some prefer a strong agent without delegation overhead; others value cheaper workers or isolated browser tasks. These are useful anecdotes, not representative measurements. “Cheap workers always save money” conflicts with coordination/token overhead evidence; “subagents are unnecessary” overgeneralizes from tightly coupled tasks to parallel research. [HN discussion](https://news.ycombinator.com/item?id=49176038).

**X limitation:** searches surfaced indirect references, but primary X posts were not reliably retrievable. I do not claim a verified X consensus or attribute statements based on mirrors. No defensible cross-community numerical sentiment estimate is available from this research.

## The minimal extension option, assessed honestly

Pi's installed official example already spawns a child with `--mode json -p --no-session`, passes an explicit task, parses messages, limits concurrency, and returns final output. It also appends role prompts and does not disable all ambient resources. It is a useful implementation reference, **not a ready-made blind-review boundary**. Local source inspected: `examples/extensions/subagent/index.ts` under the supplied installation; [upstream example directory](https://github.com/earendil-works/pi/tree/v0.84.4/packages/coding-agent/examples/extensions/subagent).

The smallest useful custom scope is one `delegate_fresh` tool with an allowlisted runner, model, task packet and working directory. Do not expose a parent-history/fork/resume argument on this tool. Return final text plus exit status, model, cwd/base commit, verification evidence and commit hash where applicable. Cap output, wall time and concurrency; cancellation must terminate descendants, not just abandon a promise. Use argument arrays with `shell: false`, passing the prompt through stdin or a controlled file rather than shell interpolation.

Prospective Pi command for a fresh, search-only child, with the task supplied on stdin:

```sh
pi -p --no-session --no-extensions --no-skills --no-prompt-templates \
  --no-context-files --provider openai-codex --model gpt-5.6-sol \
  --tools read,grep,find,ls
```

`--no-session` only disables session persistence. It does not disable project context, skills, extensions, or reads of parent artifacts. The extra flags address automatic loading, not filesystem access. A production launcher should parse JSON events or otherwise distinguish final output from diagnostics and model/tool failure; stdout alone is too weak a success contract.

For Codex, local `codex exec --help` confirms the following prospective command shape; use an absolute approved cwd and result-file path supplied by the launcher:

```sh
codex exec --ephemeral --ignore-user-config --ignore-rules \
  --sandbox read-only -m gpt-5.6-sol -C /path/to/review-snapshot \
  --output-last-message /path/to/job/result.txt -
```

The launcher should allow exactly `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.6-sol`, and `gpt-6-astra` for the Codex runner, preserving your existing routing. Worker mode uses an approved worktree and `--sandbox workspace-write`; review mode cannot select that permission. Authenticated availability of every tier was not exercised. Ignoring user config/rules reduces unintended context but also removes useful guardrails: supply the necessary worker rules explicitly. Pi provider credentials and Codex CLI authentication are separate concerns.

**Literal “must not see” requires an access boundary.** Neither a separate process nor Codex's read-only mode prevents reading accessible parent session files, planner notes or memory. For a hard confidentiality guarantee, supply a curated repository snapshot and enforce filesystem access restrictions that exclude parent reasoning/session locations. Otherwise the honest guarantee is narrower: “the launcher does not pass the parent's reasoning.” Even a task prompt can leak reasoning; construct a claim-only packet, with approved source documents, rather than asking the planner to summarize its case. This directly follows your `plan-refute` contract.

**API implementation boundary.** `pi.registerTool` uses the documented execute signature `(toolCallId, params, signal, onUpdate, ctx)` and returns content plus details. `pi.exec` is useful for bounded commands; explicit process supervision is needed for a durable launcher. `pi.appendEntry` can record job metadata without inserting it into LLM context; reconstruct it during `session_start`. Handle `session_shutdown` on reload/quit. For agent-generated completion, use `pi.sendMessage` with a custom message and follow-up delivery rather than pretending it is user input with `sendUserMessage`. Persisted entries do not keep an OS process alive. [Versioned API contract](https://raw.githubusercontent.com/earendil-works/pi/v0.84.4/packages/coding-agent/docs/extensions.md).

| Criterion | Minimal foreground launcher | Additional cost for full parity |
|---|---|---|
| Fresh context / external tiers | Straightforward explicit process invocation | Strong read isolation needs an OS/filesystem boundary |
| Read-only Explore | Built-in read/search allowlist, conclusion + evidence | Confining reads and extension-free behavior still need validation |
| Full fork | Deliberately excluded from blind tool | Separate explicit Pi session-fork path; never a refuter default |
| Results | Final text + status/artifacts | Streaming UI, usage accounting and resumable transcripts add complexity |
| Background | In-memory job handle while parent lives | Detached supervisor, durable status, recovery and idempotent notification |
| Parallel/pipeline | Fixed bounded `Promise.all`/sequential control | General workflow language is unnecessary unless requirements grow |
| Worktrees / commits | Supervisor provisions; worker verifies and commits | Retention, cancellation, integration conflicts and recovery must be designed |
| Maintenance | Small API surface; CLI compatibility probes | Your team owns tests, lifecycle bugs and credential/model drift |

Writing this narrow boundary is reasonable. Writing a general durable scheduler, agent UI, session manager and workflow framework would erase the “smallest thing” advantage. Add `pi-background-tasks` only if durable shell work is genuinely required; do not assume its context-seeded delegation is suitable for refutation.

## Minimal adoption plan

These are proposed changes only. No commands below were executed, and no configuration was modified.

1. **Resolve the version discrepancy and registry gap before adoption.** Decide whether the deployment target really remains 0.84.4 or the locally observed 0.85.1. Recheck the pinned npm artifact, integrity, repository/tag mapping and dependency graph from an environment with registry access. Do not silently upgrade Pi to accommodate a package.

2. **Install only the pinned pilot package**, initially in an isolated evaluation configuration. The exact install command for your intended config home is:

   ```sh
   PI_CODING_AGENT_DIR="$HOME/.config/pi/agent" pi install npm:@tintinweb/pi-subagents@0.19.0
   ```

   For an evaluation config, replace the environment value with a dedicated test config directory and provision the existing OpenAI authentication through your normal process; do not copy credentials into the report or repository. Do not install the alternatives alongside it: overlapping tools and hooks would confound evaluation. Reload only when idle.

3. **Set bounded defaults** in `~/.config/pi/agent/subagents.json`. Project `.pi/subagents.json` overrides global settings, so inspect both. These are defaults rather than universal hard ceilings; some dispatch paths have exceptions.

   ```json
   {
     "maxConcurrent": 2,
     "maxConcurrentForeground": 2,
     "defaultMaxTurns": 30,
     "backgroundByDefault": false,
     "agentMentions": "off",
     "schedulingEnabled": false,
     "scopeModels": true,
     "strictAgentFiles": true
   }
   ```

   Keys and global/project precedence were checked in the [tagged settings parser](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/settings.ts). Explicitly request background execution when wanted; keep scheduler and mention-based dispatch out of the initial pilot.

4. **Create a clean search role** at `~/.config/pi/agent/agents/explore-clean.md`:

   ```markdown
   ---
   name: explore-clean
   description: Find source evidence for a bounded question.
   tools: read,grep,find,ls
   model: openai-codex/gpt-5.6-sol
   prompt_mode: replace
   extensions: false
   skills: false
   isolated: true
   inherit_context: false
   persist_session: false
   max_turns: 20
   ---
   Answer the supplied question using source evidence. Return conclusions,
   file and line references, and unresolved uncertainty. Do not change files.
   ```

   Frontmatter names and boolean parsing were verified in the [tagged role parser](https://raw.githubusercontent.com/tintinweb/pi-subagents/v0.19.0/src/custom-agents.ts). This role is for ordinary search; it is not the hard refuter boundary. Avoid default role models requiring unavailable Anthropic authentication.

5. **Keep your strict workflows explicit.** Implement the narrow launcher separately in a future authorized change. `plan-refute` gets only the claim, repository/snapshot and approved references; no planner transcript or rationale. `grind` dispatches one fresh worker per task, which runs the repository's canonical checks and makes a scoped commit. Parallel workers require verified separate worktrees and a later integration gate. Preserve the distinction between task completion, successful checks and a committed change.

6. **Run a small acceptance suite before making it the default.** Test two fresh searches; inspect actual child inputs for a parent-only canary; test a nondefault Codex tier; exercise timeout/cancel, model-unavailable failure and output truncation; verify live background completion and reload cancellation. Force worktree-creation failure and confirm your supervisor refuses to dispatch. Exercise a worker's check failure and require no success claim or automatic commit. Run an integration check after merging two independent test commits. No server or E2E harness is needed to establish these properties.

7. **Measure the substitution.** On representative tasks, compare one strong agent against parent + two workers at similar total budget. Record correctness, source-grounded findings, wall time, total tokens/cost, failed/redundant work and integration effort. Keep delegation only where it earns its overhead. Revisit Nico's package if durable workflows and its external adapter remove more code than they add, after the current compatibility/tool-discovery questions are resolved.

## Principal remaining risks

- **Verification gap:** registry/tarball integrity and actual 0.84.4 execution remain unverified; catalog metadata and peer ranges cannot close that gap.
- **Context contamination:** parent-authored briefs, inherited system prompts, ambient extensions, skills and readable files can defeat nominally fresh sessions.
- **Writer safety:** automatic worktree fallback and cleanup are incompatible with a fail-closed ownership/commit policy; handle this outside the recommended package.
- **Lifecycle expectations:** ordinary background completion is not restart survival. Do not reload during active tintinweb/gotgenes work and expect continuation.
- **Shared configuration drift:** model defaults and extension propagation can behave differently under your real config than in a clean demo; verify exact tools and effective prompts.
- **Maintenance concentration:** all shortlisted choices require accepting independent-maintainer risk. Pin versions, inspect updates, and retain the simpler CLI launcher as an exit path.
- **Evidence strength:** literature supports conditional gains, not universal coding-team superiority. Vendor demos and community anecdotes should guide experiments, not replace them.

The decision is therefore a bounded package pilot plus a small owned independence boundary—not an assertion that any current Pi package reproduces every Claude Code semantic unchanged.
