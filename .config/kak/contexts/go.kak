hook global BufSetOption filetype=go %{
  set-option buffer formatcmd 'gofmt'
}

hook global WinSetOption filetype=go %{
  # look into https://github.com/mgechev/revive

###### LSP ######
  set-option window lsp_auto_highlight_references true
  set-option window lsp_hover_anchor true
  lsp-auto-hover-enable
  lsp-auto-hover-insert-mode-enable
  lsp-inlay-diagnostics-enable window
  lsp-inlay-hints-enable window
  echo -debug "Enabling LSP for filtetype %opt{filetype}"
  lsp-enable-window

  map global object a     -docstring 'LSP any symbol'                    '<a-semicolon>lsp-object<ret>'
  map global object e     -docstring 'LSP function or method'            '<a-semicolon>lsp-object Function Method<ret>'
  map global object k     -docstring 'LSP class interface or struct'     '<a-semicolon>lsp-object Class Interface Struct<ret>'
  map global insert <tab> -docstring 'Select next snippet placeholder'   '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>'
}
