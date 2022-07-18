hook global WinSetOption filetype=html %{
  set-option window lintcmd "tidy -e --gnu-emacs yes --quiet yes 2>&1"
  lint
  define-command emmet %{ execute-keys "giGl| emmet <ret>" }
  define-command minify %{ execute-keys "<percent>| minify --type html <ret><a-j>" }
  map global dev e -docstring "emmet" ':emmet <ret>'
  map global dev m -docstring "minify" ':minify <ret>'
}
hook global BufSetOption filetype=(html) %{
  set-option buffer formatcmd "prettierd %val{buffile}"
}
