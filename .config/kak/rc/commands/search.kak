set-option global grepcmd 'rg --color=always --smart-case --with-filename --line-number --column'
require-module grep
alias global kg grep

define-command doc-grep -docstring '
  doc-grep <query>: grep kakoune and plugin docs
' -params .. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    grep_args=%val{selection}
  else
    grep_args=%arg{@}
  fi

  fd \
  --absolute-path \
    --exclude '*changelog*' \
    --search-path "$(dirname $(dirname ${kak_runtime%/share/kak}))" \
    --search-path "${kak_config}" \
    --extension=asciidoc |
      xargs echo "grep ${grep_args}"
}}

define-command file-picker -docstring '
  file-picker: Opens file picker.
' %{
  prompt file: -shell-script-candidates 'fd --type=file' %{
    edit %val{text}
  }
}

define-command global-picker -docstring 'global-picker: Opens global search picker.' %{
  # provides word completion
  prompt grep: -shell-script-candidates %{
    echo "write '$kak_response_fifo'" > "$kak_command_fifo"
    cat "$kak_response_fifo" | kak -f 's[\w-]{4,}<ret>y%<a-R>a<ret>'
  } %{
    grep %val{text}
  }
}

define-command grep-buffers -docstring '
  grep-buffers [<pattern>]: search for a pattern in all buffers
  If <pattern> is not specified, the content of the main selection is used
' -params .. %{ evaluate-commands %sh{
  if [ $# -eq 0 ]; then
    echo "grep -F %val{selection} %val{buflist}"
  else
    echo "grep %arg{@} %val{buflist}"
  fi
}}
