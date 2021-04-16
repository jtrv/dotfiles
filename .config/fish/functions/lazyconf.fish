# Defined via `source`
function lazyconf --wraps='lazygit --git-dir=$HOME/dotfiles/ --work-tree=$HOME' --description 'alias for lazygitting dotfiles'
  lazygit --git-dir=$HOME/dotfiles/ --work-tree=$HOME $argv; 
end
