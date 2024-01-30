set-option window formatcmd "dprint fmt --stdin=format.toml --config=$XDG_CONFIG_HOME/dprint/dprint.json"

set-option window lintcmd 'taplo lint %val{buffile}'
