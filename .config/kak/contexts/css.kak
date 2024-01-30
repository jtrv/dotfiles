set-option window formatcmd "prettierd format.scss"

set-option window lintcmd "stylelint_d --config ~/.config/.stylelintrc --stdin --stdin-filename %val{buffile}"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }

define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

map window dev e -docstring "emmet"  ':emmet <ret>'
map window dev m -docstring "minify" ':minify <ret>'

lint
ui-colorcol-toggle

###### LSP ######
define-command -override ui-lsp-enable %{
  set-option window lsp_auto_highlight_references true
  set-option window lsp_hover_anchor true
  lsp-auto-hover-enable
  lsp-auto-hover-insert-mode-enable
  lsp-inlay-diagnostics-enable window
  lsp-inlay-hints-enable window
  echo -debug "Enabling LSP for filtetype %opt{filetype}"
  lsp-enable-window
}
ui-lsp-enable

map window object a     -docstring 'LSP any symbol'                    '<a-semicolon>lsp-object<ret>'
map window object e     -docstring 'LSP function or method'            '<a-semicolon>lsp-object Function Method<ret>'
map window insert <tab> -docstring 'Select next snippet placeholder'   '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>'
