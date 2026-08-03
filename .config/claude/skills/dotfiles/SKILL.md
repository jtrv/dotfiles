---
name: dotfiles
description: Review and commit changes in the bare-repo dotfiles setup, grouped into logical, signed-off commits. Use when the user wants to check dotfiles status, add or commit config changes, or mentions "$DOTFILES", "config repo", "dotfiles", or asks to add changes under ~/.config, ~/.local, etc. into their dotfiles or config.
---

# dotfiles

The dotfiles are a **bare git repo**: git dir `$DOTFILES` (`~/.config/dotfiles`),
work-tree `$HOME`. Every git call needs both flags:

```sh
/usr/bin/git --git-dir="$DOTFILES" --work-tree="$HOME" <cmd>
```

Use `/usr/bin/git` (not a shell alias) so it works regardless of shell config.
Pathspecs are matched against the cwd — pass **absolute `$HOME/...` paths**, not
the `../../` paths that `status` prints.

## Workflow

1. **Status.** Run `status`. Clean tree → say so, stop.
2. **Read every diff** before grouping. Batch files per `diff` call. For large
   auto-generated tracking files (`.local/share/cargo/.crates*`,
   `bun/.../package.json`), a `--stat` + one spot-check is enough.
3. **Surface candidates.** Check if there are relevant/related untracked files
   that should be added - if so - ask the user if they should be added. (If
   candidates are added, re-do steps 1. and 2.)
4. **Group into logical commits.** One concern per commit; keep related files
   together (e.g. a kanata keybind that shells into `niri msg` ships with the
   niri change). Auto-generated dep files group into their own `deps:` commit.
5. **Present the plan** as a table (commit subject → files) before committing.
   Note if the branch is already ahead of origin.
6. **Commit iteratively.** One commit at a time, each with a one-line summary of
   what it does so the user can sign off as you go.
7. **Never push** unless explicitly asked. Never `git add -A`/`.` — add named
   absolute paths only, so an unrelated stray file never rides along.
8. When a diff has a small flaw (e.g. useless-use-of-cat), ask the user if it
   should be fixed before committing.

## Commit messages

Conventional-ish `area: summary` subject (`pi:`, `niri/kanata:`, `waybar:`,
`deps:`). Body only when the "why" isn't obvious from the diff.

## Splitting one file across commits

Avoid it. If genuinely needed, encourage the user to manually used lazygit
and recommend what to commit with what message.
