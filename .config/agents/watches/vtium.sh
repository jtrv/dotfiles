#!/bin/sh
# Bar: vtium leaves alpha or lands in nixpkgs -> weigh it against kmscon for ly on thiccpad (memory vtium-vs-kmscon-deferred)
# Baseline 2026-11-04: v0.1.0-alpha.5, repo 9 days old, 4 stars, LLM-written, runs as root, not in nixpkgs.
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
t=$(gh api repos/vtium/vtium/releases --jq '.[0].tag_name // empty' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
[ -n "$t" ] || { echo "UNKNOWN: vtium has no releases listed"; exit 0; }
hits=""
case "$t" in
  *alpha*) ;;
  *) hits="latest release is $t" ;;
esac
if gh api repos/NixOS/nixpkgs/contents/pkgs/by-name/vt/vtium >/dev/null 2>&1; then
  hits="${hits:+$hits; }in nixpkgs"
fi
if [ -n "$hits" ]; then echo "CHECK: vtium $hits - read its security notes, compare with kmscon for ly"
else echo "NOT-READY: vtium $t is still alpha and not in nixpkgs"
fi
