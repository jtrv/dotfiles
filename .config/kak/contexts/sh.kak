hook global WinSetOption filetype=sh %{
  set-option window formatcmd "shfmt"

  ui-lsp-enable
}
