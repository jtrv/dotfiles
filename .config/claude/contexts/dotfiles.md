# dotfiles

One repo, two working trees:

- **Live**: bare git dir `$DOTFILES` (`~/.config/dotfiles`), work-tree `$HOME`, branch = machine name (`thiccpad`, `morpheus`, …). Drive it with
  `command git --git-dir="$DOTFILES" --work-tree="$HOME" <cmd>` (the `config` wrapper in `~/.local/bin` does exactly this). Use `command git`, not a shell alias. Pathspecs match against the cwd — pass **absolute `$HOME/...` paths**, never the `../../` paths `status` prints.
- **Staging**: `~/repos/dotfiles`, a linked `git worktree` of the same repo on branch `<machine>-wip` (e.g. `thiccpad-wip`). Plain `git` works there. Edit and test here without touching the live tree.

Because both trees share one object store and ref set, commits, branches, and tags made in either are instantly visible in the other — there is no fetch/push between them.

**Never check out the live machine branch in the staging worktree.** The `$HOME` tree is ad-hoc (`--work-tree` flag), so git's double-checkout guard can't see it; two trees on one branch means a commit in one shows phantom changes in the other. Staging stays on `<machine>-wip`.

## Machine profiles

- **thiccpad** — NixOS laptop, no home-manager. Never bring arch-isms (`warehouse/arch`, pacman config) or desktop-only bits (evdi/hermes-streaming, other machines' systemd user units) onto this branch; user units come from nixos-config, not `~/.config/systemd/user`.
- **morpheus** — arch desktop. Owns `warehouse/arch`, `kanata-morpheus.service`, evdi/hermes-streaming.
- **morpheus-nixos** — the desktop's in-progress NixOS migration; replaces `morpheus` at cutover. NixOS rules as for thiccpad, desktop ownership as for morpheus. Until cutover it converges as a third party — with three branches, convergence is pairwise merges, and each pair's state is judged separately.

### Machine-specific paths

Anything not listed here is shared. When a merge surfaces a new ambiguous path, ask the user which it is — then add the decision to this list.

| Path | Ownership |
|---|---|
| `warehouse/arch`, `.config/pacman/` | morpheus (arch) |
| `warehouse/uv` additions | morpheus; thiccpad keeps it empty (nixos-config carries tools) |
| `.config/systemd/user/*` units | owning machine only; NixOS machines track none (units come from nixos-config) |
| `.local/bin/waybar-sleep-inhibit` + its waybar config/style hunks | morpheus |
| evdi/hermes-streaming (packages, virtual-display pinning) | morpheus |
| bun global `package.json`, cargo `.crates*` | per-machine local state — never merged, each side keeps its own |
| `kanata/*.kbd` | on every branch, per-machine by filename (`morpheus.kbd`, `thiccpad.kbd`, `shared.kbd`) — the good pattern; name-space new machine-specific files like this instead of adding rows here |

Machine-specific files make cross-machine merges lie in both directions: a merge can resurrect files this machine purged, and a deletion committed here propagates when the other machine merges this branch — *silently* while they haven't modified the file since the merge-base, as a modify/delete conflict if they have. Either way, after every cross-machine merge, sweep against the profile: re-delete what isn't for this machine, and restore this machine's own files if the incoming branch deleted them. `config log --diff-filter=D --name-status HEAD..<their-ref> -- <path>` lists what their side dropped — the `HEAD..` range matters; without it the whole shared history's deletions appear.

## Converging

The invariant: **shared (non-machine-specific) changes flow to every branch, both ways; machine-specific files stay on the branch that owns them** (see Machine profiles). A convergence is complete only when both sides have merged the other's shared content — each branch's `converged/<branch>` tag marks where that last held. Merging the other machine in covers one direction; the other completes when they pull and merge back.

Which branch gets which work:

- **Live `<machine>` branch**: only commits that capture live `$HOME` state (the commit workflow below). Nothing else lands here directly.
- **Staging `<machine>-wip` branch**: everything else — new configs, experiments, and **cross-machine merges**. Resolve and inspect there, then take it live with `config merge --ff-only <machine>-wip`, and only with `config status` clean first — dirty live files abort the merge, and a non-ff merge would put conflict markers in the live `$HOME` tree, the exact thing staging exists to prevent. If live has moved, merge live into wip first, then fast-forward.

Cross-machine: machine branches meet via the bare repo's `origin` remote (github.com/jtrv/dotfiles). With `<this>` = the machine you are on and `<other>` = the branch being converged: `config fetch origin`, then in the staging worktree `git -C ~/repos/dotfiles merge <this>` (catch up with live first), then `git -C ~/repos/dotfiles merge origin/<other>` — always the **remote-tracking ref**, never a local copy of another machine's branch (local copies go stale). Sweep per the machine profile, inspect, then fast-forward live.

Conflict handling during the merge:

- **Machine-specific files and local-state manifests** (bun global package.json, cargo `.crates*`): resolve mechanically — profile decides keep/drop, manifests take this machine's side.
- **Shared files**: work through conflicts **iteratively with the user** — one at a time, show both sides and what each machine intended, propose a resolution, get sign-off before the next.
- **rerere is on with `rerere.autoupdate`**: recorded resolutions reapply *and stage themselves* automatically, bypassing the iterative review. After a conflicted merge, run `config rerere diff` and re-inspect any file that resolved without input before committing.
- After resolving, scan the merged result for silent duplication: the same change made on both sides can land twice at different offsets with no conflict (a doubled `[vad]` TOML section broke voxtype this way).

Each machine creates and moves its own lightweight `converged/<branch>` tag at its own reconcile — a branch without one simply hasn't converged since this workflow began. The tag marks the last commit that branch reconciled with the others; everything after it is unreconciled drift. Diff against it instead of re-deriving what changed:

- `config log --oneline converged/<branch>..<branch>` and `config diff converged/<branch>..<branch>`
- Staging side: `git -C ~/repos/dotfiles log --oneline converged/<branch>..HEAD` plus `status` for uncommitted edits.

After a reconcile, move the tag to the agreed commit (the merge-base of the HEADs if unsure):

```sh
config -c tag.gpgsign=false tag -f converged/<branch> <agreed-commit>
```

Always pass `-c tag.gpgsign=false` — `tag.gpgsign=true` is set globally and a signed tag fires a gpg pinentry an agent session can't answer. Pushing a moved tag needs force, but **never `push -f` with the branch in the same command** — `-f` applies to every refspec on the line and can clobber the remote branch. Scope the force to the tag alone:

```sh
config push origin <branch> +refs/tags/converged/<branch>:refs/tags/converged/<branch>
```

## Commit workflow

1. **Status.** Clean tree → say so, stop.
2. **Read every diff** before grouping. Batch files per `diff` call. For large auto-generated tracking files (`.local/share/cargo/.crates*`, `bun/.../package.json`), a `--stat` + one spot-check is enough.
3. **Surface candidates.** If relevant untracked files should ride along, ask the user; if added, redo 1–2.
4. **Group into logical commits.** One concern per commit; keep related files together (e.g. a kanata keybind that shells into `niri msg` ships with the niri change). Auto-generated dep files get their own `deps:` commit.
5. **Present the plan** as a table (commit subject → files) before committing. Note if the branch is ahead of origin.
6. **Commit iteratively.** One at a time, each with a one-line summary so the user can sign off as you go.
7. **Never push** unless explicitly asked. Never `git add -A`/`.` — named absolute paths only, so a stray file never rides along.
8. A diff with a small flaw (e.g. useless-use-of-cat): ask the user whether to fix it before committing.

Commit messages: conventional-ish `area: summary` subject (`pi:`, `niri/kanata:`, `waybar:`, `deps:`). Body only when the "why" isn't obvious from the diff.

Splitting one file across commits: avoid. If genuinely needed, hand the user lazygit (`lc` alias) and recommend what to stage with what message.
