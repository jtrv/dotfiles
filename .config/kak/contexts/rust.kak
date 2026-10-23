hook global WinSetOption filetype=rust %{
  map window dev c -docstring 'clippy'  ':cargo clippy --color=always<ret>'

  ui-lsp-enable
}
