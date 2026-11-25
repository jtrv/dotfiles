#!/bin/sh
# Bar: google/gvisor#12575 fixed (PR #14578, runsc resolves its exe path before entering the mount ns) -> move nixos-config back to virtualisation.docker.rootless with runsc as default-runtime, drop docker.fish's sudo (nixos/common/default.nix, docs/plan.md)
# Baseline 2026-11-24: issue open, PR #14578 open; rootless fails with "fork/exec /proc/self/exe: no such file or directory" unless --TESTONLY-unsafe-nonroot.
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
pr=$(gh api repos/google/gvisor/pulls/14578 --jq '.state + " " + (.merged_at // "")' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
issue=$(gh api repos/google/gvisor/issues/12575 --jq '.state' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
case "$pr" in
  "closed "?*) echo "CHECK: gvisor#14578 merged $(echo "${pr#closed }" | cut -c1-10) - once the overlay's gvisor rev includes it, test rootless docker + runsc" ;;
  "closed ") echo "CHECK: gvisor#14578 closed unmerged (issue #12575 $issue) - look for a successor fix" ;;
  *) if [ "$issue" = closed ]; then echo "CHECK: gvisor#12575 closed while #14578 open - see what fixed it"; else echo "NOT-READY: gvisor#12575 and PR #14578 still open"; fi ;;
esac
