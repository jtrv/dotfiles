complete -c 'config' -w "/usr/bin/git --git-dir='$DOTFILES' --work-tree='$HOME'"
complete -c 'config-add' -F
complete -c "config-diff" -w "/usr/bin/git --git-dir='$DOTFILES' --work-tree='$HOME' diff"
