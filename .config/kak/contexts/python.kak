set-indent buffer 4 false # indent.kak

set-option window formatcmd "black -q -"
set-option window lintcmd "ruff check -q %val{buffile}"

ui-lsp-enable
