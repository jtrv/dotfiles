set-option window formatcmd "prettierd format.yml"

set-option window lintcmd %{
  run() {
    # change [message-type] to message-type:
    yamllint -f parsable "$1" | sed 's/ \[\(.*\)\] / \1: /'
  } && run
}
