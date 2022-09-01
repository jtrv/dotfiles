hook global WinSetOption filetype=grep %{
  alias buffer w grep-write
  alias buffer wq grep-write-quit
  map buffer user c -docstring "get context"     ':multi-file-from-grep <ret>'
  map buffer grep c -docstring "get context"     ':multi-file-from-grep <ret>'
  map buffer user w -docstring "write changes"   ':grep-write <ret>'
  map buffer grep w -docstring "write changes"   ':grep-write <ret>'
}

hook global WinSetOption filetype=multi-file %{
  alias buffer w multi-file-apply
  map buffer user r -docstring "review changes"   ':multi-file-review <ret>'
  map buffer grep r -docstring "review changes"   ':multi-file-review <ret>'
  map buffer user w -docstring "write changes"    ':multi-file-apply <ret>'
  map buffer grep w -docstring "write changes"    ':multi-file-apply <ret>'
}
