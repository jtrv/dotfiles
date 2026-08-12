# Replaces the fisher eth-p/fish-plugin-sudo wrapper (which used `sudo -sE`):
# fish plugins are nix-managed now and that one isn't packaged. sudo-rs warns on
# bare -E, so drop it while keeping fish as the sudo shell.
function sudo
	env SHELL=(which fish) sudo -s $argv
end
