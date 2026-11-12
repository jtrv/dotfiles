# dotfiles

One repo, two working trees per machine:

- **Live**: bare git dir `$DOTFILES` (`~/.config/dotfiles`), work-tree `$HOME`, branch = machine name. Drive it with the `config` wrapper (= `command git --git-dir="$DOTFILES" --work-tree="$HOME"`). Pathspecs match against the cwd — pass absolute `$HOME/...` paths, never the `../../` paths `status` prints.
- **Staging**: `~/repos/dotfiles`, a linked worktree on `<machine>-wip` (`config worktree add ~/repos/dotfiles <machine>-wip`). Plain `git` works there. **Cross-machine merges and experiments happen here, never on live**; ordinary commits land on live directly.

Both trees share one object store and ref set — no fetch/push between them. **Never check out the live machine branch in staging**: git's double-checkout guard can't see the ad-hoc `$HOME` tree, and two trees on one branch show phantom status changes in each other.

## Ownership

Branches: `thiccpad` (NixOS laptop, no home-manager), `morpheus` (arch desktop), `morpheus-nixos` (the desktop's NixOS migration; replaces `morpheus` at cutover — NixOS rules, desktop ownership).

`morpheus-nixos` sticks to morpheus's changes and keeps desktop-specific state (ultrawide output, hermes pinning, edge-pan, GPU tooling) unless the change is NixOS-specific; shared updates flow in from any branch; archisms (pacman, arch warehouse) belong in nixos-config's `nixos/morpheus` dir, not this branch.

This table is the **single source of truth** for what is machine-specific; anything not listed is shared. When a merge surfaces a new ambiguous path, ask the user, then record the decision here — never decide from vibes like "looks desktop-y".

| Path | Ownership |
|---|---|
| `warehouse/arch`, `.config/pacman/` | arch machines (morpheus) |
| `warehouse/{uv,bun,cargo}` | per-machine. NixOS machines list only what nixos-config doesn't install: bootstrap replays these lists on a fresh install, on top of nix. Prune against `nix eval --json <nixos-config>#nixosConfigurations.<host>.config.environment.systemPackages` (pname and `meta.mainProgram`), never by eye |
| `.config/systemd/user/*` units | owning machine; NixOS machines track none (units come from nixos-config) |
| evdi/hermes-streaming (packages, virtual-display pinning) | morpheus. nixos-config replaces hermes with sunshine, so the `Virtual-1` pin is probably dead after cutover (unconfirmed) |
| bun global `package.json`, cargo `.crates*` | per-machine local state — never merged. Keep this machine's side, but **report what the other side had**; if it looks like new tools rather than version drift, ask |
| `kanata/*.kbd` | every branch, per-machine by filename (`morpheus.kbd`, `thiccpad.kbd`, `shared.kbd`) — prefer this name-spacing for new machine-specific files over new table rows |
| `niri/hosts/*.kdl` | every branch, per-machine by filename; `niri/config.kdl` is fully shared — machine settings (outputs, struts, per-host daemons and binds) go in the host file, never back into `config.kdl` |
| `niri/local.kdl` | per-branch, one line including that branch's `hosts/<machine>.kdl`. A branch that lacks it keeps the incoming copy (`config-sweep` flags it) — repoint it before committing |
| `mpv/hosts/*.conf` | every branch, per-machine by filename (GPU shader and scaler lines); `mpv.conf` is fully shared |
| `mpv/local.conf` | per-branch, one `include=` of that branch's `hosts/<machine>.conf`; same missing-file handling as `niri/local.kdl` |
| `.config/environment.d/*` | morpheus — NixOS machines set the same vars via `environment.sessionVariables` in nixos-config |
| `.config/fontconfig/fonts.conf` | morpheus — NixOS machines set the same aliases via `fonts.fontconfig.defaultFonts` in nixos-config |
| `.config/gamemode.ini`, `.config/pipewire/pipewire.conf`, `.local/bin/steam` | morpheus — NixOS machines use `programs.gamemode.settings`, `services.pipewire.extraConfig` and `programs.steam` in nixos-config |
| `warehouse/wud` | per-machine, like the package manifests — never union. Keep this machine's side and **ask about every docset the other side has** (`config-sweep` prints them); install one only on a yes. The file is a `wud ls` snapshot that `warehouse` rewrites, so an installed docset lands in it on the next run |
| `warehouse/{fish,go,ktsctl}`, `fish/fish_plugins`, `mpv/shaders/*`, `mise/config.toml` global `[tools]` | morpheus keeps them; NixOS machines drop what nixos-config installs |
| `paru/paru.conf`, `.local/bin/mirrors`, topgrade `[linux]`/arch commands | arch machines (morpheus) |
| firefox flavor: `BROWSER`, the firefox lines of `mimeapps.list`, `mozilla/firefox/<profile>` dir | per-machine: arch morpheus runs firefox; NixOS hosts run devedition (nixos-config installs only that, and its profile differs from arch devedition's), so morpheus-nixos carries thiccpad's devedition flavor. `config-sweep` keeps HEAD's profile dir; `mimeapps.list` is otherwise shared (other handlers, e.g. `inode/*`), so the sweep lists it for review — a whole-file reset once dropped the shared yazi handler on morpheus-nixos |
| `.config/xdg-desktop-portal-termfilechooser/`, `.config/xdg-desktop-portal/niri-portals.conf` | morpheus — NixOS machines set the termfilechooser config (`environment.etc`) and portal routing (`xdg.portal.config`) in nixos-config |
| absolute tool paths in configs/scripts (`/usr/...` vs `/run/current-system/sw/...`) | shared — probe both paths at run time (see `.local/bin/tofi-run`), never fork the file per machine |
| secret access in scripts (`secli get` on morpheus vs sops-nix `/run/secrets/*` on NixOS; agenix is gone) | per-machine. Secrets still missing from sops are listed in nixos-config `docs/plan.md` |
| hardware tuning: `voxtype` model/threads, waybar height/font | per-machine hunks in otherwise shared files — `config-sweep` lists them for review, never resets them. voxtype's evdev hotkey is off on NixOS (niri binds `voxtype record toggle`), so morpheus-nixos keeps the NixOS `enabled = false` |
| `easyeffects/*` | shared — every file is keyed by a device (autoload by alsa id, presets/irs by headphone or mic name) and inert elsewhere; union on merge, never sweep |
| `fish/config.fish` ssh-agent fallback | morpheus (NixOS gets the agent from systemd) |
| `fish/conf.d/aliases.fish` `wget` → `wget2` alias | morpheus (nix installs no `wget2`) |
| skyspell dict names in `kak/rc/modes.kak` (`en_US-large`/`es` vs nix `en_US`/`es_ANY`) | per-machine |
| `.local/bin/niri-edge-pan`, `.config/nvtop/` | desktop (morpheus, morpheus-nixos) — ultrawide edge-pan and GPU tooling |
| `.config/udev/rules.d/*` | morpheus — NixOS machines carry udev rules in nixos-config |
| `readme.md` | per-branch — describes that branch's OS and host |

## Converging

Invariant: **shared changes flow to every branch, both ways, pairwise; machine-specific files stay with their owner.** There are no convergence tags — the merge-base *is* the last convergence point, computed for free.

In the staging worktree, with `<this>` = this machine's branch and `<other>` = the branch being converged:

1. `config fetch origin` (github.com/jtrv/dotfiles). Always merge **remote-tracking refs**; local copies of other machines' branches go stale.
2. Drift check, both sides at once: `git log --left-right --oneline <this>...origin/<other>` (`<` ours only, `>` theirs only).
3. `git merge <this>` (catch staging up with live; a fast-forward here is fine), then `git merge --no-ff --no-commit origin/<other>`. Both flags matter: once the other machine has merged yours and pushed, your branch is an ancestor of theirs, and a plain merge fast-forwards onto their tree — their owned files included, with nothing left to sweep. `--no-commit` holds a clean merge open for the sweep and the checkpoint.
4. Conflicts: table paths and manifests resolve mechanically per Ownership. Shared files resolve **iteratively with the user** — one at a time, both sides and intent shown, sign-off each. Note rerere is on, with `autoupdate` disabled for this repo via the tracked `~/.config/git/dotfiles-local` include (global git config keeps it on): recorded resolutions reapply but stay unstaged — review each before `git add`.
5. Sweep: run `config-sweep` (`.local/bin/config-sweep`, the table's mechanical half — keep its path lists in sync with the table). It resets every owned path and manifest to what HEAD had, prints the other side's manifest additions, and lists files that mix shared and per-machine hunks for review by hand. It also prints which owned paths they changed (discarded), every incoming deletion, and the files both sides changed that merged without conflict. Restore our own files from the deletion list — deletions propagate silently when our side hadn't touched the file, including ones the other side dropped inside a merge commit, which `git log --diff-filter=D` misses. Check the both-sides list for silent duplication: the same change made on both sides can land twice with no conflict (a doubled `[vad]` TOML section broke voxtype this way). A per-machine hunk kept by hand in a shared file comes back as a clean incoming change the next time the other side merges ours, so it is only ever caught if its file is in the sweep's `mixed` list: list every such file there, and prefer moving the hunk into a host file or a run-time probe so it stops needing review.
6. **Checkpoint — before committing the merge**: show the user the incoming summary, planned deletions/restores, and everything mechanically discarded. Commit only after that, with a plain `git commit` — never `-a` or `add -A`, which would commit a rerere-replayed resolution unreviewed.
7. Take it live: `config status` effectively clean, and no path the merge adds already exists in `$HOME` — live hides untracked files (`status.showUntrackedFiles=no`), and a fast-forward silently overwrites an ignored one: `config diff --name-only --diff-filter=A <this> <this>-wip | while read -r p; do [ -e "$HOME/$p" ] && echo "$p"; done` must print nothing. Then `config merge --ff-only <this>-wip`. A non-ff merge or overlapping dirty files would put the mess in the live `$HOME` tree — the thing staging exists to prevent. If live moved meanwhile, `git merge <this>` in staging again, then fast-forward.
8. Push only when asked: `config push origin <this>`. The pair is fully converged once the other machine runs this same flow there.

### Pending convergence steps

One-time steps a branch owes at its next convergence. Repo edits (`git rm`, file edits) happen during step 5, before the checkpoint; delete the entry in the same merge. Steps that run commands touching `$HOME` (`bun remove -g`, `warehouse`) wait until after step 7's fast-forward and land as an ordinary live commit — run during step 5 they dirty tracked files in live just before the fast-forward.

## Commit workflow (live `$HOME` state, on the live branch)

1. **Status.** Clean tree → say so, stop.
2. **Read every diff** before grouping. Batch files per `diff` call; for large auto-generated tracking files (`cargo/.crates*`, bun `package.json`), `--stat` + a spot-check is enough.
3. **Surface candidates.** Relevant untracked files: ask the user; if added, redo 1–2.
4. **Group into logical commits.** One concern per commit; related files together (a kanata keybind that shells into `niri msg` ships with the niri change). Auto-generated dep files get their own `deps:` commit.
5. **Present the plan** as a table (subject → files) before committing; note if the branch is ahead of origin.
6. **Commit iteratively**, one at a time with a one-line summary so the user can sign off as you go.
7. **Never push unasked. Never `git add -A`/`.`** — named absolute paths only, so a stray file never rides along. Under `~/.config/agents` this is not a nicety: vendored skills are untracked by policy and run to hundreds of files each, so a swept directory buries the real change. See `harnesses.md`.
8. A diff with a small flaw (e.g. useless-use-of-cat): ask before committing.

Messages: conventional-ish `area: summary` (`pi:`, `niri/kanata:`, `waybar:`, `deps:`); body only when the why isn't obvious from the diff. Splitting one file across commits is fine when you can verify the staged version is non-destructive and works on its own — e.g. stage an edited copy with `hash-object -w` + `update-index --cacheinfo`, then check it parses/loads and that the working tree still holds the full change.
