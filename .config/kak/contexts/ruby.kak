set-option window formatcmd "rubocop -x -o /dev/null -s %val{buffile} | sed -n '2,$p'"
set-option window lintcmd 'rubocop -l --format emacs'

set-option window lsp_hover_max_diagnostic_lines 10
set-option window lsp_hover_max_info_lines 10

ui-lsp-enable
