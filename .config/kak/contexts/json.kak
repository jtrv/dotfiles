set-option window formatcmd "jaq"
set-option window lintcmd %{ run() { cat -- "$1" | jaq 2>&1 | awk -v filename="$1" '/ at line [0-9]+, column [0-9]+$/ { line=$(NF - 2); column=$NF; sub(/ at line [0-9]+, column [0-9]+$/, ""); printf "%s:%d:%d: error: %s", filename, line, column, $0; }'; } && run }

ui-lsp-enable
