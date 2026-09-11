# harnesses

Changes to the coding agents themselves — Claude Code, Codex, Pi — meaning their
config dirs, plugins, skills, extensions and the wiring that keeps the three
pointed at one source of truth. `../PLUGINS.md` is the inventory of what is
installed where and what each harness's equivalent is; this file is the rules
for changing it.

## Never stage vendored skills

`skills/MANIFEST.md` records which skills are third-party. Those are
reinstallable from upstream and are deliberately **untracked** — only
hand-written skills belong in dotfiles. The manifest has always said so; saying
it there was not enough, which is why the rule lives here too.

A vendored skill is large: `color-expert` is 181 files, `last30days` 175,
`vercel-optimize` 155. Eleven of them once reached the index at 698 files,
burying a 68-file change that was the actual work. Nothing warns you — there is
no ignore rule, and `config status` on a swept directory looks like progress.

So: **name paths explicitly.** Never `config add` a directory at or above
`~/.config/agents/skills`. The standing dotfiles rule against `git add -A`/`.`
is the same rule; this is the place it gets violated.

Before committing anything under `~/.config/agents`:

```sh
config diff --cached --name-only -- "$HOME/.config/agents/skills"
```

Expect roughly one `SKILL.md` per hand-written skill. Hundreds of files, or any
name listed in `skills/MANIFEST.md`, means vendored content was swept in —
unstage it (`config restore --staged <absolute paths>`, which leaves every file
on disk) before going further.

`graphify` is a useful canary: it is vendored, so if it ever shows up staged,
something added a directory wholesale.

## Adding a skill

Claude and Pi symlink the whole `skills` directory, so a new skill is visible to
them the moment it exists. **Codex does not** — it takes per-skill symlinks,
because `$CODEX_HOME/skills/.system` holds its own bundled skills and is
re-extracted per version, so pointing the whole directory at ours would write
Codex's system skills into the dotfiles tree. Re-link after adding one:

```sh
cd "$CODEX_HOME/skills" && for d in ~/.config/agents/skills/*/; do
  ln -sfn "$d" "$(basename "$d")"; done
```

`skills.extra_roots` looks like the tidy alternative and is not — the key does
not exist, and Codex ignores it silently rather than erroring, so a session
looks configured while loading nothing.

## Adding a plugin

For a port of a named upstream tool, only that upstream's own package counts. A
third party repackaging someone else's service under its name is a different
trust decision — especially anything that would hold API access to an account —
and those stay unadopted no matter how many downloads they have. Generic
plumbing with no upstream to be from (LSP and MCP bridges) is exempt.

Record the result in `../PLUGINS.md` either way. A dash there means *checked and
nothing suitable exists*, which is worth as much as an install — it stops the
next session re-researching it. Deferred adoptions get a probe in `../watches/`.

## Verify wiring, do not assume it

A symlink that silently loads nothing looks identical to one that works. After
changing how a harness finds instructions or skills, ask that harness something
answerable only from the file you just wired up — a tool named in `AGENTS.md`,
a skill name — rather than trusting that the path looks right.

Codex's home is `$CODEX_HOME` (`$XDG_CACHE_HOME/codex`), not the `~/.config/codex`
that sorting by name would suggest; that directory is a stale abandoned copy.
Confirm with `codex doctor` before editing anything, or you will edit a config
nothing reads.
