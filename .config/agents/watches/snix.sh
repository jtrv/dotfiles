#!/bin/sh
# Bar: Snix shows signs of becoming a usable Nix replacement -> re-evaluate Snix vs Lix (nixos-config; memory snix-vs-lix-deferred)
# Baselines recorded 2026-10-06 (Gerrit/blog 2026-11-03): no tags, not in nixpkgs,
# no matching merged-change subjects after 2026-10-06, snix.dev blog 2 posts,
# Discourse "Announcing Snix" (61799) 17 posts, NGI Forge thread (79878) 1 post.
# Bump the baselines after acting on a CHECK, or the probe keeps firing.
# git.snix.dev (Forgejo) went login-only by 2026-11; Gerrit at cl.snix.dev is
# the canonical repo and reads anonymously. Forge issues are no longer visible.
command -v jq >/dev/null || { echo "UNKNOWN: jq not installed"; exit 0; }
gerrit=https://cl.snix.dev
since=2026-10-06 blog_base=2
hits="" ; unk=""

# Gerrit prefixes JSON with a )]}' line
tags=$(curl -sf "$gerrit/projects/snix/tags/" | tail -n +2 | jq length); [ -n "$tags" ] || unk="$unk gerrit-tags"
[ -n "$tags" ] && [ "$tags" -gt 0 ] && hits="$hits; first git tag(s) exist ($tags)"

# snixembed is an unrelated tray-icon package
pkgs=$(gh api repos/NixOS/nixpkgs/contents/pkgs/by-name/sn \
  --jq '[.[].name|select(test("^snix($|-)"))]|join(",")' 2>/dev/null) || unk="$unk nixpkgs"
[ -n "$pkgs" ] && hits="$hits; nixpkgs package: $pkgs"

new=$(curl -sf "$gerrit/changes/?q=status:merged+after:$since&n=500") || unk="$unk gerrit-changes"
new=$(printf %s "$new" | tail -n +2 | jq -r '.[]?
  | select(.subject | test("roadmap|drop-?in|nixos-rebuild|toplevel|nix-build|release|stable"; "i"))
  | "CL \(._number) \(.subject)"' | paste -sd'|')
[ -n "$new" ] && hits="$hits; merged changes: $new"

posts=$(curl -sf https://snix.dev/blog/index.xml | grep -c '<item>') || unk="$unk snix-blog"
[ -n "$posts" ] && [ "$posts" -gt "$blog_base" ] && hits="$hits; snix.dev blog has $posts posts (was $blog_base)"

for pair in 61799:17 79878:1; do
  id=${pair%:*} base=${pair#*:}
  n=$(curl -sf "https://discourse.nixos.org/t/$id.json" | jq .posts_count); [ -n "$n" ] || { unk="$unk discourse"; continue; }
  [ "$n" -gt "$base" ] && hits="$hits; discourse t/$id has $n posts (was $base)"
done
topics=$(curl -sf "https://discourse.nixos.org/search.json?q=snix%20in%3Atitle") || unk="$unk discourse-search"
topics=$(printf %s "$topics" | jq -r '[.topics[]? | select(.id != 61799 and .id != 79878) | "t/\(.id) \(.title)"] | join("|")')
[ -n "$topics" ] && hits="$hits; new discourse topics: $topics"

if [ -n "$hits" ]; then echo "CHECK:${hits#;}"
elif [ -n "$unk" ]; then echo "UNKNOWN: unreachable:$unk"
else echo "NOT-READY: no tag, no nixpkgs package, no release/replacement change, blog and Discourse quiet"
fi
