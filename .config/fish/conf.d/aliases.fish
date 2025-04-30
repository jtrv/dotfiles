if status is-interactive

alias ani     "ani-cli -q best --skip" # weeb out in S-rank ultra-fidelity 8k lossless greenray
alias boi     "wikiman"
alias bls     "/bin/ls"
alias cat     "bat"
alias cbin    "yes | cargo binstall"
alias cdr     "cd (git rev-parse --show-toplevel)"
alias cg      "config-grep"
alias claude  "SHELL=/bin/bash ~/.local/share/bun/bin/claude"
alias clip    "clipcat-menu --finder='fzf'"
alias cncr    "conceal restore"
alias cols    "column -c '$COLUMNS'"
alias cp      "cp -i"
alias d       "devour"
alias dg      "diff-grep"
alias feh     "feh --scale-down --image-bg black"
alias fp      "sk --preview='bat --color=always {}'"
alias ghs     "gh auth switch"
alias hn      "clx -an --no-less-verify"
alias jls     "jless -r"
alias j       "yazi"
alias kab     "k ~/.config/fish/conf.d/abbreviations.fish"
alias kakrc   "k ~/.config/kak/kakrc"
alias kal     "k ~/.config/fish/conf.d/aliases.fish"
alias kenv    "k ~/.config/fish/conf.d/env.fish"
alias kenvs   "k ~/.config/fish/conf.d/envs.fish"
alias kish    "k ~/.config/fish/config.fish"
alias k       "kak"
alias la      "fls -alh --color=always" # all files and dirs
alias lc      "lazygit --git-dir='$DOTFILES' --work-tree='$HOME'" # lazygit for config files
alias lg      "lazygit"
alias lh      "eza -la --color=always --ignore-glob='[a-z]*|[A-Z]*|[0-9]*'" # hidden only
alias ll      "eza -l --color=always --git" # long format
alias lmk     "lemmeknow"
alias loc     "plocate"
alias ls      "fls -lh --color=always" # preferred listing
alias lt      "erd -HIl --color=force" # tree listing
alias mdc     "mdcat --columns=70"
alias mkd     "mkdir -p"
alias m       "qalc"
alias mrb     "mise run build"
alias mrc     "mise run clean"
alias mrd     "mise run develop"
alias mrf     "mise run format"
alias mrl     "mise run lint"
alias mr      "mise run"
alias mrs     "mise run serve"
alias mv      "mv -i"
alias nbg     "feh --randomize --bg-scale --no-fehbg ~/media/pictures/wallpapers/" # change bg
alias o       "xdg-open"
alias py      "python"
alias q       "exit"
alias rm      "cnc"
alias tf      "terraform"
alias thes    "thesauromatic"
alias tv      "lobster"
alias wget    "wget2 --hsts-file='$XDG_DATA_HOME/wget-hsts'"
alias wh      "wormhole-rs"

end
