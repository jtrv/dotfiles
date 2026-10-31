hook global WinSetOption filetype=(javascript|typescript) %{
  map window dev e -docstring 'emmet'     %{:emmet <ret>}

  map window normal '#' -docstring 'comment'     %{:comment-line <ret>}

  ui-lsp-enable
}
