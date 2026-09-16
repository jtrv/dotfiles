#!/bin/sh
# postinstall: the typebox devDependency exists only so `bun test` and the LSP
# resolve what pi aliases to its bundled copy at runtime. Fail the install when
# the pin drifts from that copy so the tests keep exercising the runtime API.
pi=$(command -v pi) || exit 0
dir=$(dirname "$(readlink -f "$pi")")
version() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$1" | head -1; }
# nix: <store>/bin/pi, typebox 6 deep under <store>. bun global: <global>/node_modules/@x/pi/dist/cli.js,
# typebox hoisted to <global>/node_modules. Four levels up covers both without reaching /nix/store.
for _ in 1 2 3 4; do
  bundled=$(find "$dir" -maxdepth 7 -path '*/node_modules/typebox/package.json' 2>/dev/null | head -1)
  [ -n "$bundled" ] && break
  dir=$(dirname "$dir")
done
[ -n "$bundled" ] || { echo "check-typebox: pi found but no bundled typebox near it" >&2; exit 0; }
want=$(version "$bundled"); have=$(version node_modules/typebox/package.json)
[ "$want" = "$have" ] && exit 0
echo "check-typebox: pi bundles typebox $want, package.json pins $have — run: bun add -d typebox@$want" >&2
exit 1
