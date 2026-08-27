if status is-interactive
  carapace _carapace          | source
  atuin init fish             | source
  mise activate fish          | source
  pay-respects fish --alias f | source
  starship init fish          | source
  fish_config theme choose catppuccin-mocha
end

# fix ssh agent
if not set -q SSH_AUTH_SOCK
  eval (ssh-agent -c) &> /dev/null
end
