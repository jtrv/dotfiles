hook global WinSetOption filetype=git-commit %{
  execute-keys ":autowrap-enable<ret>"
  set-option window lintcmd "commitlint <"
  lint
}
