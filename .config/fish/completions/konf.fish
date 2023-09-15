function __konf__complete
    pushd "$XDG_CONFIG_HOME"
    __fish_complete_directories
    popd
end

complete -x -c konf -a "(__konf__complete)"
