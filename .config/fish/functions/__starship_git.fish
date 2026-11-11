# Autoloaded by fish-async-prompt's background child (see config.fish). The
# empty-line filter drops the newline starship's add_newline puts before profiles too.
function __starship_git
    starship prompt --profile git | string match -v ""
end
