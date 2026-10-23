# clipboard integration
# see https://discuss.kakoune.com/t/clipboard-integration-using-osc-52/1002/7
define-command push-clip -docstring '
  push kakoune''s " register to external clipboard
' %{ nop %sh{
  encoded=$(printf %s "$kak_main_reg_dquote" | base64 | tr -d '\n')
  printf "\033]52;;%s\a" "$encoded" >"/proc/$kak_client_pid/fd/0"
}}
define-command pull-clip -docstring '
  pull external clipboard into kakoune''s " register
' %{ set-register dquote %sh{ wl-paste -n } }

hook -group clip global NormalKey 'y|d|c' %{ push-clip }
hook -group clip global KakBegin  '.*'    %{ pull-clip }
hook -group clip global FocusIn   '.*'    %{ pull-clip }
