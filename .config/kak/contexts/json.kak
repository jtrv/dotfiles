hook global WinSetOption filetype=json %{
  set-option window formatcmd "jq"

  ui-lsp-enable
}
