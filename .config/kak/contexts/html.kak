set-option window formatcmd "prettierd format.html"
set-option window lintcmd "tidy -e --gnu-emacs=yes --quiet=yes 2>&1"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
define-command minify -override %{ execute-keys "<percent>| minify-html --minify-css --minify-js <ret><percent>" }

map window dev e -docstring "emmet"  ':emmet <ret>'
map window dev m -docstring "minify" ':minify <ret>'

lint
ui-lsp-enable
