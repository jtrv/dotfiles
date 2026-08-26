#!/bin/sh
# Bar: nixpkgs#345978 (systemctl kexec preempts prepare-kexec; systemd#40743 closed wontfix-ish) resolved -> drop the pre-load wrapper in ~/.local/bin/rbt
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
s=$(gh api repos/NixOS/nixpkgs/issues/345978 --jq .state 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
if [ "$s" = "open" ]; then echo "NOT-READY: nixpkgs#345978 still open — keep the rbt pre-load wrapper"
else echo "CHECK: nixpkgs#345978 closed — if the module now loads before systemctl kexec, revert rbt to plain systemctl kexec"
fi
