hook global WinSetOption filetype=git-commit %{
  ui-whitespaces-toggle
  autowrap-enable
  set-option window lintcmd "commitlint <"
  lint
}
