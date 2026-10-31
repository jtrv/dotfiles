hook global WinSetOption filetype=terraform %{
  set-option window formatcmd "terraform fmt"

  ui-lsp-enable
}
