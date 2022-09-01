hook global WinSetOption filetype=grep %{
  alias buffer w grep-write
  alias buffer wq grep-write-quit
  map buffer user w -docstring "write changes"   ':grep-write <ret>'
  map global grep w -docstring "write changes"   ':grep-write <ret>'
  map global grep c -docstring "get context"     ':multi-file-from-grep <ret>'
}

hook global WinSetOption filetype=multi-file %{
  alias buffer w multi-file-apply
  map buffer user R -docstring "review changes"   ':multi-file-review <ret>'
  map buffer user w -docstring "write changes"    ':multi-file-apply <ret>'
  map global grep r -docstring "review changes"   ':multi-file-review <ret>'
  map global grep w -docstring "write changes"    ':multi-file-apply <ret>'
}
