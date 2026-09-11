#!/bin/sh
# Bar: oxfmt 1.0 -> relax the exact-version pin (contexts/typescript.md §1)
v=$(curl -sf https://registry.npmjs.org/oxfmt/latest | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$v" ] && { echo "UNKNOWN: npm registry unreachable"; exit 0; }
case "$v" in
  0.*) echo "NOT-READY: oxfmt $v still pre-1.0 — keep the exact pin" ;;
  *) echo "CHECK: oxfmt $v reached 1.0 — consider relaxing the exact pin" ;;
esac
