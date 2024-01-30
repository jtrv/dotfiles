define-command grep-write -docstring "
  grep-write: pipes the current grep-buffer to grug -w and prints the results
" %{
  declare-option -hidden str grug_buf
  evaluate-commands -draft %{
    evaluate-commands %sh{
      echo "set-option window grug_buf '$(mktemp /tmp/grug_buf.XXX)'"
    }
    write -sync -force %opt{grug_buf}
    evaluate-commands %sh{
      cat "$kak_opt_grug_buf" | grug -w |
        xargs -I{} echo "echo -markup {Information} '{}'; echo -debug '{}';"
    }
  }
}

hook window WinSetOption filetype=grep %{
  alias window w grep-write
  alias window wq grep-write-quit
  alias window write grep-write
  alias window write-quit grep-write-quit
  map window grep e -docstring "get context"     ':grep-expand <ret>'
  map window grep w -docstring "write changes"   ':grep-write <ret>'
  map window user e -docstring "get context"     ':grep-expand <ret>'
  map window user l -docstring "live-grep"       ':live-grep <ret>'
  map window user w -docstring "write changes"   ':grep-write <ret>'
}

hook window WinSetOption filetype=grep-expand %{
  alias window w grep-expand-write
  alias window write grep-expand-write
  map window grep r -docstring "review changes"   ':grep-expand-review <ret>'
  map window grep w -docstring "write changes"    ':grep-expand-write <ret>'
  map window user r -docstring "review changes"   ':grep-expand-review <ret>'
  map window user w -docstring "write changes"    ':grep-expand-write <ret>'
}
