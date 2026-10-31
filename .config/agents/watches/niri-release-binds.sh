#!/bin/sh
# Bar: niri-wm/niri#3621 (press/release keybinds) in a niri release -> voxtype back to push-to-talk via niri press/release binds (nixos-config docs/plan.md, security)
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
m=$(gh api repos/niri-wm/niri/pulls/3621 --jq '.state + " " + (.merged_at // "")' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
case "$m" in
  "open "*) echo "NOT-READY: niri#3621 (release binds) still open"; exit 0 ;;
  "closed ") echo "CHECK: niri#3621 closed unmerged — look for a successor PR"; exit 0 ;;
esac
merged=${m#closed }
rel=$(gh api repos/niri-wm/niri/releases/latest --jq '.tag_name + " " + .published_at' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
# ISO-8601 UTC timestamps compare correctly as strings
if [ "$(printf '%s\n%s\n' "${rel#* }" "$merged" | sort | tail -n1)" = "${rel#* }" ]; then
  echo "CHECK: niri ${rel%% *} released after #3621 merged — once nixpkgs has it, move voxtype to niri press/release binds"
else
  echo "NOT-READY: niri#3621 merged $(echo "$merged" | cut -c1-10), latest release ${rel%% *} predates it"
fi
