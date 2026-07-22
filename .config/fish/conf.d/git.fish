if status is-interactive

function __git_back_in_time
  set TODAY (date '+%a %b %d %H:%M:%S %Y %z')
  echo "commit --amend % --no-edit --date='$TODAY'"
end

# abbr --command git bit --set-cursor --function __git_back_in_time

# Add git aliases
complete -f -c git -n '__fish_use_subcommand' -a skip -d 'Skip worktree changes for a file'
complete -f -c git -n '__fish_use_subcommand' -a unskip -d 'Unskip worktree changes for a file'
complete -f -c git -n '__fish_use_subcommand' -a unskip-all -d 'Unskip worktree changes for all files'
complete -f -c git -n '__fish_use_subcommand' -a bit -d 'Amend commit with current date'

# skip/unskip file completion
complete -F -c git -n '__fish_seen_subcommand_from skip'
complete -F -c git -n '__fish_seen_subcommand_from unskip'

end
