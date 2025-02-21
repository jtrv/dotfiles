set-option window formatcmd "prettierd format.html"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
define-command minify -override %{ execute-keys "<percent>| minify-html --minify-css --minify-js <ret><percent>" }

map window dev e -docstring "emmet"  ':emmet <ret>'
map window dev m -docstring "minify" ':minify <ret>'

ui-lsp-enable
