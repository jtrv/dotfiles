define-command fifo-alias -docstring '
 fifo-alias <command>: Forwards outputs of the command given as
 parameter to a new fifo buffer and highlights text based on ansi color codes
' -params 1.. %{
  ansi-fifo -scroll -- %arg{@}
}
alias global : fifo-alias

define-command bgsh -docstring '
  bgsh [<commands>]: background shell utility
  execute one-off commands in the background
' -shell-completion -params .. %{ ansi-fifo-bg -name *bg* -- %arg{@} }
alias global :: bgsh

define-command bun -docstring '
  bun [<arguments>]: bun utility wrapper
  Launch bun with the given arguments inside kakoune
' -params 1.. %{
  ansi-fifo -name *bun* -scroll -- env FORCE_COLOR=1 bun %arg{@}
}

define-command cargo -docstring '
  cargo [<arguments>]: cargo utility wrapper
  Launch cargo with the given arguments inside kakoune
' -params 1.. %{
  ansi-fifo -name *cargo* -scroll -- cargo --color=always %arg{@}
}

define-command go -docstring '
  go [<arguments>]: go utility wrapper
  Launch go with the given arguments inside kakoune
' -params 1.. %{
  ansi-fifo -name *go* -scroll -- go %arg{@}
}

define-command npm -docstring '
  npm [<arguments>]: npm utility wrapper
  Launch npm with the given parameters inside kakoune
' -params 1.. %{
  ansi-fifo -name *npm* -scroll -- npm %arg{@}
}

define-command pastel -docstring '
  pastel [<arguments>]: pastel utility wrapper
  Launch pastel with the given parameters inside kakoune
' -params 0.. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *pastel* -- unbuffer pastel color %val{selection}"
  else
    echo "ansi-fifo -name *pastel* -- unbuffer pastel %arg{@}"
  fi
}}

define-command watchexec -docstring '
  watchexec [<args>] <command>: watchexec utility wrapper
  execute the given command when the current directory changes
' -shell-completion -params 0.. %{
  ansi-fifo -name *watchexec* -- watchexec %arg{@}
}

define-command watchthis -docstring '
  watchthis [<args>] <command>: watchexec utility wrapper
  execute the given command when the current file changes
' -shell-completion -params 0.. %{
  ansi-fifo -name *watchexec* -- watchexec --watch %val{buffile} %arg{@}
}

define-command xargs -docstring '
  xargs [<arguments>]: xargs utility wrapper
  execute a command with each selection, selections are represented with {} as a placeholder
' %{
  prompt 'command:' %{
    execute-keys "| xargs -I {} %val{text} <ret>"
  }
}
