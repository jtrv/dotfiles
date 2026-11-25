#!/bin/sh
# Bar: netwatch's parser_layer_leaves_fast_open_and_autobind_open handles kernels whose Landlock denies TCP Fast Open -> drop the netwatch checkFlags skip in nixos-config/nixos/pkgs/default.nix
# Baseline 2026-11-21: v0.39.0 asserts sendto(MSG_FASTOPEN) == Ok(9); kernel 7.2 returns EACCES.
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
t=$(gh api repos/matthart1983/netwatch/releases --jq '.[0].tag_name // empty' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
[ -n "$t" ] || { echo "UNKNOWN: netwatch has no releases listed"; exit 0; }
case "$t" in
  v0.39.0|0.39.0) echo "NOT-READY: netwatch latest release is still $t" ;;
  *) echo "CHECK: netwatch $t released - see if the fast-open test tolerates EACCES, then drop the skip" ;;
esac
