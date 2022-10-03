hook global BufSetOption filetype=grep %{
  alias buffer w grep-write
  alias buffer wq grep-write-quit
  map buffer grep e -docstring "get context"     ':grep-expand <ret>'
  map buffer grep w -docstring "write changes"   ':grep-write <ret>'
  map buffer user e -docstring "get context"     ':grep-expand <ret>'
  map buffer user l -docstring "live-grep"       ':live-grep <ret>'
  map buffer user w -docstring "write changes"   ':grep-write <ret>'
}

hook global BufSetOption filetype=grep-expand %{
  alias buffer w grep-expand-write
  map buffer grep r -docstring "review changes"   ':grep-expand-review <ret>'
  map buffer grep w -docstring "write changes"    ':grep-expand-write <ret>'
  map buffer user r -docstring "review changes"   ':grep-expand-review <ret>'
  map buffer user w -docstring "write changes"    ':grep-expand-write <ret>'
}
