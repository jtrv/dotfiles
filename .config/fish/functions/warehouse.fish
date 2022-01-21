# Defined via `source`
function warehouse
  paru -Qqet > ~/.config/warehouse/pacman
  cargo install --list | rg -o '^(\w.+)\s' -r '$1' > ~/.config/warehouse/cargo
  /bin/cat ~/.config/fish/fish_plugins > ~/.config/warehouse/fish
  pnpm list -g | rg -o '(\w.+)\s\d' -r '$1' > ~/.config/warehouse/npm
  config diff ~/.config/warehouse/*
end
