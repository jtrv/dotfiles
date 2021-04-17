# Defined via `source`
function config --wraps='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME' --description 'alias for gitting dotfiles'
  /usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME $argv; 
end
