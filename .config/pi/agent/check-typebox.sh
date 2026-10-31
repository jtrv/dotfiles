#!/bin/sh
# postinstall: the typebox devDependency exists only so `bun test` and the LSP
# resolve what pi aliases to its bundled copy at runtime. Fail the install when
# the pin drifts from that copy so the tests keep exercising the runtime API.
pi=$(command -v pi) || exit 0
entry=$(readlink -f "$pi")
# bun's bin symlink resolves straight to pi's cli.js; nix installs a shell
# wrapper in bin/ that execs the store's cli.js, so take that path from it.
case $entry in
  *.js) ;;
  *) entry=$(grep -o '/nix/store/[^ "'"'"']*\.js' "$entry" | head -1) ;;
esac
# node's resolution from pi's own directory: nested node_modules on nix, the
# hoisted global one under bun.
bundled=$(bun -e 'console.log(require.resolve("typebox/package.json",{paths:[process.argv[1]]}))' "${entry%/*}" 2>/dev/null) ||
  { echo "check-typebox: pi is $pi but its typebox cannot be resolved from $entry" >&2; exit 0; }
version() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$1" | head -1; }
want=$(version "$bundled"); have=$(version node_modules/typebox/package.json)
[ "$want" = "$have" ] && exit 0
echo "check-typebox: pi bundles typebox $want, package.json pins $have — run: bun add -d typebox@$want" >&2
exit 1
