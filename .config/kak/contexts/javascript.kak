hook global WinSetOption filetype=javascript %{
  set-option window lintcmd 'run() { cat "$1" | eslint_d -c ~/.config/.eslintrc.js -f unix --stdin --stdin-filename "$kak_buffile";} && run '
  lint
  define-command emmet %{ execute-keys "giGl| emmet <ret>" }
  define-command minify %{ execute-keys "<percent>| minify-html <ret><percent>" }
  map global dev e -docstring "emmet" ':emmet <ret>'
  map global dev m -docstring "minify" ':minify <ret>'
}
hook global BufSetOption filetype=javascript %{
  set-option buffer formatcmd "prettierd %val{buffile}"
  map -docstring "comment" buffer normal <#> ':comment-line <ret>'
}
