hook global BufSetOption filetype=json %{
  set-option buffer formatcmd "jq --indent %opt{tabstop} ."
}

hook global WinSetOption filetype=json %{
  set-option window lintcmd %{ run() { cat -- "$1" | jq 2>&1 | awk -v filename="$1" '/ at line [0-9]+, column [0-9]+$/ { line=$(NF - 2); column=$NF; sub(/ at line [0-9]+, column [0-9]+$/, ""); printf "%s:%d:%d: error: %s", filename, line, column, $0; }'; } && run }
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
}
