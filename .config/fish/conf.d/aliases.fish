if status is-interactive

alias ani     "ani-cli -q best --skip" # weeb out in S-rank ultra-fidelity 8k lossless greenray
alias boi     "wikiman"
alias cat     "bat"
alias cbin    "yes | cargo binstall"
alias cdr     "cd (git rev-parse --show-toplevel)"
alias cg      "config-grep"
alias claude  "SHELL=/bin/bash ~/.local/share/bun/bin/claude"
alias clip    "clipcat-menu --finder='fzf'"
alias cncr    "conceal restore"
alias cols    "column -c '$COLUMNS'"
alias d       "devour"
alias feh     "feh --scale-down --image-bg black"
alias fp      "sk --preview='bat --color=always {}'"
alias glow    "glow -p"
alias hn      "clx -an --no-less-verify"
alias jls     "jless -r"
alias j       "yazi"
alias k       'kak'
alias kab     'k ~/.config/fish/conf.d/abbreviations.fish'
alias kakrc   'k ~/.config/kak/kakrc'
alias kal     'k ~/.config/fish/conf.d/aliases.fish'
alias kenv    'k ~/.config/fish/conf.d/env.fish'
alias kish    'k ~/.config/fish/config.fish'
alias la      "fls -al --color=always" # all files and dirs
alias lc      "lazygit --git-dir='$DOTFILES' --work-tree='$HOME'" # lazygit for config files
alias lg      "lazygit"
alias lh      "eza -la --color=always --ignore-glob='[a-z]*|[A-Z]*|[0-9]*'" # hidden only
alias ll      "eza -l --color=always --git" # long format
alias lmk     "lemmeknow"
alias loc     "plocate"
alias ls      "fls -l --color=always" # preferred listing
alias lt      "erd -HIl --color=force" # tree listing
alias mdc     "mdcat --columns=70"
alias mkd     "mkdir -p"
alias m       "qalc"
alias nbg     "feh --randomize --bg-scale --no-fehbg ~/media/pictures/wallpapers/" # change bg
alias o       "xdg-open"
alias py      "python"
alias q       "exit"
alias tf      "terraform"
alias thes    "thesauromatic"
alias tv      "lobster"
alias wget    "wget2 --hsts-file='$XDG_DATA_HOME/wget-hsts'"
alias wh      "wormhole-rs"

end
