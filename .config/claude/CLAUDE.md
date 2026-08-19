# User-global instructions

## Contexts
In-depth per-context instructions live in `~/.config/claude/contexts/`. Before working in a matching context, Read the file — do not proceed on memory of it:
- `parallel-agents.md` — spawning multiple agents that edit the same working tree
- `long-tasks.md` — any task spanning sessions or > ~1 hour; before /compact; when resuming or handing off work
- `e2e.md` — writing, running, or gating on end-to-end tests in any language; also read it before adding an E2E tier that may not be worth having, and before configuring any harness that starts a server of its own (E2E, screenshot/capture rigs, smoke tests)
- `flutter.md` — editing, testing, or committing Dart/Flutter code (also surfaced as the `flutter` skill)
- `kotlin.md` — editing, testing, or committing Kotlin or Gradle files (also surfaced as the `kotlin` skill)
- `rust.md` — editing, testing, or committing Rust code (also surfaced as the `rust` skill)
- `python.md` — editing, testing, or committing Python code (also surfaced as the `python` skill)
- `typescript.md` — editing, testing, or committing TypeScript/JavaScript code, bun + oxlint/oxfmt (also surfaced as the `typescript` skill)
- `go.md` — editing, testing, or committing Go code (also surfaced as the `go` skill)

## Agent dispatch
A classifier-blocked Agent dispatch gets ONE honestly reworded retry
(loop/load-test and scraping-adjacent phrasing are known triggers). Blocked
again: do the task in the main loop or park it for the user — never
disguise it to slip past.

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

## Clipboard for user-run commands
When giving commands the user must run themselves (`! ...` session command, sudo, interactive login, key management), also put them on the clipboard via `clipcatctl insert <text>` (no `!` prefix) and say so. Multiple commands: insert each in reverse run order, so the first-to-run ends up as the active clip and the rest sit in clipcat history. Never copy secrets or fill-in values — copy the template with placeholders. Skip silently if `command -v clipcatctl` fails or the daemon is down.

## mise
Use mise as the project runtime layer: pin tool versions in `mise.toml` (`[tools]`), hold project env vars in `[env]` (secrets go in an untracked `mise.local.toml`, never committed), and document runnable commands as `[tasks]` — build, fmt, dev, serve, test, lint, etc. — so `mise run <task>` is the canonical way to run them. When adding a tool, env var, or recurring command to a project, put it in `mise.toml` rather than README prose or ad-hoc shell. Prefer `mise run <task>` over invoking the underlying commands directly when a task exists.

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

## graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
