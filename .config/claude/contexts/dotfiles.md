# dotfiles

One repo, two working trees per machine:

- **Live**: bare git dir `$DOTFILES` (`~/.config/dotfiles`), work-tree `$HOME`, branch = machine name. Drive it with the `config` wrapper (= `command git --git-dir="$DOTFILES" --work-tree="$HOME"`). Pathspecs match against the cwd — pass absolute `$HOME/...` paths, never the `../../` paths `status` prints.
- **Staging**: `~/repos/dotfiles`, a linked worktree on `<machine>-wip`. Plain `git` works there. **Cross-machine merges and experiments happen here, never on live**; ordinary commits land on live directly.

Both trees share one object store and ref set — no fetch/push between them. **Never check out the live machine branch in staging**: git's double-checkout guard can't see the ad-hoc `$HOME` tree, and two trees on one branch show phantom status changes in each other.

## Ownership

Branches: `thiccpad` (NixOS laptop, no home-manager), `morpheus` (arch desktop), `morpheus-nixos` (the desktop's NixOS migration; replaces `morpheus` at cutover — NixOS rules, desktop ownership).

This table is the **single source of truth** for what is machine-specific; anything not listed is shared. When a merge surfaces a new ambiguous path, ask the user, then record the decision here — never decide from vibes like "looks desktop-y".

| Path | Ownership |
|---|---|
| `warehouse/arch`, `.config/pacman/` | arch machines (morpheus) |
| `warehouse/uv` additions | morpheus; NixOS machines keep it empty (nixos-config carries tools) |
| `.config/systemd/user/*` units | owning machine; NixOS machines track none (units come from nixos-config) |
| `.local/bin/waybar-sleep-inhibit` + its waybar config/style hunks | morpheus |
| evdi/hermes-streaming (packages, virtual-display pinning) | morpheus |
| bun global `package.json`, cargo `.crates*` | per-machine local state — never merged. Keep this machine's side, but **report what the other side had**; if it looks like new tools rather than version drift, ask |
| `kanata/*.kbd` | every branch, per-machine by filename (`morpheus.kbd`, `thiccpad.kbd`, `shared.kbd`) — prefer this name-spacing for new machine-specific files over new table rows |

## Converging

Invariant: **shared changes flow to every branch, both ways, pairwise; machine-specific files stay with their owner.** There are no convergence tags — the merge-base *is* the last convergence point, computed for free.

In the staging worktree, with `<this>` = this machine's branch and `<other>` = the branch being converged:

1. `config fetch origin` (github.com/jtrv/dotfiles). Always merge **remote-tracking refs**; local copies of other machines' branches go stale.
2. Drift check, both sides at once: `git log --left-right --oneline <this>...origin/<other>` (`<` ours only, `>` theirs only).
3. `git merge <this>` (catch staging up with live), then `git merge origin/<other>`.
4. Conflicts: table paths and manifests resolve mechanically per Ownership. Shared files resolve **iteratively with the user** — one at a time, both sides and intent shown, sign-off each. Note rerere is on with `autoupdate`: recorded resolutions reapply and self-stage; run `git rerere diff` and re-inspect anything that resolved without input.
5. Sweep: re-delete what the table says isn't ours; restore our own files the incoming branch deleted — deletions propagate silently when our side hadn't touched the file (`git log --diff-filter=D --name-status <this>..origin/<other> -- <path>` lists what they dropped). Then scan for silent duplication: the same change made on both sides can land twice with no conflict (a doubled `[vad]` TOML section broke voxtype this way).
6. **Checkpoint — before committing the merge**: show the user the incoming summary, planned deletions/restores, and everything mechanically discarded. Commit only after that.
7. Take it live: `config status` effectively clean, then `config merge --ff-only <this>-wip`. A non-ff merge or overlapping dirty files would put the mess in the live `$HOME` tree — the thing staging exists to prevent. If live moved meanwhile, `git merge <this>` in staging again, then fast-forward.
8. Push only when asked: `config push origin <this>`. The pair is fully converged once the other machine runs this same flow there.

## Commit workflow (live `$HOME` state, on the live branch)

1. **Status.** Clean tree → say so, stop.
2. **Read every diff** before grouping. Batch files per `diff` call; for large auto-generated tracking files (`cargo/.crates*`, bun `package.json`), `--stat` + a spot-check is enough.
3. **Surface candidates.** Relevant untracked files: ask the user; if added, redo 1–2.
4. **Group into logical commits.** One concern per commit; related files together (a kanata keybind that shells into `niri msg` ships with the niri change). Auto-generated dep files get their own `deps:` commit.
5. **Present the plan** as a table (subject → files) before committing; note if the branch is ahead of origin.
6. **Commit iteratively**, one at a time with a one-line summary so the user can sign off as you go.
7. **Never push unasked. Never `git add -A`/`.`** — named absolute paths only, so a stray file never rides along.
8. A diff with a small flaw (e.g. useless-use-of-cat): ask before committing.

Messages: conventional-ish `area: summary` (`pi:`, `niri/kanata:`, `waybar:`, `deps:`); body only when the why isn't obvious from the diff. Splitting one file across commits: avoid — hand the user lazygit (`lc`) with a recommendation instead.
