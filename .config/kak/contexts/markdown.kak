hook global BufSetOption filetype=markdown %{
  set-option buffer formatcmd "dprint fmt --stdin=format.md --config=$XDG_CONFIG_HOME/dprint/dprint.json"
}
