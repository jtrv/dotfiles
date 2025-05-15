complete -c docs -n '__fish_is_first_arg' -f -a "(dedoc ls -ln --porcelain)"
complete -c docs -n 'not __fish_is_first_arg' -f -a "(dedoc ss -i --porcelain (commandline -op)[2])"
