hook global WinSetOption filetype=html %{
  set-option window lintcmd "tidy -e --gnu-emacs yes --quiet yes 2>&1"
  lint
  define-command emmet %{ execute-keys "giGl| emmet <ret>" }
  define-command minify %{ execute-keys "<percent>| minify --type html <ret><a-j>" }
  map window dev e -docstring "emmet" ':emmet <ret>'
  map window dev m -docstring "minify" ':minify <ret>'
}
hook global BufSetOption filetype=(html) %{
  set-option buffer formatcmd "prettier --stdin-filepath=%val{buffile}"
}
