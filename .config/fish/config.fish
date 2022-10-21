fish_vi_key_bindings

# Emulates vim's cursor shape behavior
set fish_cursor_default block blink
set fish_cursor_insert line blink
set fish_cursor_replace_one underscore blink
set fish_cursor_visual block blink



######## SOURCE ########

set -gx XDG_CONFIG_HOME "$HOME"/.config
source "$XDG_CONFIG_HOME"/fish/env.fish

# better history
atuin init fish | source
# bind to ctrl-r in normal and insert mode
bind \cr _atuin_search
bind -M insert \cr _atuin_search



######## FUNCTIONS ########

# add '!!' functionality
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end
bind -Minsert ! __history_previous_command

# add '!$' functionality
function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end
bind -Minsert '$' __history_previous_command_arguments

# other functions can be found in ./functions/



######## ABBREVIATIONS ########

if status --is-interactive
  abbr --add --global cp     'cp -i'
  abbr --add --global mv     'mv -i'
  abbr --add --global rm     'rm -i'
  abbr --add --global npin   'license MIT && gitignore node && covgen jtravers@tutanota.com && npm init -y && volta pin node@lts && git init'
  abbr --add --global gitbit 'git commit --amend --no-edit --date "Sat 01 Jan 2022 16:20:00 PST"'
end



######## ALIASES ########

alias ani     'ani-cli -q high' # watch anime in super ultra HD 8k lossless greenray
alias awman   'wiki-docs-search'
complete -c wiki-docs-search -a '(fd html "/usr/share/doc/arch-wiki/html/en/" | rg -o \'/(\w*).html$\' -r \'$1\')'
alias cat     'bat'
alias cdr     'cd (git rev-parse --show-toplevel)'
alias doas    'doas --'
alias glow    'glow -p'
alias j       '~/.config/lf/wrapper'
alias kish    'k ~/.config/fish/config.fish'
alias konf    'k ~/.config/kak/kakrc'
alias la      'fls -al --color=always' # all files and dirs
alias lc      'lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME' # lazygit for config files
alias lg      'lazygit'
alias lh      'exa -la --color=always --ignore-glob="[a-z]*|[A-Z]*|[0-9]*"' # hidden only
alias ll      'fls -l --color=always' # long format
alias ls      'fls -l --color=always' # preferred listing
alias lsn     'fls' # normal ls for piping
alias lt      'exa -aT --color=always --group-directories-first --git --icons' # tree listing
alias loc     'plocate'
alias m       'math'
alias mirrors '~/.local/bin/update-mirrors' # update mirrors / database
alias mkdir   'mkdir -p'
alias nbg     'feh --randomize --bg-scale --no-fehbg ~/media/pictures/wallpapers/' # change bg
alias off     'systemctl suspend' # save state, enter low-power mode
alias pom     'potato' # shell pomodoro timer
alias q       'exit'
alias wget    "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\""
alias yarn    "yarn --use-yarnrc \"$XDG_CONFIG_HOME\"/yarn/config"



######## KAKOUNE ########

function kakgrep
    set grepargs
    for x in $argv
        set -a grepargs (echo $x | sed -e "s/'/''/g" -e "s/^/'/" -e "s/\$/'/")
    end
    kak -e "grep $(string join -- " " $grepargs); buffer-only; echo; info-buffers"
end
complete -c kakgrep -w rg
alias kg 'kakgrep'

# diff in kak
function kakdiff
  kak -e "diff $argv; buffer-only; echo; info-buffers"
end
alias kd 'kakdiff'

function kifft
  kak -e "difft $argv; buffer-only; echo; info-buffers"
end
alias kdt 'kifft'

function kelta
  kak -e "delta $argv; buffer-only; echo; info-buffers"
end
alias kda 'kelta'

alias kr      'kak -e "mru-files-list; buffer-only; echo; info-buffers"'
alias kl      'kak -e "mru-files-session-load; buffer-only; echo; info-buffers"'
alias kf      'kamp-files'
alias kgi     'kamp-grep'
alias kgl     'kak -e "live-grep; buffer-only;echo "live-grep"; info-buffers"'

alias k       'kamp edit'
alias kval    'kamp get val'
alias kopt    'kamp get opt'
alias kreg    'kamp get reg'
alias kcd-pwd 'cd (kamp get sh pwd)'
alias kcd-buf 'cd (dirname (kamp get val buffile))'
alias kft     'kamp get -b \* opt filetype | sort | uniq' # list file types you're working on
