hook global WinSetOption current_bufname=.*\.grep$ %{ set-option buffer filetype grep }

hook global WinSetOption filetype=grep %{
  ansi-enable

  alias window w grep-write

  map window normal <ret> ':grep-jump <ret>'

  map window user e -docstring "get context"     ':grep-expand <ret>'
  map window user w -docstring "write changes"   ':grep-write <ret>'
}
