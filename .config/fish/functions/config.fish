# Defined via `source`
function config --wraps='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME' --description 'alias config=/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
  /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME $argv; 
end

# Start X at login
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec startx -- -keeptty
    end
end
