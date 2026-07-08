complete -c 'config' -w "git --git-dir='$DOTFILES' --work-tree='$HOME'"
complete -c 'config-add' -F
complete -c "config-diff" -w "git --git-dir='$DOTFILES' --work-tree='$HOME' diff"
