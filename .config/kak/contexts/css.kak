hook global WinSetOption filetype=(css|scss) %{
  set-option window formatcmd "prettierd format.scss"

  map window dev e -docstring "emmet"  ':emmet <ret>'

  try ui-colorcol-enable
  ui-lsp-enable
}
