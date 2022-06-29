fish_vi_key_bindings

# Emulates vim's cursor shape behavior
set fish_cursor_default block blink
set fish_cursor_insert line blink
set fish_cursor_replace_one underscore blink
set fish_cursor_visual block blink

######## SOURCE ########

# better history
mcfly init fish | source

# better prompt
starship init fish | source

# better 'cd' (z)
zoxide init fish | source

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true


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

# ask questions, get answers in kakoune
function how
  kak -e "how $argv"
end

######## ABBREVIATIONS ########

if status --is-interactive
  abbr --add --global cp     'cp -i'
  abbr --add --global mv     'mv -i'
  abbr --add --global rm     'rm -i'
  abbr --add --global npin   'license MIT && gitignore node && covgen jtravers@tutanota.com && npm init -y && volta pin node@lts && git init'
  abbr --add --global gitbit 'git commit --amend --no-edit --date "Sat 01 Jan 2022 16:20:07 PST"'
end


######## ALIASES ########

alias ani     'ani-cli -q high' # watch anime in super ultra HD 8k lossless greenray
alias awman   'wiki-docs-search'
complete -c wiki-docs-search -a '(fd html "/usr/share/doc/arch-wiki/html/en/" | rg -o \'/(\w*).html$\' -r \'$1\')'
alias bc      'kalk'
alias bls     '/bin/ls' # for piping
alias cat     'bat'
alias config  '/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME' # git for config files
alias doas    'doas --'
alias glow    'glow -p'
alias j       '~/.config/lf/wrapper'
alias kish    'k ~/.config/fish/config.fish'
alias konf    'k ~/.config/kak/kakrc'
alias la      'exa -al --color=always --group-directories-first --git --icons' # all files and dirs
alias lc      'lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME' # lazygit for config files
alias lg      'lazygit'
alias lh      'exa -al --color=always --group-directories-first --git --icons --ignore-glob="[a-z]*|[A-Z]*|[0-9]*"' # hidden
alias ll      'exa -l --color=always --group-directories-first --git --icons' # long format
alias ls      'exa -l --color=always --group-directories-first --git --icons' # preferred listing
alias lt      'exa -aT --color=always --group-directories-first --git --icons' # tree listing
alias m       'math'
alias mirrors '~/.local/bin/update-mirrors' # update mirrors / database
alias mons    'bass mons' # use bash for mons (monitor scripts)
alias nbg     'feh --randomize --bg-scale --no-fehbg ~/media/pictures/wallpapers/' # change bg
alias off     'systemctl suspend' # save state, enter low-power mode
alias pom     'potato' # shell pomodoro timer
alias q       'exit'
alias wget    "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\""
alias yarn    "yarn --use-yarnrc \"$XDG_CONFIG_HOME\"/yarn/config"



######## KAKOUNE ########

# view manpage
function kakman
  kak -e "man $argv"
end
complete -c kakman -w man

# view '--help' output
function kelp
  kak -e "helpp $argv"
end
complete -c kelp -w man

# view tldr
function kldr
  kak -e "tldr $argv"
end
complete -c kldr -w man

# manpage with fallback to help output
function kan
  if man -w $argv &> /dev/null
    kakman $argv
  else if $argv --help &> /dev/null
    kelp $argv
  end
end
complete -c kan -w man

# view mdn docs
function kdn
  kak -e "mdn $argv"
end

function kakgrep
    set grepargs
    for x in $argv
        set -a grepargs (echo $x | sed -e "s/'/''/g" -e "s/^/'/" -e "s/\$/'/")
    end
    kak -e "grep $(string join -- " " $grepargs)"
end
complete -c kakgrep -w rg
alias kg 'kakgrep'

# diff in kak
function kakdiff
  kak -e "diff $argv"
end
alias kd 'kakdiff'

function kifft
  kak -e "difft $argv"
end
alias kdt 'kifft'

function kelta
  kak -e "delta $argv"
end
alias kda 'kelta'

alias kf      'kamp-files'
alias kgi     'kamp-grep'

alias k       'kamp edit'
alias kval    'kamp get val'
alias kopt    'kamp get opt'
alias kreg    'kamp get reg'
alias kcd-pwd 'cd "(kamp get sh pwd)"'
alias kcd-buf 'cd "(dirname (kamp get val buffile))"'
alias kft     'kamp get -b \* opt filetype | sort | uniq' # list file types you're working on



######## EXPORTS ########

set -gx CALIBRE_USE_DARK_PALETTE "yes"
set -gx EDITOR "/usr/bin/kak"
set -gx fish_greeting
set -gx FZF_DEFAULT_OPTS "--ansi --color=dark --multi --tabstop=2  --preview='bat --color=always {}' --preview-window border-vertical"
set -gx HORS_ENGINE "google"
set -gx MANPAGER "/usr/bin/bat" # see 'kan' function
set -gx MCFLY_FUZZY 2
set -gx PATH "$VOLTA_HOME/bin" $PATH
set -gx RUSTC_WRAPPER "/usr/bin/sccache"
set -gx VISUAL "/usr/bin/kak"

set -gx LESSHISTFILE "$XDG_CACHE_HOME"/less/history

set -gx AWS_CONFIG_FILE             "$XDG_CONFIG_HOME"/aws/config
set -gx AWS_SHARED_CREDENTIALS_FILE "$XDG_CONFIG_HOME"/aws/credentials
set -gx GTK2_RC_FILES               "$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
set -gx NPM_CONFIG_USERCONFIG       "$XDG_CONFIG_HOME"/npm/npmrc
set -gx PYTHONSTARTUP               "$XDG_CONFIG_HOME"/python/pythonrc
set -gx _JAVA_OPTIONS -Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

set -gx ANDROID_HOME      "$XDG_DATA_HOME"/android
set -gx CARGO_HOME        "$XDG_DATA_HOME"/cargo
set -gx GOPATH            "$XDG_DATA_HOME"/go
set -gx GNUPGHOME         "$XDG_DATA_HOME"/gnupg
set -gx NODE_REPL_HISTORY "$XDG_DATA_HOME"/node_repl_history
set -gx NVM_DIR           "$XDG_DATA_HOME"/nvm
set -gx RUSTUP_HOME       "$XDG_DATA_HOME"/rustup
set -gx VOLTA_HOME        "$XDG_DATA_HOME"/volta

set -gx HISTFILE "$XDG_STATE_HOME"/bash/history

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
