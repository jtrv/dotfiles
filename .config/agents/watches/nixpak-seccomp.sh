#!/bin/sh
# Bar: nixpak#12 (seccomp rules) closed -> re-evaluate nixpak vs hardened firejail for the Electron apps (nixos-config docs/reports/sandboxing/README.md)
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
s=$(gh api repos/nixpak/nixpak/issues/12 --jq .state 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
if [ "$s" = "open" ]; then echo "NOT-READY: nixpak#12 (seccomp) still open"
else echo "CHECK: nixpak#12 closed — confirm seccomp landed in a release, then revisit firejail vs nixpak in docs/reports/sandboxing/README.md"
fi
