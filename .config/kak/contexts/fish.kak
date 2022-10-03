hook global WinSetOption filetype=fish %{
  set-option buffer formatcmd "fish_indent"
  set-option window lintcmd "fish -n"
  lint
}
