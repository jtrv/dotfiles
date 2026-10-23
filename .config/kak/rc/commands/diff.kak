define-command delta -docstring '
  delta [<arguments>]: delta utility wrapper
  Launch delta with the given arguments inside kakoune
' -shell-completion -params 1.. %{
  ansi-fifo -name *delta* -- delta %arg{@}
}

define-command delta-buffers -docstring '
  delta-buffers <buffer-a> <buffer-b>: delta utility
  Generate a delta diff between <buffer-a> and <buffer-b>
' -buffer-completion -params 2 %{ diff-impl delta buffers %arg{@} }

define-command delta-selections -docstring '
  delta-selections <buffer>: delta utility
  Generate a delta diff between the selections and <buffer>
' -buffer-completion -params 1 %{ diff-impl delta selections %arg{@} }

define-command diff -docstring '
  diff [<arguments>]: diff utility wrapper
  Generate a diff with the given arguments
' -shell-completion -params 1.. %{
  ansi-fifo -name *diff* -- diff -u %arg{@}; set buffer filetype diff;
}

define-command difft -docstring '
  difft [<arguments>]: difftastic utility wrapper
  Generate a diff with difftastic and the given arguments
' -shell-completion -params 1.. %{
  ansi-fifo -name *difft* -- difft --width=%val{window_width} --color=always %arg{@}
}

define-command diff-buffers -docstring '
  diff-buffers <buffer-a> <buffer-b>: diff utility
  Generate a diff buffer between <buffer-a> and <buffer-b>
' -buffer-completion -params 2 %{ diff-impl diff buffers %arg{@} }

define-command diff-selections -docstring '
  diff-selections <buffer>: diff utility
  Generate a diff buffer between the selections and <buffer>
' -buffer-completion -params 1 %{ diff-impl diff selections %arg{@} }

define-command -hidden diff-impl -docstring '
  diff-impl <diff|delta> buffers <buffer-a> <buffer-b>
  diff-impl <diff|delta> selections <buffer>
' -params 3..4 %{ evaluate-commands %sh{
  tool=$1 mode=$2; shift 2
  dir=$(mktemp -d)
  if [ "$mode" = selections ]; then
    a='*selections*' b=$1
    echo "execute-keys '<a-|>sed -e ''\$a\\'' >> $dir/a<ret>'"
  else
    a=$1 b=$2
    echo "evaluate-commands -buffer '$a' write -force $dir/a"
  fi
  echo "evaluate-commands -buffer '$b' write -force $dir/b"
  if [ "$tool" = delta ]; then
    echo "ansi-fifo -name *delta-$mode* -script %{diff -u --label '$a' --label '$b' $dir/a $dir/b | delta --paging=never; rm -r $dir}"
  else
    echo "
      edit! -scratch *diff-$mode*
      set buffer filetype diff
      set-register | 'diff -u --label ''$a'' --label ''$b'' $dir/a $dir/b; rm -r $dir'
      execute-keys '!<ret>gk'
    "
  fi
}}

define-command zet-buffers -docstring '
  zet-buffers <command> <buffer>...: zet utility
  Treat each buffer as a set of lines, combine them into a scratch buffer
    union      lines appearing in ANY buffer
    intersect  lines appearing in EVERY buffer
    diff       lines appearing in the FIRST buffer and no other
    single     lines appearing exactly once
    multiple   lines appearing more than once
  Each line is printed at most once, in order of first occurrence
' -buffer-completion -params 2.. %{ zet-impl buffers %arg{@} }

define-command zet-selections -docstring '
  zet-selections <command> [<buffer>...]: zet utility
  Like zet-buffers, but the selections are the FIRST set and each buffer another
    union      lines appearing in ANY set
    intersect  lines appearing in EVERY set
    diff       lines appearing in the selections and no buffer
    single     lines appearing exactly once
    multiple   lines appearing more than once
  Each line is printed at most once, in order of first occurrence
' -buffer-completion -params 1.. %{ zet-impl selections %arg{@} }

define-command -hidden zet-impl -docstring '
  zet-impl <buffers|selections> <command> [<buffer>...]
' -params 2.. %{ evaluate-commands %sh{
  mode=$1 op=$2; shift 2
  case $op in
    union|intersect|diff|single|multiple) ;;
    *) echo "fail %{zet-$mode: expected union, intersect, diff, single or multiple}"; exit ;;
  esac
  dir=$(mktemp -d)
  files=
  if [ "$mode" = selections ]; then
    echo "execute-keys '<a-|>sed -e ''\$a\\'' >> $dir/0<ret>'"
    files=" $dir/0"
  fi
  n=0
  for buf in "$@"; do
    n=$((n + 1))
    echo "evaluate-commands -buffer '$buf' write -force $dir/$n"
    files="$files $dir/$n"
  done
  echo "
    edit! -scratch *zet-$mode*
    set-register | 'zet $op$files; rm -r $dir'
    execute-keys '!<ret>gexdgk'
  "
}}
