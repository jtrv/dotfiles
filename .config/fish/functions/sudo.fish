# Shadows fishPlugins.plugin-sudo's wrapper (which uses `sudo -sE`).
# sudo-rs warns on bare -E, so drop it while keeping fish as the sudo shell.
function sudo
	env SHELL=(which fish) sudo -s $argv
end
