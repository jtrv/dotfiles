# OS/FS

I run [Arch Linux](https://wiki.archlinux.org/title/Arch_Linux) on the [CachyOS kernel](https://wiki.archlinux.org/title/Kernel) with the [BTRFS](https://www.wikiwand.com/en/Btrfs#/Features) filesystem to make rollbacks and backups easy and performant.

# Config

All my configs are managed in a [git --bare repo](https://www.atlassian.com/git/tutorials/dotfiles). I usually use [lazygit](https://github.com/jesseduffield/lazygit) to make managing them easy with the following alias in [`.config/fish/config.fish`](https://github.com/jtrv/dotfiles/blob/main/.config/fish/config.fish):

```sh
  alias lc 'lazygit --git-dir=$HOME/.config/dotfiles/ --work-tree=$HOME'
```

I also have a few config related scripts that can be found in [`.local/bin/`](https://github.com/JacobTravers/.cfg/blob/main/.local/bin/) (prepended with "config"), and corresponding fish-completions in [.config/fish/completions/](https://github.com/JacobTravers/.cfg/blob/main/.config/fish/completions/).

The [Warehouse](https://github.com/jtrv/dotfiles/blob/morpheus/.config/warehouse) is a manifest for most of my installed packages so I can diff between devices ([config-diff](https://github.com/jtrv/dotfiles/blob/morpheus/.local/bin/config-diff)) or do a new install easily e.g. `paru -S (cat "/home/$USER/.config"/warehouse/arch)`. It also makes for a good resource for curious config readers.
