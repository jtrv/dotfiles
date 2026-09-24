# User-global instructions

## Verbosity
I have ADHD so please respond clearly and concisely.

## Contexts
In-depth per-context instructions live in `~/.config/agents/contexts/`. Before working in a matching context, Read the file — do not proceed on memory of it:
- `ui.md` — any UI/UX work on any platform: screens, pages, dashboards, artifacts, charts; taste calls, colour choices, design review. Points at the per-platform capture rigs and the `impeccable`/`color-expert` skills
- `artifacts.md` — publishing any Artifact that collects user decisions (triage boards, review forms, note collectors)
- `parallel-agents.md` — spawning multiple agents that edit the same working tree
- `long-tasks.md` — any task spanning sessions or > ~1 hour; before /compact; when resuming or handing off work
- `e2e.md` — writing, running, or gating on end-to-end tests in any language; also read it before adding an E2E tier that may not be worth having, and before configuring any harness that starts a server of its own (E2E, screenshot/capture rigs, smoke tests)
- `flutter.md` — editing, testing, or committing Dart/Flutter code (also surfaced as the `flutter` skill)
- `kotlin.md` — editing, testing, or committing Kotlin or Gradle files (also surfaced as the `kotlin` skill)
- `rust.md` — editing, testing, or committing Rust code (also surfaced as the `rust` skill)
- `python.md` — editing, testing, or committing Python code (also surfaced as the `python` skill)
- `typescript.md` — editing, testing, or committing TypeScript/JavaScript code, bun + oxlint/oxfmt (also surfaced as the `typescript` skill)
- `go.md` — editing, testing, or committing Go code (also surfaced as the `go` skill)
- `harnesses.md` — changing the coding agents themselves (Claude Code, Codex, Pi): their config dirs, plugins, skills, extensions, and the symlink wiring that shares one AGENTS.md and one skills dir between them. Read before staging anything under `~/.config/agents`
- `dotfiles.md` — anything touching the dotfiles: committing config changes ($DOTFILES bare repo / `config`), the `~/repos/dotfiles` staging worktree, converging machine branches and checking drift (also surfaced as the `dotfiles` skill)

## Watches
Deferred-adoption decisions ("re-check X when it matures") have probe scripts
in `~/.config/agents/watches/` — one per watch, each printing a single line:
`NOT-READY` / `CHECK` / `UNKNOWN` + reason. Run the probe before re-researching
a watch topic; investigate only on `CHECK`. Adding a watch = probe script +
pointer from the doc or memory that defers the decision.

## Research
Reports on how the agents themselves are set up and used — delegation,
context handling, plugin and skill evaluations — live in
`~/.config/agents/research/` (index in its `README.md`), date-prefixed.
A session that produces one writes it there, not to a scratchpad. Read the
index before re-researching a harness topic; a decision the report justified
belongs in `PLUGINS.md`, a context file or a skill, with a pointer back.

## Routing
Which model takes which work, for whichever harness is steering the session.
Read `contexts/harnesses.md` before changing routes or tier placement.
A delegated worker does its task and does not route onward.
Dispatch and escalation rationale: `research/2026-09-15-routing-instruction-fixes.md`.
Tier placement evidence: `research/2026-09-23-routing-tiers-opus-5-5-gpt-6.md`.

| Situation | Route |
|---|---|
| Sufficient context, straightforward | Stay here. Bulky byproduct (long test/log/grep output) → `ctx_execute`, printing the derived answer, never the dump |
| Nontrivial plan or design ready, not yet built | `plan-refute` (its small-tactical-plan exemption applies) |
| Implementation ready | Suggest the user run a review by a model from a different family than the one that wrote the code — a same-family reviewer shares its blind spots (user-invoked only) |
| Repeated attempts have failed | Codex `gpt-6-astra` with the repro, evidence, and failed approaches; ask for a testable alternative explanation |
| Substantial separable task, clear inputs and acceptance check | Codex `gpt-6-luna` (mechanical, near-zero judgment: fixtures, extraction, renames) or `gpt-6-sol` (bounded coding or investigation needing judgment). Inspect the result. Quick tasks stay inline |
| Substantial prose — documentation, READMEs, reports, summaries | Codex `gpt-6-sol` at default effort; short prose (commit/PR text, a paragraph) stays inline. Agent instructions follow the rule below. Evidence: `research/2026-09-24-prose-model-choice.md` |
| Demanding coding work — multi-file implementation, nontrivial refactor, sustained reliability over a long task | Codex `gpt-6-sol`. Inspect the result |
| Ambiguous, hard debugging, substantial independent review | Stay here if this session is on Opus 5.5 (the strongest tier); otherwise Codex `gpt-6-astra` |
| Ordered queue of separable tasks | `grind` |
| Agent instruction changes | Follow “Agent instructions get the strongest model” below |

Codex tiers for delegated tasks: Luna → Sol → Astra; a blocked worker gets more
effort before a higher tier. Luna is the mechanical tier, not a cheap coding
default — start coding work at Sol. Skill-owned dispatch (`grind`
workers, `plan-refute` refuters) is unchanged.

### Dispatch per harness

| Route | Claude Code | Codex | Pi |
|---|---|---|---|
| Codex `<model>` | `codex:codex-rescue` with `--model <model>` | `spawn_agent` with `model=<model>`, `fork_turns="none"` and a self-contained task brief | `delegate` with `runner=codex`, `model=<model>` |
| Cross-family review | Suggest the user run `/codex:review`, or `/codex:adversarial-review` when the approach itself is in question | Suggest the user run `/code-review` in Claude Code (or another non-OpenAI reviewer) | `delegate` with `runner=agy` (Gemini) for a read-only review the session runs itself; or, on a non-OpenAI model, suggest the user run `codex review` |
| `grind` | the `grind` skill | the `grind` skill, one fresh `spawn_agent` per task | the `grind` skill's in-session loop, one `delegate` child with `mode=write` per task; inspect its result before continuing |

## Agent instructions get the strongest model
Creating or substantively redesigning a skill, a context file, this file, a
harness routing table, or an agent/subagent definition is done by the most
capable model available (currently Claude Opus 5.5) — never delegated down a
tier to save cost. These
files steer every future session that loads them, so a flaw in one is paid
again on each use, and it fails quietly: a vague trigger or a wrong rule looks
fine and just makes later work worse. If the current session is not on the
strongest model, keep drafts outside paths any harness loads as instructions
or skills, and hand the design to the strongest model (or tell the user).
Only that model finalizes and writes the change into loaded paths: an
uncommitted edit is already live for later sessions. Typo fixes and mechanical
renames are exempt. Harness code — hooks, Pi extensions, delegate tooling —
is under the same rule: it shapes every session the way an instruction file
does, and a review of weaker-model lifecycle code found it missing its own
guarantees (2026-09-15).

## Comments
The default is no comment; adding one carries the burden of proof. A comment earns its place only when it holds a *why* the reader cannot recover from the code in front of them: a non-obvious constraint or invariant, a trap that will bite the next editor, the origin of a measured constant, the reason a simpler-looking alternative is wrong.
Never write comments that:
- narrate what the next line visibly does, or restate a name;
- explain an absence — deleted code needs no tombstone, an omitted widget/field/branch needs no "deliberately no X here" unless someone WILL plausibly re-add it wrongly;
- talk to the reviewer — "changed from", "now uses", "per the new design" belong in the commit message and die with the PR;
- cite planning artifacts as justification (a wave/task id may locate a decision, but the constraint itself must be stated in place).
When deleting code, delete its comments with it and add none.

## Commits
Never add a "co-authored by Claude Code" trailer.
Inside `git commit -m "…"` the shell expands backticks, `$(…)` and `$VAR` — a
message quoting a command runs it and splices the output into the message
(it happened: a `flutter drive` profile build, committed as ~40 lines of
body). Anything beyond a one-line subject goes to a scratchpad file and
`git commit -F <file>`.

## Clipboard for user-run commands
When giving commands the user must run themselves (`! ...` session command, sudo, interactive login, key management), also put them on the clipboard via `clipcatctl insert <text>` (no `!` prefix) and say so. Multiple commands: insert each in reverse run order, so the first-to-run ends up as the active clip and the rest sit in clipcat history. Never copy secrets or fill-in values — copy the template with placeholders. Skip silently if `command -v clipcatctl` fails or the daemon is down.

## mise
Use mise as the project runtime layer. Config lives at `<project-root>/.config/mise/config.toml` — pin tool versions there (`[tools]`), hold project env vars in `[env]` (secrets go in an untracked `.config/mise/config.local.toml`, never committed), and document runnable commands as `[tasks]` — build, fmt, dev, serve, test, lint, etc. — so `mise run <task>` is the canonical way to run them. A task longer than a couple of lines is an executable file task at `.config/mise/tasks/<name>` — shebang + `#MISE description="..."`, filename is the task name, a `.sh`/`.py` extension stripped — rather than a long TOML string. These run directly as well (`./.config/mise/tasks/check`), so a `package.json` script or CI step can call the path without mise on PATH. Keep `scripts/` for the source a task invokes (a `.ts` module, a helper), never for a task entry point. Do not add a root `mise.toml` alongside the `.config` layout — it takes precedence and shadows it. When adding a tool, env var, or recurring command to a project, put it in the mise config rather than README prose or ad-hoc shell. Prefer `mise run <task>` over invoking the underlying commands directly when a task exists.

## Preferred tools
These are installed; reach for them over the generic default:
- **Code search/refactor**: `ast-grep` for structural (AST) search and rewrites — prefer over regex grep + hand edits. `rg` for text search, `rga` when content is inside PDFs/archives/docx/sqlite. `fd` for file discovery by name/type; `plocate` for instant whole-filesystem filename lookup.
- **Line-set ops**: `zet union|intersect|diff` on files/streams — replaces `sort | comm`/`uniq` pipelines.
- **Docs lookup**: `dedoc` — offline DevDocs (`dedoc search <docset> <query>`, `dedoc open`); ~80 docsets downloaded (rust, python, postgres, react, go…). Try before WebFetch/web search for API reference.
- **Web/doc → text**: `reader <url>` renders a webpage as readable text for ingestion — prefer over raw curl/WebFetch HTML. `markitdown` converts local docx/pdf/pptx/xlsx to markdown.
- **Diffs**: `difft` (difftastic) for syntax-aware diffs when reviewing changes (`GIT_EXTERNAL_DIFF=difft git diff`).
- **Databases**: `usql` — one CLI for postgres/mysql/sqlite/etc. (`usql <url> -c '<sql>'`).

## JavaScript tooling
Use `bun` instead of `npm` (install, run scripts, execute packages via `bunx`).

## Python tooling
Use `uv` instead of `pip`/`python`: `uv add` + `uv run` in projects with `pyproject.toml`, `uv pip install` as drop-in pip replacement elsewhere (existing venvs, requirements.txt), `uvx` for one-off tools.

