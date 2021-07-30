# OS/FS
I run [Arch Linux](https://wiki.archlinux.org/title/Arch_Linux) on the [Zen kernel](https://wiki.archlinux.org/title/Kernel) with the [BTRFS](https://www.wikiwand.com/en/Btrfs#/Features) filesystem utilizing incremental snapshots in [Snapper](https://www.wikiwand.com/en/Btrfs#/Features) and [grub-btrfs](https://github.com/Antynea/grub-btrfs) in case I need to revert breaking changes from the grub menu on my machine. (haven't needed to yet so :fingers_crossed:)

# dotfiles
All my configs managed with a [git --bare repo](https://www.atlassian.com/git/tutorials/dotfiles), usually in [lazygit](https://github.com/jesseduffield/lazygit) with the following aliases in [.config/fish/config.fish](https://github.com/JacobTravers/dotfiles/blob/main/.config/fish/config.fish#L148): 

```
# config = git for ~/dotfiles
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

# lc = lazygit for ~/dotfiles
alias lc='lazygit --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
```

## warehouse
[warehouse](https://github.com/JacobTravers/dotfiles/blob/main/.config/fish/functions/warehouse.fish) is a fish script I made to keep a record of the installed packages on my machine, it concatenates package names from various locations to [.warehouse](https://github.com/JacobTravers/dotfiles/blob/main/.warehouse) in my home directory. This also serves as a quick resource for anybody curious about the packages on my system.

## kakrc
My kakoune config is almost entirely in [kakrc](https://github.com/JacobTravers/dotfiles/blob/main/.config/kak/kakrc), the only files outside of my kakrc that aren't simply managed by [plug.kak](https://github.com/andreyorst/plug.kak) are my [kakship](https://github.com/eburghar/kakship) config ([starship.toml](https://github.com/JacobTravers/dotfiles/blob/main/.config/kak/starship.toml)) and my customized [kak-rainbower](https://github.com/crizan/kak-rainbower) files in this [gist](https://gist.github.com/JacobTravers/fb509fd4c9c44a2c2767cadf775305ab).

### kak plugs:
- [plug.kak](https://github.com/andreyorst/plug.kak)
- [kakoune-mysticaltutor](https://github.com/caksoylar/kakoune-mysticaltutor)
- [kakship](https://github.com/eburghar/kakship)
- [number-toggle.kak](https://github.com/evanrelf/number-toggle.kak)
- [kak-rainbower](https://github.com/crizan/kak-rainbower)
- [smarttab.kak](https://github.com/andreyorst/smarttab.kak)
- [kak-lsp](https://github.com/kak-lsp/kak-lsp)
- [alacritty.kak](https://github.com/alexherbo2/alacritty.kak)
- [kakoune-sudo-write](https://github.com/occivink/kakoune-sudo-write)
- [kakboard](https://github.com/lePerdu/kakboard)
- [dynamic-matching.kak](https://github.com/useredsa/dynamic-matching.kak)
- [kakoune-buffers](https://github.com/delapouite/kakoune-buffers)
- [kakoune-phantom-selection](https://github.com/occivink/kakoune-phantom-selection)
- [kakoune-surround](https://github.com/h-youhei/kakoune-surround)
- [kak-tree](https://github.com/ul/kak-tree)
- [ui.kak](https://github.com/kkga/ui.kak)
