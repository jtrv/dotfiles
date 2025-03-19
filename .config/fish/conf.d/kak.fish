function config-grep -d "grep config files in kak"
  set config_files (config ls-files | while read line; printf "\"%s\" " "$line"; end)
  set -l escaped_args (string escape --style=script -- $argv)
  kak -e "grep $escaped_args $config_files; buffer-only; echo; info-buffers"
end
complete -c config-grep -w rg

function kd -d "edit all fd results in kak"
  k (fd $argv)
end
complete -c kd -w fd

function kda -d "open delta output in kak"
  set -l escaped_args (string escape --style=script -- $argv)
  kak -e "delta $escaped_args; buffer-only; echo; info-buffers"
end

function kdr -d "make path and edit in kak"
  for i in $argv
    mkdir -p (dirname $i)
    k $i
  end
end

function kg -d "grep with kakoune"
  set -l escaped_args (string escape --style=script -- $argv)
  kak -e "grep $escaped_args; buffer-only; echo; info-buffers"
end
complete -c kg -w rg

function kgl -d "kakoune live grep"
  kak -e 'live-grep; buffer-only;echo "live-grep"; info-buffers'
end

function kp -d "kakpipe"
  set -l escaped_args (string escape --style=script -- $argv)
  kak -e "kakpipe -- $escaped_args"
end
