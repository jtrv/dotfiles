#!/bin/sh
# Bar: niri-wm/niri#3621 (press/release keybinds) merged -> voxtype back to push-to-talk via niri press/release binds (nixos-config docs/plan.md, security)
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
m=$(gh api repos/niri-wm/niri/pulls/3621 --jq '.state + " " + (.merged_at // "")' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
case "$m" in
  "open "*) echo "NOT-READY: niri#3621 (release binds) still open" ;;
  "closed ") echo "CHECK: niri#3621 closed unmerged — look for a successor PR" ;;
  *) echo "CHECK: niri#3621 merged — wait for a niri release, then move voxtype to niri press/release binds" ;;
esac
