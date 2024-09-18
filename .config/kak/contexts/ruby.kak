set-option window formatcmd "rubocop -x -o /dev/null -s %val{buffile} | sed -n '2,$p'"

set-option window lintcmd 'rubocop -l --format emacs'

###### LSP ######
define-command -override ui-lsp-enable %{
  set-option window lsp_auto_highlight_references true
  set-option window lsp_hover_anchor true
  set-option window lsp_hover_max_diagnostic_lines 10
  set-option window lsp_hover_max_info_lines 10
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
map window object k     -docstring 'LSP class interface or struct'     '<a-semicolon>lsp-object Class Interface Struct<ret>'
map window insert <tab> -docstring 'Select next snippet placeholder'   '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>'
