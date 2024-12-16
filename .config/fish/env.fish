# XDG Base Directories
set -gx XDG_CACHE_HOME    "$HOME"/.cache
set -gx XDG_CONFIG_HOME   "$HOME"/.config
set -gx XDG_DATA_HOME     "$HOME"/.local/share
set -gx XDG_DESKTOP_DIR   "$HOME"/
set -gx XDG_DOCUMENTS_DIR "$HOME"/documents
set -gx XDG_DOWNLOAD_DIR  "$HOME"/downloads
set -gx XDG_MUSIC_DIR     "$HOME"/media/music
set -gx XDG_PICTURES_DIR  "$HOME"/media/pictures
set -gx XDG_STATE_HOME    "$HOME"/.local/state

# Cache
set -gx BUNDLE_USER_CACHE "$XDG_CACHE_HOME"/bundle
set -gx LESSHISTFILE      "$XDG_CACHE_HOME"/less/history
set -gx TEXMFVAR          "$XDG_CACHE_HOME"/texlive/texmf-var

# Config
set -gx AWS_CONFIG_FILE             "$XDG_CONFIG_HOME"/aws/config
set -gx AWS_SHARED_CREDENTIALS_FILE "$XDG_CONFIG_HOME"/aws/credentials
set -gx BUNDLE_USER_CONFIG          "$XDG_CONFIG_HOME"/bundle
set -gx DOTFILES                    "$XDG_CONFIG_HOME"/dotfiles
set -gx GEMRC                       "$XDG_CONFIG_HOME"/gem/gemrc
set -gx GTK2_RC_FILES               "$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
set -gx JUPYTER_CONFIG_DIR          "$XDG_CONFIG_HOME"/jupyter
set -gx NETRC                       "$XDG_CONFIG_HOME"/.netrc
set -gx NPM_CONFIG_USERCONFIG       "$XDG_CONFIG_HOME"/npm/npmrc
set -gx PARALLEL_HOME               "$XDG_CONFIG_HOME"/parallel
set -gx PYTHONSTARTUP               "$XDG_CONFIG_HOME"/python/pythonrc
set -gx XINITRC                     "$XDG_CONFIG_HOME"/X11/xinitrc
set -gx _JAVA_OPTIONS -Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

# Data
set -gx ANDROID_HOME       "$XDG_DATA_HOME"/android
set -gx BUNDLE_USER_PLUGIN "$XDG_DATA_HOME"/bundle
set -gx BUN_INSTALL        "$XDG_DATA_HOME"/bun
set -gx CARGO_HOME         "$XDG_DATA_HOME"/cargo
set -gx DEDOC_HOME         "$XDG_DATA_HOME"/dedoc
set -gx FORTUNE_DIR        "$XDG_DATA_HOME"/fortunes
set -gx GNUPGHOME          "$XDG_DATA_HOME"/gnupg
set -gx GOPATH             "$XDG_DATA_HOME"/go
set -gx GRADLE_USER_HOME   "$XDG_DATA_HOME"/gradle
set -gx NIMBLE_DIR         "$XDG_DATA_HOME"/nimble
set -gx NODE_REPL_HISTORY  "$XDG_DATA_HOME"/node_repl_history
set -gx NVM_DIR            "$XDG_DATA_HOME"/nvm
set -gx RBENV_ROOT         "$XDG_DATA_HOME"/rbenv
set -gx RUSTUP_HOME        "$XDG_DATA_HOME"/rustup
set -gx VOLTA_HOME         "$XDG_DATA_HOME"/volta
set -gx WINEPREFIX         "$XDG_DATA_HOME"/wine
set -gx W3M_DIR            "$XDG_DATA_HOME"/w3m

# Runtime
set -gx XAUTHORITY "$XDG_RUNTIME_DIR"/Xauthority

# State
set -gx HISTFILE "$XDG_STATE_HOME"/bash/history

# Misc
set -gx ARGC_COMPLETIONS_ROOT       "$XDG_CONFIG_HOME/argc-completions"
set -gx ARGC_COMPLETIONS_PATH       "$ARGC_COMPLETIONS_ROOT/completions/linux:$ARGC_COMPLETIONS_ROOT/completions"
set -gx ARGC_SCRIPTS                (ls -p -1 "$ARGC_COMPLETIONS_ROOT/completions/linux" "$ARGC_COMPLETIONS_ROOT/completions" | sed -n 's/\.sh$//p')
set -gx ATUIN_NOBIND                "true"
set -gx BAT_PAGER                   "kak"
set -gx BEMOJI_PICKER_CMD           "dmenu -i -fn 'pixelsize=18:antialias=true' -nb rgb:1e/1e/2e -nf rgb:cd/d6/f4 -sb rgb:89/dc/eb -sf rgb:1e/1e/2e"
set -gx BEMOJI_CLIP_CMD             "xclip -sel clip"
set -gx BEMOJI_TYPE_CMD             "xdotool"
set -gx BROWSER                     "firefox"
set -gx CONCEAL_FINDER              "skim"
set -gx DELTA_PAGER                 "kak"
set -gx DMENU_THEME                 "-i -fn 'pixelsize=18:antialias=true' -nb rgb:1e/1e/2e -nf rgb:cd/d6/f4 -sb rgb:89/dc/eb -sf rgb:1e/1e/2e" # matched to spectrwm.conf
set -gx EDITOR                      "kak"
set -gx fish_greeting
set -gx HORS_ENGINE                 "google"
set -gx MANPAGER                    "kak -e 'set buffer filetype man'"
set -gx OPENAI_API_KEY              (secli get openai_api_key)
set -gx OPENAI_API_BASE             "https://api.openai.com/v1"
set -gx PAGER                       "kak"
set -gx SCCACHE_DIRECT              true
set -gx QT_STYLE_OVERRIDE           "kvantum"
set -gx QT_QPA_PLATFORMTHEME        "qt6ct"
set -gx VISUAL                      "kak"
set -gx VIRTUAL_ENV_DISABLE_PROMPT  true

set -gx FZF_DEFAULT_OPTS "\
--ansi \
--multi \
--tabstop=2 \
--preview-window border-vertical \
--bind='\
alt-a:select-all,\
alt-d:deselect-all,\
alt-k:preview-up,\
alt-j:preview-down,\
alt-b:preview-page-up,\
alt-f:preview-page-down,\
ctrl-b:page-up,\
ctrl-f:page-down,\
ctrl-u:half-page-up,\
ctrl-d:half-page-down,\
ctrl-space:jump\
'"

# catppucin theme
set -gx FZF_DEFAULT_OPTS "\
$FZF_DEFAULT_OPTS \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
"

set -gx SKIM_DEFAULT_OPTIONS "\
--ansi \
--multi \
--tabstop=2 \
--bind='\
alt-a:select-all,\
alt-d:deselect-all,\
alt-k:preview-up,\
alt-j:preview-down,\
alt-b:preview-page-up,\
alt-f:preview-page-down,\
ctrl-b:page-up,\
ctrl-f:page-down,\
ctrl-u:half-page-up,\
ctrl-d:half-page-down,\
ctrl-space:jump\
'"

# catppucin theme
set -gx SKIM_DEFAULT_OPTIONS "$SKIM_DEFAULT_OPTIONS --color=fg:#cdd6f4,bg:#1e1e2e,matched:#313244,matched_bg:#f2cdcd,current:#cdd6f4,current_bg:#45475a,current_match:#1e1e2e,current_match_bg:#f5e0dc,spinner:#a6e3a1,info:#cba6f7,prompt:#89b4fa,cursor:#f38ba8,selected:#eba0ac,header:#94e2d5,border:#6c7086"

set -gx LF_ICONS "\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.vimrc=:\
*.viminfo=:\
*.gitignore=󰊢:\
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

set PATH /home/sugimoto/.local/bin /home/sugimoto/.local/share/bun/bin /home/sugimoto/.local/share/cargo/bin /home/sugimoto/.local/share/go/bin /home/sugimoto/.local/share/nimble/bin /home/sugimoto/.local/share/npm/bin /home/sugimoto/.local/share/rbenv/shims /home/sugimoto/repos/kakoune/src/../libexec/kak /usr/local/sbin /usr/local/bin /usr/bin /usr/bin/site_perl /usr/bin/vendor_perl /usr/bin/core_perl $ARGC_COMPLETIONS_ROOT/bin
