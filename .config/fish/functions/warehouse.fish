# Defined via `source`
function warehouse
  paru -Qqet > ~/.config/warehouse/pacman
  cargo install --list | rg -o '^(\w.+)\sv' -r '$1' > ~/.config/warehouse/cargo
  cat ~/.config/fish/fish_plugins > ~/.config/warehouse/fish
  config diff ~/.config/warehouse/*
end
