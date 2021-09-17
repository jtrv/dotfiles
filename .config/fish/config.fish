fish_vi_key_bindings

### EXPORT ###
set -gx fish_greeting

set -gx EDITOR "kak"
set -gx VISUAL "kak"

set -gx GOPATH         "/home/sugimoto/build/go"
set -gx CARGO_HOME     "/home/sugimoto/build/cargo"
set -gx RUSTC_WRAPPER  "/home/sugimoto/build/cargo/bin/sccache"
set -gx NPM_CONFIG_USERCONFIG  "~/.config/npm/npmrc"
set -gx SKIM_DEFAULT_COMMAND   "fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."
set -gx FZF_DEFAULT_OPTS       "--ansi --multi --tabstop=2 --color=dark --preview='bat --color=always {}'" 
set -gx CALIBRE_USE_DARK_PALETTE  "yes"
set NAVI_CONFIG_YAML       "~/.config/navi/config.yaml"

# better prompt
starship init fish | source

# smarter 'cd' (z)
zoxide init fish | source

# cli cheatsheet widget
navi widget fish | source


### FUNCTIONS ###

# kakoune as manpager
function man
  kak -e "man $argv"; 
end

# needed for !! and !$
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

# The bindings for !! and !$
if [ $fish_key_bindings = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Function for creating a backup file
#   ex: backup file.txt
#   result: copies file as file.txt.bak
function backup --argument filename
  cp $filename $filename.bak
end

# Function for copying files and directories, even recursively.
#   ex: copy DIRNAME LOCATIONS
#   result: copies the directory and all of its contents.
function copy
  set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
      set from (echo $argv[1] | trim-right /)
      set to (echo $argv[2])
    command cp -r $from $to
    else
    command cp $argv
    end
end

# Function for printing a column (splits input on whitespace)
#   ex: echo 1 2 3 | coln 3
#   output: 3
function coln
  while read -l input
  echo $input | awk '{print $'$argv[1]'}'
  end
end

# Function for printing a row
#   ex: seq 3 | rown 3
#   output: 3
function rown --argument index
  sed -n "$index p"
end

# Function for ignoring the first 'n' lines
#   ex: seq 10 | skip 5
#   results: prints everything but the first 5 lines
function skip --argument n
  tail +(math 1 + $n)
end

# Function for taking the first 'n' lines
#   ex: seq 10 | take 5
#   results: prints only the first 5 lines
function take --argument number
  head -$number
end


### ABBREVIATIONS ###

if status --is-interactive
  abbr --add --global cp   'cp -i' 
  abbr --add --global mv   'mv -i' 
  abbr --add --global sudo 'doas'
  abbr --add --global skrg 'sk --ansi -i -c \'rg --color=always --line-number "{}"\''
end


### ALIASES ###

# root privileges
alias doas 'doas --'
alias d    'doas --'

alias bc  'kalk'
alias bs  'broot --sizes'
alias btm 'btm --battery'
alias cat 'bat'
alias j   'joshuto'
alias lg  'lazygit'

# (mons is POSIX, bass runs it in bash)
alias mons 'bass mons'

# git for ~/dotfiles
alias config '/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

# lazygit for ~/dotfiles
alias lc 'lazygit --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

# Changing "ls" to "exa"
alias ls 'exa -l --color=always --group-directories-first --git --icons' # my preferred listing
alias la 'exa -al --color=always --group-directories-first --git --icons'  # all files and dirs
alias lh 'exa -al --color=always --group-directories-first --git --icons --ignore-glob="[a-z]*|[A-Z]*|[0-9]*"'
alias ll 'exa -l --color=always --group-directories-first --git --icons'  # long format
alias lt 'exa -aT --color=always --group-directories-first --git --icons' # tree listing

# Colorize grep output (good for log files)
alias grep  'grep --color=auto'
alias egrep 'egrep --color=auto'
alias fgrep 'fgrep --color=auto'

# get fastest mirrors
alias mirror  "doas reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord "doas reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors "doas reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora "doas reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

## get top process eating memory
alias psmem   'ps auxf | sort -nr -k 4'
alias psmem10 'ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias pscpu   'ps auxf | sort -nr -k 3'
alias pscpu10 'ps auxf | sort -nr -k 3 | head -10'

# kakoune coderunner
alias k    'kcr edit'
alias K    'kcr-fzf-shell'
alias KK   'K --working-directory .'
alias ks   'kcr shell --session'
alias kl   'kcr list'
alias a    'kcr attach'
alias :    'kcr send'
alias :br  'KK broot'
alias :cat 'kcr cat --raw'

alias val 'kcr get --value'
alias opt 'kcr get --option'
alias reg 'kcr get --register'

# Start X at login
if status is-login
  if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
    exec startx -- -keeptty
  end
end

