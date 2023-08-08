hook global BufSetOption filetype=typescript %{
  set-option buffer formatcmd "dprint fmt --stdin=format.ts --config=$XDG_CONFIG_HOME/dprint/dprint.json"

  define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
  define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

  map buffer dev e -docstring "emmet"     ':emmet <ret>'
  map buffer dev c -docstring "comment"   ':comment-line <ret>'
}

hook global WinSetOption filetype=typescript %{
  set-option window lintcmd 'deno lint -'
  lint

###### LSP ######
  set-option window lsp_auto_highlight_references true
  set-option window lsp_hover_anchor true
  lsp-auto-hover-enable
  lsp-auto-hover-insert-mode-enable
  lsp-inlay-diagnostics-enable window
  lsp-inlay-hints-enable window
  echo -debug "Enabling LSP for filtetype %opt{filetype}"
  lsp-enable-window

  map window object a     -docstring 'LSP any symbol'                    '<a-semicolon>lsp-object<ret>'
  map window object e     -docstring 'LSP function or method'            '<a-semicolon>lsp-object Function Method<ret>'
  map window object k     -docstring 'LSP class interface or struct'     '<a-semicolon>lsp-object Class Interface Struct<ret>'
  map window insert <tab> -docstring 'Select next snippet placeholder'   '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>'
}
