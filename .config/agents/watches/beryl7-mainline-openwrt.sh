#!/bin/sh
# Bar: openwrt#24656 (Beryl 7 eth0 packet loss) and mt76#1065 (MT7990 Wi-Fi degrades under sustained load) both closed -> revisit moving the Beryl 7 travel router from stock GL firmware to mainline OpenWrt (~/repos/nixos-lab/hosts/travel-router/PLAN.md, Firmware row). Closed is not enough: confirm the fixes shipped in a stable release for glinet_gl-mt3600be, check the Tailscale package is current, and soak 48h. #1065 may never close (a commenter blames MediaTek firmware), so re-decide if it stalls.
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
open=""
for i in openwrt/openwrt/24656 openwrt/mt76/1065; do
  repo=${i%/*} n=${i##*/}
  s=$(gh api "repos/$repo/issues/$n" --jq .state 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
  [ "$s" = "open" ] && open="$open $repo#$n"
done
if [ -n "$open" ]; then echo "NOT-READY: still open:$open"
else echo "CHECK: openwrt#24656 and mt76#1065 closed — confirm the fixes are in a stable release for glinet_gl-mt3600be, then plan the Beryl 7 move to mainline"
fi
