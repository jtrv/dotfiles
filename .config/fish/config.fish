fish_vi_key_bindings

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

# create backup files
function bak
  for file in $argv
    cp $file $file.bak
  end
end

# ask questions, get answers
function how
  kak -e "kakpipe -n how -- hors -a -n 2 -p never $argv"
end

######## ABBREVIATIONS ########

if status --is-interactive
  abbr --add --global cp     'cp -i'
  abbr --add --global mv     'mv -i'
  abbr --add --global npin   'license MIT && gitignore node && covgen jtravers@tutanota.com && npm init -y && volta pin node@lts && git init'
  abbr --add --global gitbit 'git commit --amend --no-edit --date "Sat 01 Jan 2022 16:20:07 PST"'
end


######## ALIASES ########

alias ani     'ani-cli -q high' # watch anime in super ultra HD 8k lossless greenray
alias bc      'kalk'
alias bls     '/bin/ls' # for piping
alias cat     'bat'
alias config  '/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME' # git for config files
alias doas    'doas --'
alias j       'lf'
alias kish    'k ~/.config/fish/config.fish'
alias konf    'k ~/.config/kak/kakrc'
alias la      'exa -al --color=always --group-directories-first --git --icons' # all files and dirs
alias lc      'lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME' # lazygit for config files
alias lg      'lazygit'
alias lh      'exa -al --color=always --group-directories-first --git --icons --ignore-glob="[a-z]*|[A-Z]*|[0-9]*"' # hidden
alias ll      'exa -l --color=always --group-directories-first --git --icons' # long format
alias ls      'exa -l --color=always --group-directories-first --git --icons' # preferred listing
alias lt      'exa -aT --color=always --group-directories-first --git --icons' # tree listing
alias mirrors '~/scripts/update-mirrors.sh' # update mirrors / database
alias mons    'bass mons' # use bash for mons (monitor scripts)
alias nbg     'feh --randomize --bg-scale --no-fehbg ~/pictures/wallpapers/' # change bg
alias off     'systemctl suspend' # save state, enter low-power mode
alias pom     'potato' # shell pomodoro timer
alias q       'exit'
alias rm      'rm -i'

alias awman   'wiki-docs-search'
complete -c wiki-docs-search -a '(fd html "/usr/share/doc/arch-wiki/html/en/" | rg -o \'/(\w*).html$\' -r \'$1\')'


######## KAKOUNE ########

# view manpage
function kakman
  kak -e "man $argv"
end
complete -c kakman -w man

# view '--help' output
function kelp
  kak -e "kakpipe -n help -- $argv --help"
end
complete -c kelp -w man

# view tldr
function kldr
  kak -e "kakpipe -n tldr -- tldr --color=always $argv"
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

# view tldr
function kldr
  kak -e "kakpipe -n tldr -- tldr --color=always $argv"
end

# view mdn docs
function kdn
  kak -e "kakpipe -n mdn -- mdn $argv"
end

# kakoune grep
function kak-grep
  kak -e "grep $argv";
end
alias kg 'kak-grep'
complete -c kak-grep -w rg

alias kf      'kamp-files'
alias kgi     'kamp-grep'

alias k       'kamp edit'
alias kval    'kamp get val'
alias kopt    'kamp get opt'
alias kreg    'kamp get reg'
alias kcd-pwd 'cd "(kamp get sh pwd)"'
alias kcd-buf 'cd "(dirname (kamp get val buffile))"'
alias kft     'kamp get -b \* opt filetype | sort | uniq' # list file types you're working on


# Start X at login
if status is-login
  if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
    exec startx -- -keeptty
  end
end

######## EXPORTS ########

set -gx fish_greeting
set -gx MCFLY_FUZZY 2

set -gx CALIBRE_USE_DARK_PALETTE "yes"
set -gx FZF_DEFAULT_OPTS         "--ansi --color=dark --multi --tabstop=2  --preview='bat --color=always {}' --preview-window border-vertical"
set -gx HORS_ENGINE              "google"
set -gx NPM_CONFIG_USERCONFIG    "/home/sugimoto/.config/npm/npmrc"

set -gx EDITOR   "/usr/bin/kak"
set -gx VISUAL   "/usr/bin/kak"
set -gx MANPAGER "/usr/bin/bat" # see 'kan' function

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
