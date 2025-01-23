function config-grep
  set config_files (config ls-files | while read line; printf "\"%s\" " "$line"; end)
  set grepargs
  for x in $argv
    set -a grepargs (echo $x | sed -e "s/'/''/g" -e "s/^/'/" -e "s/\$/'/")
  end
  kak -e "grep $(string join -- " " $grepargs) $config_files; buffer-only; echo; info-buffers"
end
complete -c config-grep -w rg

function kd
  k (fd $argv)
end
complete -c kd -w fd

function kda
  kak -e "delta $argv; buffer-only; echo; info-buffers"
end

function kg
  set grepargs
  for x in $argv
    set -a grepargs (echo $x | sed -e "s/'/''/g" -e "s/^/'/" -e "s/\$/'/")
  end
  kak -e "grep $(string join -- " " $grepargs); buffer-only; echo; info-buffers"
end
complete -c kg -w rg

function kgl
  kak -e 'live-grep; buffer-only;echo "live-grep"; info-buffers'
end

function kp
  kak -e "kakpipe -- $argv"
end

alias k       'kak'
alias kakrc   'k ~/.config/kak/kakrc'
alias kenv    'k ~/.config/fish/env.fish'
alias kish    'k ~/.config/fish/config.fish'
