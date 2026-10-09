# Nix

Building, packaging and contributing with Nix on these machines: nixpkgs work in
`~/repos/nixpkgs`, the system flake in `~/repos/nixos-config`, and any repo with a
`flake.nix` or `default.nix`.

## The toolchain here
- `nix` is **Lix** (2.95), not CppNix or Determinate. No lazy trees, no parallel
  eval; flags and error text can differ from upstream Nix docs.
- Daemon settings are `max-jobs = 8`, `cores = 0` on 8 cores: every build may use
  every core, and up to 8 run at once. Check with
  `nix config show | rg '^(max-jobs|cores) '`.
- Substituters: `cache.nixos.org` and `nyx-cache.chaotic.cx`. Most of a closure
  downloads; only changed derivations compile.
- Offline docs before the web: `manix <query>` for option and lib docs,
  `nix-search-tv print | rg <q>` then `nix-search-tv preview 'nixpkgs/<name>'` to
  find packages, `nixos-option <opt>` for this machine's evaluated value.

## Running builds
- **A repo's mise tasks come first.** In `nixos-config` never run raw
  `nix build`, `nixos-rebuild switch` or `nix flake update`; use
  `mise run build|check|switch|update`. `update` with no arguments bumps every
  flake input; `update nixpkgs` bumps just that one, locking from the local clone
  instead of GitHub. `build`/`switch` run `nh`, which already shows build
  progress and the package diff. With no matching task, ask or propose one.
  nixpkgs itself has no tasks, so plain `nix-build` is fine there.
- Local package overrides, including test-skips for packages Hydra hasn't built,
  live in `nixos-config/nixos/pkgs/default.nix`.
  Give each new test-skip a watch probe that says when it can go.
- **Parallel builds starve each other.** With `cores = 0`, two agents each
  compiling Rust oversubscribe the CPU and can push the machine into swap, which
  is slower than running them in turn. `max-jobs` is per client, so the daemon
  does not queue builds from separate commands. When several agents or background
  jobs build at once, serialize them on one lock file:
  `flock <scratchpad>/nix-build.lock nix-build …`. Never kill a build that is
  already running to apply this; let it finish.
- Run long builds in the background with a long timeout; a large Rust or Go
  package takes 10+ minutes.
- To build one branch while switching to another, instantiate first and realise
  the `.drv` later: `nix-instantiate -A <attr>` reads the tree once, then
  `nix-store -r <drv>` no longer cares what is checked out.
- `nix log <drv>` is empty for substituted outputs. To see a real build log,
  rebuild locally (`nix-build --check -A <attr>`).

## Working in ~/repos/nixpkgs
- **The clone is shallow.** Plain `git fetch origin master` sat for 10+ minutes
  with no output on it. Use `git fetch --depth=1 origin master`, which takes
  seconds, and move branches with
  `git rebase --onto origin/master <old-base> <branch>`.
- Checkouts touch tens of thousands of files and are slow. For parallel work use
  one worktree per branch:
  `git worktree add ~/repos/nixpkgs-wt/<pkg> -b <branch> origin/master`, and
  remove it when the branch is merged or abandoned. Stale ones pile up, so when
  starting work run `git worktree prune` and clear out any that are done.
- Package files live at `pkgs/by-name/<first two letters>/<pname>/package.nix`;
  older ones are found with `nix eval --raw -f . <attr>.meta.position`. Store
  paths substituted from a cache have no local deriver, so map a store path to
  its attribute by pname, not with `nix-store -q --deriver`.
- Fetch a package's source to read it: `nix-build --no-out-link -A <attr>.src`.
- Format with `nixfmt` (RFC style); `nixfmt --check <file>` before committing.

## Contributing to nixpkgs
Read `CONTRIBUTING.md` on master when unsure; these are the rules that have
bitten:
- **AI disclosure is mandatory.** Every commit made with an AI tool needs an
  `Assisted-by:` trailer naming the tool, model and version, for example
  `Assisted-by: Claude Code (Claude Opus 5.5)`; the PR description needs its own
  disclosure. This is required by nixpkgs and is not the `Co-authored-by`
  trailer the global commit rule bans; `Co-authored-by` does not satisfy it.
  The user must review every diff before it is submitted.
- One PR per package; commit titles are `<attr>: <change>` (`tailspin: install
  shell completions`).
- Before starting, check for an open PR on the same file:
  `gh pr list -R NixOS/nixpkgs --search "<pname> in:title"`.
- Forking, pushing, opening PRs and commenting are outward-facing: local branches
  only until the user says otherwise.
- Verify by building the attribute and exercising what changed, not by eval
  alone; tick only the template boxes that were actually done.

## Packaging idioms
- **Shell completions:** `installShellFiles` in `nativeBuildInputs`, then in
  `postInstall` either install static files
  (`installShellCompletion completions/foo.{bash,fish,zsh}`) or run the built
  binary:
  ```nix
  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd foo \
      --bash <($out/bin/foo completion bash) \
      --fish <($out/bin/foo completion fish) \
      --zsh <($out/bin/foo completion zsh)
  '';
  ```
  The `canExecute` guard is the documented idiom; an `emulator` variant exists
  for packages that already use one.
- **Man pages:** `installManPage <file>.<section>`; it honours a separate `man`
  output. Generated ones: `$out/bin/foo --gen-man > foo.1; installManPage foo.1`.
- **Rust `build.rs` generators** often write completions and man pages to a
  directory named by an env var: set `env.SHELL_COMPLETIONS_DIR = "completions";`
  and install from it in `postInstall` (`pastel`, `timewall`).
- Generators that print a status line usually send it to stderr; check with
  `cmd 2>/dev/null | head` before trusting the file. Some clap tools demand a
  positional argument even with `--generate`; pass `""`.
- Check results: `fish -n` on fish files, `man -l <page>` on man pages.

## Finding packaging gaps
Fish 4 embeds its own completions: list them with
`fish -c 'status list-files completions'`, not from a directory. The full audit
recipe for completions and man pages that upstream provides but nixpkgs skips,
and the findings so far, are in
`~/notes/agent-wiki/wiki/fish-completion-coverage.md`; the PR queue is
`~/repos/nixpkgs-prs.md`, and PR description drafts are in
`~/repos/nixpkgs-pr-drafts.md`.
