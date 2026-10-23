define-command yo -docstring '
  yo <query>: claude utility wrapper
  Query Claude and stream the response to a fifo buffer

  Options:
    --model <MODEL>       Select a model (sonnet, opus, haiku)
    -c, --continue        Continue the most recent conversation
    -r, --resume <ID>     Resume a session
    --append-system-prompt <PROMPT>  Extend the system prompt
' -params 1.. %{
  ansi-fifo -name *claude* -- claude -p %arg{@}
  set-option buffer filetype markdown
}
define-command yo-buffer -docstring '
  opens a *yo-prompt* buffer for writing prompts to pass to yo
' %{ edit -scratch *yo-prompt* ; set-option buffer filetype yo-prompt }
define-command yo-buffer-write -docstring '
  send the *yo-prompt* buffer to yo
' -params 0.. %{
  buffer *yo-prompt*
  execute-keys '%'
  yo %arg{@} %val{selection}
}
hook global BufSetOption filetype=yo-prompt %{
  alias buffer write yo-buffer-write
  alias buffer w yo-buffer-write
}
