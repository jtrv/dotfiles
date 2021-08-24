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
My kakoune config is almost entirely in [kakrc](https://github.com/JacobTravers/dotfiles/blob/main/.config/kak/kakrc), the items outside of my kakrc that aren't simply managed by [plug.kak](https://github.com/andreyorst/plug.kak) are my [kakship](https://github.com/eburghar/kakship) config in ([starship.toml](https://github.com/JacobTravers/dotfiles/blob/main/.config/kak/starship.toml)) [kakoune.cr](https://github.com/alexherbo2/kakoune.cr) and a single line on
```
~/.config/kak/plugins/kak-rainbower/rc/rainbower.cpp +1088
const char *color = "rgb:171a1e";
```

### kak plugs:
- [alacritty.kak](https://github.com/alexherbo2/alacritty.kak)
- [dynamic-matching.kak](https://github.com/useredsa/dynamic-matching.kak)
- [kakboard](https://github.com/lePerdu/kakboard)
- [kak-lsp](https://github.com/kak-lsp/kak-lsp)
- [kakoune-buffers](https://github.com/delapouite/kakoune-buffers)
- [kakoune.cr](https://github.com/alexherbo2/kakoune.cr)
- [kakoune-mirror](https://github.com/delapouite/kakoune-mirror)
- [kakoune-mysticaltutor](https://github.com/caksoylar/kakoune-mysticaltutor)
- [kakoune-phantom-selection](https://github.com/occivink/kakoune-phantom-selection)
- [kakoune-sudo-write](https://github.com/occivink/kakoune-sudo-write)
- [kakoune-surround](https://github.com/h-youhei/kakoune-surround)
- [kak-rainbower](https://github.com/crizan/kak-rainbower)
- [kakship](https://github.com/eburghar/kakship)
- [kak-tree](https://github.com/ul/kak-tree)
- [number-toggle.kak](https://github.com/evanrelf/number-toggle.kak)
- [plug.kak](https://github.com/andreyorst/plug.kak)
- [smarttab.kak](https://github.com/andreyorst/smarttab.kak)
- [ui.kak](https://github.com/kkga/ui.kak)
