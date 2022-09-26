hook global WinSetOption filetype=javascript %{
  set-option window lintcmd 'run() { cat "$1" | eslint_d -c ~/.config/.eslintrc.js -f unix --stdin --stdin-filename "$kak_buffile";} && run '
  lint
}
hook global BufSetOption filetype=javascript %{
  set-option buffer formatcmd "prettierd %val{buffile}"

  define-command emmet -override %{ execute-keys  "giGl| emmet <ret>" }
  define-command minify -override %{ execute-keys "<percent>| minify-html <ret><percent>" }

  map buffer dev e      -docstring "emmet"     ':emmet <ret>'
  map buffer dev m      -docstring "minify"    ':minify <ret>'

  map buffer normal <#> -docstring "comment"   ':comment-line <ret>'
}
