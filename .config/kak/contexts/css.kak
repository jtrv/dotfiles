set-option window formatcmd "prettierd format.scss"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }

map window dev e -docstring "emmet"  ':emmet <ret>'

ui-colorcol-toggle
ui-lsp-enable
