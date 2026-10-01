#!/bin/sh
# Bar: stock tinycc and handlr-regex at nixos-config's locked nixpkgs are on cache.nixos.org (Hydra built them, so their tests pass again) -> delete their test-skip overrides in nixos/pkgs/default.nix
cfg=$HOME/repos/nixos-config
rev=$(jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked.rev' "$cfg/flake.lock" 2>/dev/null)
[ -n "$rev" ] && [ "$rev" != null ] || { echo "UNKNOWN: no nixpkgs rev in $cfg/flake.lock"; exit; }
fixed= broken=
for p in tinycc handlr-regex; do
  out=$(nix eval --raw "github:NixOS/nixpkgs/$rev#$p.outPath" 2>/dev/null) || { echo "UNKNOWN: cannot evaluate $p at $rev"; exit; }
  if nix path-info --store https://cache.nixos.org "$out" >/dev/null 2>&1; then fixed="$fixed $p"; else broken="$broken $p"; fi
done
if [ -n "$fixed" ]; then echo "CHECK: cached at ${rev%"${rev#???????}"}:$fixed — drop those overrides"
else echo "NOT-READY: still uncached at ${rev%"${rev#???????}"}:$broken (Hydra may also just be behind)"; fi
