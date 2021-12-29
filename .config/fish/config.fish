fish_vi_key_bindings

######## SOURCE ########

# better prompt
starship init fish | source

# smarter 'cd' (z)
zoxide init fish | source

# cli cheatsheet widget
navi widget fish | source


######## FUNCTIONS ########

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

function how
  kak -e "kakpipe -n how -- hors -a -n 2 -p never $argv"
end

# pretty print markdown files in kakoune
function md
  kak -e "kakpipe -n mdcat -- mdcat $argv"
end


######## ABBREVIATIONS ########

if status --is-interactive
  abbr --add --global cp   'cp -i'
  abbr --add --global mv   'mv -i'
  abbr --add --global sudo 'doas'
  abbr --add --global npin 'license MIT && gitignore node && covgen jtravers@tutanota.com && npm init -y && volta pin node@lts && git init'
  abbr --add --global gitbit 'git commit --amend --no-edit --date "Sat 01 Jan 2022 16:20:07 PST"'
end


######## ALIASES ########

# q to exit
alias q 'exit'

# root privileges
alias doas 'doas --'
alias d    'doas --'

alias bc  'kalk'
alias cat 'bat'
alias j   'lf'
alias lg  'lazygit'

# git for ~/.cfg
alias config '/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# lazygit for ~/.cfg
alias lc 'lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# (mons is POSIX, bass runs it in bash)
alias mons 'bass mons'

# Changing "ls" to "exa"
alias ls 'exa -l --color=always --group-directories-first --git --icons' # my preferred listing
alias la 'exa -al --color=always --group-directories-first --git --icons'  # all files and dirs
alias lh 'exa -al --color=always --group-directories-first --git --icons --ignore-glob="[a-z]*|[A-Z]*|[0-9]*"'
alias ll 'exa -l --color=always --group-directories-first --git --icons'  # long format
alias lt 'exa -aT --color=always --group-directories-first --git --icons' # tree listing

# get fastest mirrors
alias mirror  "doas reflector --save /etc/pacman.d/mirrorlist --protocol https --country US --latest 200 --sort age"

# change bg
alias newbg 'feh --randomize --bg-scale --no-fehbg ~/pictures/wallpapers/'

# use pnpm instead of npm
alias np  'pnpm'
alias npx 'pnpm dlx'


######## KAKOUNE ########

# kakoune as manpager
function man
set HAS_MANUAL (/usr/bin/man $argv | rg "No manual entry for $argv" | wc -l)
  if [ $HAS_MANUAL = 0 ]
    kak -e "kakpipe -n $argv -- $argv --help"
  end
  if [ $HAS_MANUAL = 1 ]
    kak -e "man $argv"
  end
end

# kakoune grep
function kg
  kak -e "grep $argv";
end

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


######## EXPORTS ########

set -gx fish_greeting

set -gx CALIBRE_USE_DARK_PALETTE "yes"
set -gx FZF_DEFAULT_OPTS         "--ansi --color=dark --multi --tabstop=2  --preview='bat --color=always {}' --preview-window border-vertical"
set -gx GREETING                 "/home/sugimoto/.config/greeting"
set -gx HORS_ENGINE              "google"
set     NAVI_CONFIG_YAML         "/home/sugimoto/.config/navi/config.yaml"
set -gx NPM_CONFIG_USERCONFIG    "/home/sugimoto/.config/npm/npmrc"

set -gx EDITOR "/usr/bin/kak"
set -gx VISUAL "/usr/bin/kak"

set -gx GOPATH "/home/sugimoto/.go"

set -gx CARGO_HOME    "/home/sugimoto/.cargo"
set -gx RUSTC_WRAPPER "/usr/bin/sccache"

set -gx VOLTA_HOME "/home/sugimoto/.volta"
set -gx PATH       "/home/sugimoto/.volta/bin" $PATH

set -gx LF_ICONS "\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.vimrc=:\
*.viminfo=:\
*.gitignore=:\
*.c=:\
*.cc=:\
*.clj=:\
*.coffee=:\
*.cpp=:\
*.css=:\
*.d=:\
*.dart=:\
*.erl=:\
*.exs=:\
*.fs=:\
*.go=:\
*.h=:\
*.hh=:\
*.hpp=:\
*.hs=:\
*.html=:\
*.java=:\
*.jl=:\
*.js=:\
*.json=:\
*.lua=:\
*.md=:\
*.php=:\
*.pl=:\
*.pro=:\
*.py=:\
*.rb=:\
*.rs=:\
*.scala=:\
*.ts=:\
*.vim=:\
*.cmd=:\
*.ps1=:\
*.sh=:\
*.bash=:\
*.zsh=:\
*.fish=:\
*.tar=:\
*.tgz=:\
*.arc=:\
*.arj=:\
*.taz=:\
*.lha=:\
*.lz4=:\
*.lzh=:\
*.lzma=:\
*.tlz=:\
*.txz=:\
*.tzo=:\
*.t7z=:\
*.zip=:\
*.z=:\
*.dz=:\
*.gz=:\
*.lrz=:\
*.lz=:\
*.lzo=:\
*.xz=:\
*.zst=:\
*.tzst=:\
*.bz2=:\
*.bz=:\
*.tbz=:\
*.tbz2=:\
*.tz=:\
*.deb=:\
*.rpm=:\
*.jar=:\
*.war=:\
*.ear=:\
*.sar=:\
*.rar=:\
*.alz=:\
*.ace=:\
*.zoo=:\
*.cpio=:\
*.7z=:\
*.rz=:\
*.cab=:\
*.wim=:\
*.swm=:\
*.dwm=:\
*.esd=:\
*.jpg=:\
*.jpeg=:\
*.mjpg=:\
*.mjpeg=:\
*.gif=:\
*.bmp=:\
*.pbm=:\
*.pgm=:\
*.ppm=:\
*.tga=:\
*.xbm=:\
*.xpm=:\
*.tif=:\
*.tiff=:\
*.png=:\
*.svg=:\
*.svgz=:\
*.mng=:\
*.pcx=:\
*.mov=:\
*.mpg=:\
*.mpeg=:\
*.m2v=:\
*.mkv=:\
*.webm=:\
*.ogm=:\
*.mp4=:\
*.m4v=:\
*.mp4v=:\
*.vob=:\
*.qt=:\
*.nuv=:\
*.wmv=:\
*.asf=:\
*.rm=:\
*.rmvb=:\
*.flc=:\
*.avi=:\
*.fli=:\
*.flv=:\
*.gl=:\
*.dl=:\
*.xcf=:\
*.xwd=:\
*.yuv=:\
*.cgm=:\
*.emf=:\
*.ogv=:\
*.ogx=:\
*.aac=:\
*.au=:\
*.flac=:\
*.m4a=:\
*.mid=:\
*.midi=:\
*.mka=:\
*.mp3=:\
*.mpc=:\
*.ogg=:\
*.ra=:\
*.wav=:\
*.oga=:\
*.opus=:\
*.spx=:\
*.xspf=:\
*.pdf=:\
*.nix=:\
"
