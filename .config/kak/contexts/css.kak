define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }

hook global WinSetOption filetype=(css|scss) %{
  set-option window formatcmd "prettierd format.scss"

  map window dev e -docstring "emmet"  ':emmet <ret>'

  ui-colorcol-toggle
  ui-lsp-enable
}
