hook global BufSetOption filetype=yaml %{
  set-option buffer formatcmd "prettierd %val{buffile}"
}

hook global WinSetOption filetype=yaml %{
set-option window lintcmd %{
  run() {
    # change [message-type] to message-type:
    yamllint -f parsable "$1" | sed 's/ \[\(.*\)\] / \1: /'
  } && run }
}
