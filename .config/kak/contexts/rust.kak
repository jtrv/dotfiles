set-option window formatcmd 'rustfmt --edition=2021'
map window dev c -docstring "clippy"  ':cargo clippy --color=always<ret>'

ui-lsp-enable
