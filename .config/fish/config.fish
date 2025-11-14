if status is-interactive
  carapace _carapace          | source
  atuin init fish             | source
  mise activate fish          | source
  pay-respects fish --alias f | source
  starship init fish          | source
end

# fix ssh agent
if not set -q SSH_AUTH_SOCK
  eval (ssh-agent -c) &> /dev/null
end

# Start X at login
if status is-login
  if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
    echo "Starting X11. Press <C-c> to cancel"
    sleep 2
    exec startx -- -keeptty &>/dev/null
  end
end
