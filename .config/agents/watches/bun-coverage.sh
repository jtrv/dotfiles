#!/bin/sh
# Bar: bun#32118 (lcov kills threshold exit) + #7100/#5307 (no branch/statement coverage) closed -> revisit coverage gating (contexts/typescript.md §1)
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
open=""
for i in 32118 7100 5307; do
  s=$(gh api "repos/oven-sh/bun/issues/$i" --jq .state 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
  [ "$s" = "open" ] && open="$open #$i"
done
if [ -n "$open" ]; then echo "NOT-READY: bun coverage issues still open:$open"
else echo "CHECK: bun#32118/#7100/#5307 all closed — retest lcov-in-gate and branch thresholds, then update the doc"
fi
