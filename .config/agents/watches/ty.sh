#!/bin/sh
# Bar: ty >=1.0 + ~95% typing conformance + strict mode -> reconsider vs basedpyright (contexts/python.md)
v=$(uvx ty --version 2>/dev/null | grep -o '[0-9][0-9.a-z]*' | head -1)
[ -z "$v" ] && { echo "UNKNOWN: ty not runnable via uvx"; exit 0; }
case "$v" in
  0.*) echo "NOT-READY: ty $v (bar: >=1.0, ~95% conformance, strict mode)" ;;
  *) echo "CHECK: ty $v reached 1.0 — verify ~95% conformance + strict mode before swapping basedpyright" ;;
esac
