define-command emmet -override %{
  execute-keys 'giGl|emmet <ret>'
}

define-command minify -override %{
  execute-keys '%|minify-html <ret>%'
}

map window dev e -docstring 'emmet'     %{:emmet <ret>}
map window dev m -docstring 'minify'    %{:minify <ret>}

ui-lsp-enable
