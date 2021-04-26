# Defined via `source`

### EXPORT ###

set fish_greeting           # Supresses fish's intro message
set EDITOR "kak -c sesh"    # kakoune in default sesh
set VISUAL "kak -c sesh"  	# kakoune in default sesh
set SKIM_DEFAULT_COMMAND "fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."

# smarter 'cd' alternative in rust
zoxide init fish | source

# better prompt in rust
starship init fish | source

### "bat" as manpager
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Functions needed for !! and !$
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
# ex: backup file.txt
# result: copies file as file.txt.bak
function backup --argument filename
  cp $filename $filename.bak
end

# Function for copying files and directories, even recursively.
# ex: copy DIRNAME LOCATIONS
# result: copies the directory and all of its contents.
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
# ex: echo 1 2 3 | coln 3
# output: 3
function coln
  while read -l input
    echo $input | awk '{print $'$argv[1]'}'
  end
end

# Function for printing a row
# ex: seq 3 | rown 3
# output: 3
function rown --argument index
  sed -n "$index p"
end

# Function for ignoring the first 'n' lines
# ex: seq 10 | skip 5
# results: prints everything but the first 5 lines
function skip --argument n
  tail +(math 1 + $n)
end

# Function for taking the first 'n' lines
# ex: seq 10 | take 5
# results: prints only the first 5 lines
function take --argument number
  head -$number
end

### END OF FUNCTIONS ###



### ABBREVIATIONS ###

if status --is-interactive
    # use rip instead of rm
    abbr --add --global rm 'rip'
    abbr --add --global sudo 'doas'
    abbr --add --global skrg 'sk --ansi -i -c \'rg --color=always --line-number "{}"\''
end

### ALIASES ###

# root privileges
alias doas="doas --"

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'

# nnn
alias n='nnn'

# broot
alias bs='broot --sizes'

# Changing "ls" to "exa"
alias ls='exa -al --color=always --group-directories-first' # my preferred listing
alias la='exa -a --color=always --group-directories-first'  # all files and dirs
alias ll='exa -l --color=always --group-directories-first'  # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing
alias l.='exa -a | egrep "^\."'

# changing "cat" to "bat"
alias cat='bat'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# get fastest mirrors
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

# config = git for ~/dotfiles
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

# lazyconf = lazygit for ~/dotfiles
alias lazyconf='lazygit --git-dir=$HOME/dotfiles/ --work-tree=$HOME'


# Start X at login
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec startx -- -keeptty
    end
end
