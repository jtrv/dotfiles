define-command emmet -override %{
  execute-keys 'giGl|emmet <ret>'
}

define-command minify -override %{
  execute-keys '%|minify-html <ret>%'
}

define-command rustywind -override %{
  execute-keys -draft '%|rustywind --stdin <ret>'
}

map window dev e -docstring 'emmet'     %{:emmet <ret>}
map window dev m -docstring 'minify'    %{:minify <ret>}
map window dev r -docstring 'rustywind' %{:rustywind <ret>}

ui-lsp-enable
