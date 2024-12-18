alias buffer w grep-expand-write

map buffer user r -docstring "review changes"   ': grep-expand-review <ret>'
map buffer user w -docstring "write changes"    ': grep-expand-write <ret>'
