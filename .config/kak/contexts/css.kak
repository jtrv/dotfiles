hook global BufSetOption filetype=(css|scss) %{
  set-option buffer formatcmd "prettierd %val{buffile}"

  define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
  define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

  map buffer dev e -docstring "emmet"  ':emmet <ret>'
  map buffer dev m -docstring "minify" ':minify <ret>'
}

hook global WinSetOption filetype=(css|scss) %{
  set-option window lintcmd "stylelint_d --config ~/.config/.stylelintrc --stdin --stdin-filename %val{buffile}"
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
  map window insert <tab> -docstring 'Select next snippet placeholder'   '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>'
}
