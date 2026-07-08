alias buffer w grep-write

map buffer user r -docstring "review changes"   ': grep-preview <ret>'
map buffer user w -docstring "write changes"    ': grep-write <ret>'
