set-option window formatcmd "prettierd format.scss"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

map window dev e -docstring "emmet"  ':emmet <ret>'
map window dev m -docstring "minify" ':minify <ret>'

ui-colorcol-toggle
ui-lsp-enable
