#!/bin/sh
# Bar: typescript >=7.1 -> drop the TS6 side-by-side exception for Vue/Svelte/Astro/Angular (contexts/typescript.md §1)
v=$(curl -sf https://registry.npmjs.org/typescript/latest | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$v" ] && { echo "UNKNOWN: npm registry unreachable"; exit 0; }
major=${v%%.*}; rest=${v#*.}; minor=${rest%%.*}
if [ "$major" -gt 7 ] 2>/dev/null || { [ "$major" -eq 7 ] && [ "$minor" -ge 1 ]; } 2>/dev/null; then
  echo "CHECK: typescript $v >= 7.1 — verify framework tooling migrated, then drop the TS6 side-by-side exception"
else
  echo "NOT-READY: typescript $v < 7.1 — TS6 side-by-side exception stands"
fi
