set-option window formatcmd 'go fmt'
set-option window lintcmd 'go vet'

map window normal <#> -docstring "comment"   ':comment-line <ret>'

ui-lsp-enable
