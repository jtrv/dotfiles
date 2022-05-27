hook global BufSetOption filetype=markdown %{
  set-option buffer formatcmd 'pandoc -f commonmark -t commonmark'
}
