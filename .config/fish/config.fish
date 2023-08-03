fish_default_key_bindings

######## SOURCE ########

set -gx XDG_CONFIG_HOME "$HOME"/.config
source "$XDG_CONFIG_HOME"/fish/env.fish

atuin init fish | source


######## KEY-BINDINGS ########

bind ! __history_previous_command             # add '!!' functionality, req ./functions/__history_previous_command.fish
bind '$' __history_previous_command_arguments # add '!$' functionality, req ./functions/__history_previous_command_arguments.fish

bind \cr _atuin_search
bind \cj edit_command_buffer


######## ABBREVIATIONS ########

if status --is-interactive
  abbr --add --global cp     'cp -i'
  abbr --add --global mv     'mv -i'
  abbr --add --global rm     'rip'
  abbr --add --global gitbit 'git commit --amend --no-edit --date "Sat 01 Jan 2022 16:20:00 PST"'
end


######## ALIASES ########

alias acme    "acme.sh --home \"$XDG_CONFIG_HOME\"/acme.sh/"
alias ani     'ani-cli -q best' # weeb out in S-rank ultra-fidelity 8k lossless greenray
alias cat     'bat'
alias cdr     'cd (git rev-parse --show-toplevel)'
alias cols    'column -c $COLUMNS'
alias doas    'doas --'
alias feh     'feh --scale-down --image-bg black'
alias fzfp    'fzf --preview="bat --color=always {}"'
alias glow    'glow -p'
alias hn      'clx -an --no-less-verify'
alias j       '~/.config/lf/wrapper'
alias kenv    'k ~/.config/fish/env.fish'
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
alias m       'qalc'
alias mdc     'mdcat --columns 70'
alias mirrors '~/.local/bin/update-mirrors' # update mirrors / database
alias mkdir   'mkdir -p'
alias nbg     'feh --randomize --bg-scale --no-fehbg ~/media/pictures/wallpapers/' # change bg
alias off     'systemctl suspend' # save state, enter low-power mode
alias pom     'potato' # shell pomodoro timer
alias q       'exit'
alias thes    'thesauromatic'
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

function kakfd
  k (fd $argv)
end
alias kd 'kakfd'
complete -c kakfd -w fd

function kakdiff
  kak -e "diff $argv; buffer-only; echo; info-buffers"
end
alias kif 'kakdiff'

function kakdifft
  kak -e "difft $argv; buffer-only; echo; info-buffers"
end
alias kift 'kakdifft'

function kelta
  kak -e "delta $argv; buffer-only; echo; info-buffers"
end
alias kda 'kelta'

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

# Start X at login
if status is-login
  if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
    exec startx -- -keeptty
  end
end
