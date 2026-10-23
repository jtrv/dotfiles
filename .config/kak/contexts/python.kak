hook global WinSetOption filetype=python %{
  set-indent buffer 4 false

  map window normal '#' -docstring 'comment'     %{:comment-line <ret>}

  ui-lsp-enable
}
