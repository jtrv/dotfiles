define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

map window dev e -docstring "emmet"     ':emmet <ret>'
map window dev c -docstring "comment"   ':comment-line <ret>'

ui-lsp-enable
