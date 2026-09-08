set-option window formatcmd "prettierd format.html"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }

map window dev e -docstring "emmet"  ':emmet <ret>'

ui-lsp-enable
