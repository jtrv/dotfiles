define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }

hook global WinSetOption filetype=html %{
  set-option window formatcmd "prettierd format.html"

  map window dev e -docstring "emmet"  ':emmet <ret>'

  ui-lsp-enable
}
