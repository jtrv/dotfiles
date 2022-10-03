hook global WinSetOption filetype=sh %{
  set-option window lintcmd "shellcheck -fgcc -Cnever"
  set-option buffer formatcmd "shfmt"
  lint
}
