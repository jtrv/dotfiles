# Vendored skills manifest

These skills live in this directory but are **not tracked** in dotfiles — they're
third-party content, reinstallable from upstream. Everything else in `skills/` is
hand-written and tracked. On a new machine, reinstall from the sources below.

| Skill | Version | Source |
|---|---|---|
| caveman-commit | b4531df (2026-10-22) | github.com/JuliusBrussee/caveman (`skills/caveman-commit`) |
| color-expert | 5bf7c77 (2026-10-21) | github.com/meodai/skill.color-expert (repo root is the skill) |
| impeccable | 4.7.0 | github.com/pbakaus/impeccable → `.claude/skills/impeccable` (impeccable.style) |
| last30days | 3.30.0 | github.com/mvanhorn/last30days-skill → `skills/last30days` (copy that directory; the repo root is not the skill) |

Updating: shallow-clone the source into a scratch dir, check for local-only
files (`diff -rq`), then `rsync -a --delete <source dir>/ <skill>/`.

Adding a vendored skill → add a row here. Writing a skill yourself → track it in
dotfiles instead.

Plugins (a different thing, per harness) are recorded in `../PLUGINS.md`.
