#!/bin/sh
# Bar: mt76#1065 (MT7990 Wi-Fi degrades after 12-24h of sustained load) closed -> revisit moving the Beryl 7 travel router from stock GL firmware to mainline OpenWrt (~/repos/nixos-lab/hosts/travel-router/PLAN.md, Firmware row). A closed issue is not enough on its own: confirm the fix shipped in a stable OpenWrt release for glinet_gl-mt3600be.
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
s=$(gh api repos/openwrt/mt76/issues/1065 --jq .state 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
if [ "$s" = "open" ]; then echo "NOT-READY: mt76#1065 still open"
else echo "CHECK: mt76#1065 closed — confirm the fix is in a stable OpenWrt release for glinet_gl-mt3600be, then plan the Beryl 7 move to mainline"
fi
