hook global WinSetOption filetype=grep %{
  map buffer normal D -docstring "delete line"   'xd'
}
