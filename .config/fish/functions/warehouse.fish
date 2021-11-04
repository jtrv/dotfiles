# Defined via `source`
function warehouse
  paru -Qetq | sd "^x[d|f|o].*\n" "" > ~/.config/warehouse/pacman
  cargo install --list | sd "\sv\d.*\n" "\n" | sd "^\s.*\n" "" > ~/.config/warehouse/cargo
  /bin/cat ~/.config/fish/fish_plugins > ~/.config/warehouse/fish
  config diff ~/.config/warehouse/*
end
