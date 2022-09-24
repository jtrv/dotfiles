hook global WinSetOption filetype=git-commit %{
  ui-whitespaces-disable
  autowrap-enable
  set-option window lintcmd "commitlint <"
  lint
}
