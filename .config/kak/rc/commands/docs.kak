define-command cat -docstring '
  cat [<files>]: bat utility wrapper
  Print the files (or buffile) using bat
' -params .. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *bat* -- bat --style=plain --color=always %val{buffile}"
  else
    echo "ansi-fifo -name *bat* -- bat --style=plain --color=always %arg{@}"
  fi
}}

define-command mcat -docstring '
  mcat [<files>]: mcat utility wrapper
  Open an mcat formatted view of the provided files
' -params 1.. %{
  ansi-fifo -name *mcat* -- unbuffer mcat -P --toc --padding 1 %arg{@};
}
complete-command -menu mcat shell-script-candidates %{fd -e md}
hook global WinSetOption current_bufname=\*mcat\* %{
  ui-trailing-spaces-disable
  ui-line-numbers-disable
}

define-command kan -docstring '
  kan <query>: man utility wrapper
  Either show a man-page or the --help text for the given query
' -params 0.. %{ evaluate-commands %sh{
  if [ $# -eq 0 ] && man -w "$kak_selection" > /dev/null; then
    echo "man \"$kak_selection\""
  elif [ $# -eq 0 ] && $("$kak_selection" --help > /dev/null || "$kak_selection" -h > /dev/null); then
    echo "kelp \"$kak_selection\""
  elif man -w "$*" > /dev/null; then
    echo "man \"$*\""
  elif "$*" --help > /dev/null || "$*" -h > /dev/null; then
    echo "kelp \"$*\""
  fi
}}

define-command kelp -docstring '
  kelp <command>: --help output utility
  Show the --help output for the given command inside kakoune
' -shell-completion -params 0.. %{ evaluate-commands %sh{
  if [ $# -eq 0 ] && "$kak_selection" --help > /dev/null; then
    echo "ansi-fifo -name *help* -- \"$kak_selection\" --help"
  elif [ $# -eq 0 ] && "$kak_selection" -h > /dev/null; then
    echo "ansi-fifo -name *help* -- \"$kak_selection\" -h"
  elif "$*" --help > /dev/null; then
    echo "ansi-fifo -name *help* -- \"$*\" --help"
  elif "$*" -h > /dev/null; then
    echo "ansi-fifo -name *help* -- \"$*\" -h"
  fi
}}

define-command pcsv -docstring '
  pcsv [<files>]: csv viewing utility
  Print the files (or buffile) using bat and columns
' -file-completion -params .. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *pcsv* -- pcsv %val{buffile}"
  else
    echo "ansi-fifo -name *pcsv* -- pcsv %arg{@}"
  fi
}}

define-command ptsv -docstring '
  ptsv [<files>]: tsv viewing utility
  Print the files (or buffile) using bat and columns
' -file-completion -params .. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *ptsv* -- ptsv %val{buffile}"
  else
    echo "ansi-fifo -name *ptsv* -- ptsv %arg{@}"
  fi
}}

define-command reader-mode -docstring 'Enables settings for better reading' %{
  require-module "ui"
  try rainbow-disable-window
  try number-toggle-disable
  try ui-trailing-spaces-disable
  try ui-whitespaces-disable
}
hook global WinDisplay '\*(delta|diff|docs|greet|help|man|stdin|tldr).*\*' %{
  reader-mode
}

define-command tldr -docstring '
  tldr <command>: tldr utility wrapper
  Cheatsheet for the given command
' -shell-completion -params 0.. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "ansi-fifo -name *tldr* -- tldr --color=always %val{selection}"
  else
    echo "ansi-fifo -name *tldr* -- tldr --color=always %arg{@}"
  fi
}}
