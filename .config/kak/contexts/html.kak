hook global WinSetOption filetype=html %{
  set-option window lintcmd "tidy -e --gnu-emacs yes --quiet yes 2>&1"
  lint
}
hook global BufSetOption filetype=(html) %{
  set-option buffer formatcmd "prettierd %val{buffile}"

  define-command emmet -override %{ execute-keys "giGl| emmet <ret>" }
  define-command minify -override %{ execute-keys "<percent>| minify-html --minify-css --minify-js <ret><percent>" }

  map buffer dev e -docstring "emmet" ':emmet <ret>'
  map buffer dev m -docstring "minify" ':minify <ret>'
}
