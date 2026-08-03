if status is-interactive

function __git_back_in_time
  set TODAY (date '+%a %b %d %H:%M:%S %Y %z')
  echo "commit --amend % --no-edit --date='$TODAY'"
end

function __git_new_gh_repo
  set CWD_NAME (basename "$PWD")
  set GH_USER (gh auth status -a | awk 'NR==2 {print $7}')
echo "init; git add . ; git commit -e
set REPO_NAME $CWD_NAME%
set TRUNK_N main

gh repo create --private \$REPO_NAME
git remote add origin https://github.com/$GH_USER/\$REPO_NAME.git
git branch -M \$TRUNK_N; git push -u origin \$TRUNK_N"
end


abbr -c git -a bit --set-cursor -f __git_back_in_time
abbr -c git -a new --set-cursor -f __git_new_gh_repo


# Add git aliases
complete -f -c git -n '__fish_use_subcommand' -a skip -d 'Skip worktree changes for a file'
complete -f -c git -n '__fish_use_subcommand' -a unskip -d 'Unskip worktree changes for a file'
complete -f -c git -n '__fish_use_subcommand' -a unskip-all -d 'Unskip worktree changes for all files'
complete -f -c git -n '__fish_use_subcommand' -a bit -d 'Amend commit with current date'

# skip/unskip file completion
complete -F -c git -n '__fish_seen_subcommand_from skip'
complete -F -c git -n '__fish_seen_subcommand_from unskip'

end
