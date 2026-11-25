if status is-interactive
  # Source a tool's generated init script from a cache, regenerated when the binary
  # changes (a new store path on NixOS, a new mtime on Arch) or the command or
  # CARAPACE_BRIDGES (which shapes carapace's output) does. Saves ~40 ms per shell.
  function __cached_init -a name
    set -l bin (command -s $argv[2]); or return
    set -l key "# "(path resolve $bin) (path mtime $bin) $argv[2..] $CARAPACE_BRIDGES
    set -l f $__fish_cache_dir/init/$name.fish
    if not test -r $f; or not read -l first <$f; or test "$first" != "$key"
      mkdir -p (path dirname $f)
      begin; echo $key; $argv[2..]; end >$f.tmp; and mv $f.tmp $f
    end
    source $f
  end

  __cached_init atuin        atuin init fish
  # Never cached: the output hard-codes the current $PATH, so a cached copy would
  # restore whatever PATH the generating shell happened to have.
  mise activate fish | source
  __cached_init starship     starship init fish --print-full-init

  # starship's slow git modules (its `git` profile) render in the background through
  # fish-async-prompt (nixos-config packages.nix) and reach the prompt's top line via
  # STARSHIP_GIT. The plugin's child is not interactive, so it autoloads
  # functions/__starship_git.fish. While it runs, the last git info shows dimmed.
  # Without the plugin (e.g. on a host that lacks it) git renders synchronously.
  set -g async_prompt_functions __starship_git
  function fish_right_prompt; end
  function __starship_git_loading_indicator -a last_prompt
    set_color brblack
    string replace -ra '\e\[[0-9;]*m' '' -- $last_prompt
    set_color normal
  end
  # Reads the plugin's output file rather than calling __starship_git: before the
  # plugin swaps that function out on the first prompt, calling it would run git
  # synchronously. USR1 is the plugin's "render finished" signal.
  function __starship_git_env --on-event fish_prompt --on-signal SIGUSR1
    if functions -q __async_prompt_fire
      set -l f $__async_prompt_tmpdir/{$fish_pid}___starship_git
      test -e $f; and set -gx STARSHIP_GIT (string collect <$f); or set -e STARSHIP_GIT
    else
      set -gx STARSHIP_GIT (__starship_git | string collect)
    end
  end

  # carapace's 2,500 `complete` lines are the biggest remaining cost (~20 ms), and
  # nothing needs them before the first Tab. fish_prompt fires *before* the prompt is
  # drawn, so it only arms a signal; the handler runs once fish is idle at the prompt.
  # USR2, not USR1: fish-async-prompt repaints on USR1.
  function __carapace_arm --on-event fish_prompt
    functions -e __carapace_arm
    command sh -c "sleep 0.05; kill -USR2 $fish_pid" &
    disown
  end
  function __carapace_load --on-signal SIGUSR2
    functions -e __carapace_load
    __cached_init carapace carapace _carapace fish
  end
end
