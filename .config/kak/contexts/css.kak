hook global WinSetOption filetype=(css|scss) %{
  set-option window lintcmd "stylelint --config ~/.config/.stylelintrc --stdin --stdin-filename %val{buffile}"
  lint
  define-command emmet %{ execute-keys "giGl| emmet <ret>" }
  define-command minify %{ execute-keys "<percent>|minify --type html <ret><a-j>" }
  map global dev e -docstring "emmet" ':emmet <ret>'
  map global dev m -docstring "minify" ':minify <ret>'
}
hook global BufSetOption filetype=(css|scss) %{
  set-option buffer formatcmd "prettier --stdin-filepath=%val{buffile}"
}
