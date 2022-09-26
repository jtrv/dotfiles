hook global WinSetOption filetype=(css|scss) %{
  set-option window lintcmd "stylelint_d --config ~/.config/.stylelintrc --stdin --stdin-filename %val{buffile}"
  lint
}
hook global BufSetOption filetype=(css|scss) %{
  set-option buffer formatcmd "prettierd %val{buffile}"

  define-command emmet -override %{ execute-keys "giGl| emmet <ret>" }
  define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

  map buffer dev e -docstring "emmet" ':emmet <ret>'
  map buffer dev m -docstring "minify" ':minify <ret>'
}
