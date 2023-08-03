hook global BufSetOption filetype=(toml) %{
  set-option buffer formatcmd "dprint fmt --stdin format.toml --config $XDG_CONFIG_HOME/dprint/dprint.json"
}

hook global WinSetOption filetype=(toml) %{
  set-option window lintcmd 'taplo lint %val{buffile}'
}
