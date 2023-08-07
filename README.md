# OS/FS

I run [Arch Linux](https://wiki.archlinux.org/title/Arch_Linux) on the [Zen kernel](https://wiki.archlinux.org/title/Kernel) with the [BTRFS](https://www.wikiwand.com/en/Btrfs#/Features) filesystem utilizing [Timeshift](https://github.com/teejee2008/timeshift), [timeshift-autosnap](https://gitlab.com/gobonja/timeshift-autosnap), and [grub-btrfs](https://github.com/Antynea/grub-btrfs) in case I need to revert breaking changes from the grub menu on my machine.

# Config

All my configs managed with a [git --bare repo](https://www.atlassian.com/git/tutorials/dotfiles), usually in [lazygit](https://github.com/jesseduffield/lazygit) with the following alias in [`.config/fish/config.fish`](https://github.com/JacobTravers/.cfg/blob/main/.config/fish/config.fish):

```sh
  alias lc 'lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```

I also have a few config related scripts that can be found in [`.local/bin/`](https://github.com/JacobTravers/.cfg/blob/main/.local/bin/) prepended with "config", as well as fish-completions in [.config/fish/completions/](https://github.com/JacobTravers/.cfg/blob/main/.config/fish/completions/).

This branch runs on my thinkpad so I used the arch wiki for specific tweaks for my model as well as [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq), [thermald](https://wiki.debian.org/thermald), and [powertop](https://github.com/fenrus75/powertop) for optimal battery life and performance.

# Kakrc

My kakoune config is almost entirely in [kakrc](https://github.com/JacobTravers/.cfg/blob/main/.config/kak/kakrc), the only items outside of it are post-merge hooks for [kak-lsp](https://github.com/kak-lsp/kak-lsp), [kakpipe](https://github.com/eburghar/kakpipe), [kakship](https://github.com/eburghar/kakship), and [kampliment](https://github.com/vbauerster/kampliment).

# Warehouse

The [Warehouse](https://github.com/JacobTravers/.cfg/blob/morpheus/.config/warehouse) is where I log my installed packages, so I can diff them between devices ([config-diff](https://github.com/JacobTravers/.cfg/blob/morpheus/.local/bin/config-diff)) and easily reinstall them if needed with something like `paru -S (cat "/home/sugimoto/.config"/warehouse/arch)`. It's also a resource for curious config readers to see what packages I like to use.
