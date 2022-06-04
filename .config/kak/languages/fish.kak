hook global WinSetOption filetype=fish %{
  set-option window lintcmd "fish -n"
  lint
}
hook global WinSetOption filetype=fish %{
  set-option buffer formatcmd "fish_indent"
}
