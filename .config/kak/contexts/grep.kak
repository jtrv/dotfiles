ansi-enable

alias window w grep-write

map window normal <ret> ':grep-jump <ret>'

map window grep e -docstring "get context"     ':grep-expand <ret>'
map window grep w -docstring "write changes"   ':grep-write <ret>'
map window user e -docstring "get context"     ':grep-expand <ret>'
map window user l -docstring "live-grep"       ':live-grep <ret>'
map window user w -docstring "write changes"   ':grep-write <ret>'
