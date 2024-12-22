complete -c docs -n '__fish_is_first_arg' -f -a "(dedoc ls -ln | awk '{print \$1}')"
complete -c docs -n 'not __fish_is_first_arg' -f -a "(dedoc ss -i (commandline -op)[2] | awk 'NR > 2 {print \$2}')"
