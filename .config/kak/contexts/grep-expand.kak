alias buffer w grep-expand-write
alias buffer write grep-expand-write

map buffer grep r -docstring "review changes"   ': grep-expand-review <ret>'
map buffer grep w -docstring "write changes"    ': grep-expand-write <ret>'
map buffer user r -docstring "review changes"   ': grep-expand-review <ret>'
map buffer user w -docstring "write changes"    ': grep-expand-write <ret>'
