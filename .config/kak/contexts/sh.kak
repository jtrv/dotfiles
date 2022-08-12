hook global WinSetOption filetype=sh %{
  set-option window lintcmd "shellcheck -fgcc -Cnever"
  lint
}
hook global WinSetOption filetype=sh %{
  set-option buffer formatcmd "shfmt"
}
