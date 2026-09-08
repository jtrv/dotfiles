define-command emmet -override %{
  execute-keys 'giGl|emmet <ret>'
}

map window dev e -docstring 'emmet'     %{:emmet <ret>}

map window normal '#' -docstring 'comment'     %{:comment-line <ret>}

ui-lsp-enable
