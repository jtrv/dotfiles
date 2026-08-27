# OS/FS

I run [NixOS](https://nixos.org) on the [CachyOS kernel](https://github.com/chaotic-cx/nyx) with the [BTRFS](https://www.wikiwand.com/en/Btrfs#/Features) filesystem to make rollbacks and backups easy and performant. Packages, services and the disk layout live in [nixos-config](https://codeberg.org/jtrv/nixos-config); this repo is only what nix can't declare.

# Config

All my configs are managed in a [git --bare repo](https://www.atlassian.com/git/tutorials/dotfiles). I usually use [lazygit](https://github.com/jesseduffield/lazygit) to make managing them easy with the following alias in [`.config/fish/config.fish`](https://github.com/jtrv/dotfiles/blob/main/.config/fish/config.fish):

```sh
  alias lc 'lazygit --git-dir=$HOME/.config/dotfiles/ --work-tree=$HOME'
```

I also have a few config related scripts that can be found in [`.local/bin/`](https://github.com/JacobTravers/.cfg/blob/main/.local/bin/) (prepended with "config"), and corresponding fish-completions in [.config/fish/completions/](https://github.com/JacobTravers/.cfg/blob/main/.config/fish/completions/).

This branch runs on my thinkpad, so it pairs with the `thiccpad` host in nixos-config: [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq), [thermald](https://wiki.debian.org/thermald) and [powertop](https://github.com/fenrus75/powertop) for battery life, and suspend-then-hibernate on lid close.

The [Warehouse](https://github.com/jtrv/dotfiles/blob/morpheus/.config/warehouse) is a manifest of the packages nix doesn't install (cargo, bun, uv, kakoune, tree-sitter grammars) so I can diff between devices ([config-diff](https://github.com/jtrv/dotfiles/blob/morpheus/.local/bin/config-diff)); the nixos bootstrap unit replays those lists on a fresh install. It also makes for a good resource for curious config readers.
