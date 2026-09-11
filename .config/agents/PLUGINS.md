# Cross-harness plugin manifest

What extends each agent, and what the equivalent is on the others. Plugins are
third-party and reinstallable, so nothing here is tracked content — this is the
record needed to rebuild the set on a new machine, and to answer "we have this
in Claude, can Pi do it too?" without re-researching. Hand-written skills and
vendored skills are a separate list in `skills/MANIFEST.md`.

## What each harness means by "plugin"

| Harness | Unit | Install | Enabled in |
|---|---|---|---|
| Claude Code | marketplace plugin | `/plugin marketplace add <src>` then `/plugin install <name>@<market>` | `enabledPlugins` in `~/.config/claude/settings.json` |
| Codex | marketplace plugin | `codex plugin marketplace add <src>` then `codex plugin add <name>@<market>` | git marketplaces: `[plugins."<name>@<market>"]` in `$CODEX_HOME/config.toml`. The `openai-curated-remote` catalog is enabled account-side and leaves no trace in config.toml — `codex plugin list` is the only local truth |
| Pi | package, or a local extension | `pi install npm:<pkg>` / `pi install git:<host/user/repo>` | `$PI_CODING_AGENT_DIR/extensions/*.ts` are auto-discovered; packages listed by `pi list` |

Two structural limits decide most of the table below:

- **Pi ships no MCP.** That is an upstream position, not an oversight: its README
  says to build a CLI tool with a README, or write an extension that adds MCP.
  Someone did — `pi install npm:pi-mcp-adapter` reads a standard `.mcp.json` or
  `~/.config/mcp/mcp.json`, and its `/mcp setup` imports the Claude Code and Codex
  configs already on the machine. So an MCP-only plugin is reachable from Pi, but
  a native Pi extension beats the bridge where one exists, and the table below
  names the native one first.
- **Codex hooks are trust-gated.** A freshly installed plugin's hooks are
  skipped silently until reviewed once via `/hooks` in the Codex TUI. Installing
  is not enabling.

## Portability

Checked against the installed caches and each project's own docs on 2026-09-10.
A dash means no equivalent exists, not that one is merely unconfigured. For a
Pi port of a named upstream tool, only that upstream's own package counts — a
third party reimplementing someone else's service under its name is a different
trust decision, so those rows stay dashed no matter how many stars they have.
The exception is generic plumbing with no upstream to be from, such as the LSP
and MCP rows.

| Capability | Claude | Codex | Pi |
|---|---|---|---|
| context-mode — sandboxed execution + searchable session memory | `context-mode@context-mode` | `context-mode@context-mode`, same git marketplace | `npm:context-mode` — ships its own extension with `tool_call`/`session_start` handlers |
| ponytail — lazy-senior ruleset | `ponytail@ponytail` | `ponytail@ponytail` | `git:github.com/DietrichGebert/ponytail` |
| context7 — live library docs | `context7@claude-plugins-official` | not in the catalog — added as an MCP server instead, `https://mcp.context7.com/mcp` (OAuth), the same Upstash endpoint the Claude plugin wraps | `npm:@upstash/context7-pi` — official, native tools, same repo as the Claude plugin |
| cloudflare | `cloudflare@cloudflare` | `cloudflare@openai-curated-remote`, developer_name Cloudflare — the same skills, minus cloudflare-one, email-service, nextjs, sandbox-* and turnstile | — nothing from Cloudflare. Third parties repackage the `cf_*` tools, but handing an unaffiliated author API access to the account is not a trade worth making |
| playwright — browser control | `playwright@claude-plugins-official`, currently disabled | `codex mcp add playwright -- npx @playwright/mcp@latest` | same server through `pi-mcp-adapter`. No native port exists — the third-party CDP extensions are unrelated code |
| Codex bridge — rescue, review, adversarial review | `codex@openai-codex` | n/a, it is Codex | — |
| Language servers — rust-analyzer, typescript, clangd on; gopls, pyright off | native `LSP` tool; the `*-lsp@claude-plugins-official` plugins only register which servers it may drive | — nothing in the catalog, no feature flag, and no vendor ships an LSP-over-MCP server; the `mise run check` gate covers diagnostics and ast-grep covers navigation. Deferred, watched by `watches/codex-lsp.sh` | `pi install npm:@narumitw/pi-lsp` — config-driven, zero deps, points at server binaries already installed. `pi-lens` is the maximalist alternative but duplicates oxlint/oxfmt/ast-grep |
| Skill authoring | `skill-creator@claude-plugins-official` | bundled system skill | — |
| Curated memory | `remember@claude-plugins-official` | native, `features.memories` | — |
| Response style | `learning-output-style@claude-plugins-official` | native, `personality` setting | — |
| Autonomous loop | `ralph-loop@claude-plugins-official` | — (the `grind` skill covers this everywhere) | — |
| Security guidance | `security-guidance@claude-plugins-official` | curated `codex-security` | — |
| Vercel | `vercel@claude-plugins-official`, currently disabled | curated `vercel` | — |

Codex's remote catalog is far bigger than it looks from the TUI — roughly 700
named plugins, mostly SaaS connectors (Gmail, Slack, Notion, Supabase) but with
real dev tooling among them, Cloudflare and Vercel included. `codex plugin list`
prints the lot; grep it before concluding something is absent. What it does not
carry is anything MCP-shaped that already has a good server: no context7, no
playwright. Those go in through `codex mcp add` instead, which is the better
route anyway — it points at the vendor's own server rather than a repackaging.

`codex plugin list` also reports plugins enabled account-side that config.toml
never mentions: as of this check, `vercel`, `codex-security`, `plugin-management`,
`openai-templates` and `deep-research-work`.

## Ours, not third-party

These are tracked in dotfiles and shared by pointing every harness at one file,
rather than installed per harness.

| Capability | Claude | Codex | Pi |
|---|---|---|---|
| Global instructions | `@~/.config/agents/AGENTS.md` imported by `CLAUDE.md` | `$CODEX_HOME/AGENTS.md` symlink | `AGENTS.md` symlink |
| Skills | `skills` -> `../agents/skills` | 29 per-skill symlinks inside `$CODEX_HOME/skills/` | `skills` symlink |
| Secret blocking | `PreToolUse` hook in settings.json | same script from `hooks.json` (planned, not built) | `extensions/block-secrets.ts` |
| Statusline | `statusline/statusline.sh` into starship | built-in `tui.status_line` only, no script hook | `extensions/statusline.ts`, reusing the same script |

Both Pi extensions shell out to the same scripts Claude uses. That is the point:
one implementation, one place to fix a bug.

Codex takes per-skill symlinks rather than one directory symlink because
`$CODEX_HOME/skills/.system` holds its own bundled skills and is re-extracted
per version — pointing the whole directory at ours would write Codex's system
skills into the dotfiles tree. The cost is that a newly added skill needs its
own link:

```sh
cd "$CODEX_HOME/skills" && for d in ~/.config/agents/skills/*/; do
  ln -sfn "$d" "$(basename "$d")"; done
```

`skills.extra_roots` looks like the tidy answer and is not: the key does not
exist, and Codex ignores it in silence rather than erroring.

## Where each harness keeps its home

| Harness | Home | XDG |
|---|---|---|
| Claude | `CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude` | config |
| Pi | `PI_CODING_AGENT_DIR=$XDG_CONFIG_HOME/pi/agent` | config |
| Codex | `CODEX_HOME=$XDG_CACHE_HOME/codex` | **cache** |

Codex is the odd one out, and deliberately so — its home mixes config with
~100 MB of churning sqlite (`logs_2.sqlite` alone is 83 MB), which does not
belong under `.config`. The catch is that the same directory also holds the
stored OAuth login, every project's `trust_level`, memories, and the plugin and
marketplace registrations made above: clearing `~/.cache` would take all of it.
Codex has no way to split config from state, so this is a trade, not a bug.

A stale `~/.config/codex` from 2026-07-21 also exists — an abandoned attempt at
the config-dir layout. Nothing reads it. Left in place rather than deleted
because it still holds a stored login.

## Marketplaces to re-add on a new machine

`context-mode`, `ponytail`, `openai-codex` and `cloudflare` are git-sourced and
registered per harness. The official Claude and curated Codex catalogs are
built in and need no registration.
