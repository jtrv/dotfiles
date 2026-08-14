# Vendored skills manifest

These skills live in this directory but are **not tracked** in dotfiles — they're
third-party content, reinstallable from upstream. Everything else in `skills/` is
hand-written and tracked. On a new machine, reinstall from the sources below.

| Skill | Version | Source |
|---|---|---|
| caveman | 2026-08-04 | github.com/JuliusBrussee/caveman (`skills/caveman`) |
| caveman-commit | 2026-08-04 | github.com/JuliusBrussee/caveman (`skills/caveman-commit`) |
| color-expert | 2026-07-30 | github.com/meodai/skill.color-expert (repo root is the skill) |
| graphify | — | safishamsi (github.com/sponsors/safishamsi; see SKILL.md) |
| impeccable | 4.0.4 | github.com/pbakaus/impeccable → `.claude/skills/impeccable` (impeccable.style; `bunx impeccable install`; note the npm package version, 3.5.0, tracks the installer, not the skill) |
| last30days | — | github.com/mvanhorn/last30days-skill — installed tree is not the repo tree (local `assets/`, `agents/` vs upstream `.agents/`), so reinstall via its own installer rather than copying the repo over it |
| vercel-composition-patterns | — | vercel (see metadata.json) |
| vercel-optimize | — | vercel |
| vercel-react-best-practices | — | vercel |
| vercel-react-native-skills | — | vercel |
| vercel-react-view-transitions | — | vercel |
| web-design-guidelines | 1.0.0 | vercel |
| writing-skills | 2026-07-27 | github.com/obra/superpowers (`skills/writing-skills`) |

Adding a vendored skill → add a row here. Writing a skill yourself → track it in
dotfiles instead.
