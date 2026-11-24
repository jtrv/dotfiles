#!/bin/sh
# Bar: lix#382 (parallel evaluation) closed -> re-benchmark eval speed vs Determinate Nix before considering a switch (nixos-config)
s=$(curl -sf https://git.lix.systems/api/v1/repos/lix-project/lix/issues/382 | grep -o '"state": *"[^"]*"' | head -1 | cut -d'"' -f4)
case "$s" in
  "") echo "UNKNOWN: git.lix.systems API unreachable" ;;
  open) echo "NOT-READY: lix#382 parallel evaluation still open — perf gap vs Determinate stands" ;;
  closed) echo "CHECK: lix#382 closed — see if parallel eval shipped in a Lix release, re-evaluate Determinate comparison" ;;
  *) echo "UNKNOWN: unexpected state '$s' for lix#382" ;;
esac
