set-option window formatcmd "biome format --stdin-file-path=index.tsx"
set-option window lintcmd "biome lint --log-kind=compact --stdin-file-path=index.tsx"

define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

map window dev e -docstring "emmet"     ':emmet <ret>'
map window dev c -docstring "comment"   ':comment-line <ret>'

ui-lsp-enable
