define-command comment -docstring '(Un)Comment lines' %{
  try %{
    execute-keys '_'
    comment-block
  } catch comment-line
}

define-command iplan -docstring 'Insert a commented problem-solving plan' %{
  evaluate-commands -save-regs '"' %{
    set-register '"' %{PROBLEM (rephrased):
INPUT:   shape + example
OUTPUT:  shape + example
EDGE CASES: empty · only one item · duplicates · NULL/undefined · bad input · huge input
APPROACH (out loud before typing):
  1.
  2.
TESTS:
  f(example) →
  f([])      →
  f(edge)    →
COMPLETE: what's slow? what could I change with more time?
}
    execute-keys '<a-o>jPx'
    try comment-line catch comment-block
  }
}

define-command emmet -docstring 'expand the emmet abbreviation on the current line' %{
  execute-keys 'giGl|emmet <ret>'
}

define-command dic -docstring '
  dic <query>: dic utility wrapper
  Generate dictionary results for the given query inside kakoune
' -params 0..2 %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *dic* -- dic %val{selection}"
  else
    echo "ansi-fifo -name *dic* -- dic %arg{@}"
  fi
}}

define-command math -docstring '
  math <expression>: qalc utility wrapper
  Replace the selection with the solution of the given expression where x=selection
' -params 0.. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    printf %s\\n "
    prompt 'expression:' -init 'x' %{
      execute-keys \"| xargs -I x qalc -t '%val{text}' <ret>\"
    }"
  else
    printf %s\\n "
      execute-keys \"| xargs -I x qalc -t '$@' <ret>\""
  fi
}}

define-command rnd -docstring '
  rnd: go to a random line
' %{ evaluate-commands %sh{
    echo "execute-keys '$(shuf -i 1-$kak_buf_line_count)g'"
}}

define-command save-macro-as -docstring '
  save-macro-as <command-name>: define-command with macro register
' -params 1 %{
  define-command %arg{1} -override %{ execute-keys "%reg{@}" }
}

define-command seq -docstring '
seq: <start?> <inc?>
insert numbered output to cursors
' -params 0.. %{ evaluate-commands %sh{
  start=${1:-1}; increment=${2:-1}
  end=$(( start + increment * (kak_selection_count - 1) ))
  echo "
    edit -scratch
    execute-keys '!seq -w $start $increment $end <ret>'
    execute-keys '<a-s>_y:db<ret>P'
  "
}}

define-command set-filetype -docstring 'prompt to set filetype' %{
  prompt filetype: -shell-script-candidates %{
      fd --base-directory "$kak_runtime/rc/filetype" -t f -x basename -s .kak {}
    } %{
      set buffer filetype %val{text}
  }
}

define-command thes -docstring '
  thes <query>: thesauromatic utility wrapper
  Generate thesaurus results for the given query
' -params 0..2 %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *thes* -script \"thesauromatic %val{selection} | col %val{window_width}\""
  else
    echo "ansi-fifo -name *thes* -script \"thesauromatic %arg{@} | col %val{window_width}\""
  fi
}}
