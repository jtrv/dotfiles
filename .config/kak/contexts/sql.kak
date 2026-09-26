# sqlfluff only reads a .sqlfluff sitting above the file it is given, and format/lint
# hand it stdin or a copy in /tmp, so resolve the buffer's config here and pass it in.
evaluate-commands %sh{
  d=$(dirname "$kak_buffile")
  while [ "$d" != / ] && [ ! -f "$d/.sqlfluff" ]; do d=$(dirname "$d"); done
  [ -f "$d/.sqlfluff" ] || exit 0
  # fix exits 1 when violations it cannot fix remain; its output is still the fixed text
  printf 'set-option window formatcmd %%{sqlfluff fix -q --config %s - 2>/dev/null; [ $? -le 1 ]}\n' "$d/.sqlfluff"
  printf 'set-option window lintcmd %%{%s/.config/kak/scripts/sqlfluff-lint %s}\n' "$HOME" "$d/.sqlfluff"
}

# This file is sourced per window; redeclaring would reset a toggled choice.
evaluate-commands %sh{
  [ -n "$kak_opt_sql_linter" ] ||
    echo "declare-option -docstring 'sqruff: live LSP diagnostics; sqlfluff: lint on save' str sql_linter sqruff"
}

define-command -override -docstring 'switch SQL linting between sqruff (live) and sqlfluff (on save)' sql-linter-toggle %{
  evaluate-commands %sh{
    [ "$kak_opt_sql_linter" = sqruff ] && echo 'set-option global sql_linter sqlfluff' || echo 'set-option global sql_linter sqruff'
  }
  sql-linter-apply
  echo -markup "{Information}SQL linter: %opt{sql_linter}"
}

define-command -override -hidden sql-linter-apply %{
  remove-hooks window sql-linter
  evaluate-commands %sh{
    if [ "$kak_opt_sql_linter" = sqruff ]; then
      echo 'try lint-hide-diagnostics'
      echo 'set-option buffer lsp_servers "%opt{lsp_server_sqls}%opt{lsp_server_sqruff}"'
      echo 'try lsp-did-change'
    else
      # kak-lsp keeps the last diagnostics it got, so sqruff's would linger
      for o in lsp_inline_diagnostics lsp_diagnostic_lines lsp_inlay_diagnostics \
        lsp_diagnostic_error_count lsp_diagnostic_warning_count lsp_diagnostic_info_count lsp_diagnostic_hint_count; do
        echo "unset-option buffer $o"
      done
      echo 'set-option buffer lsp_servers %opt{lsp_server_sqls}'
      echo 'hook window -group sql-linter BufWritePost .* lint'
      echo 'lint'
    fi
  }
}

sql-linter-apply
ui-lsp-enable
