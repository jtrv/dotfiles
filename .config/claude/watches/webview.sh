#!/bin/sh
# Bar: Bun.WebView leaves experimental AND gains clock/animation control -> migrate capture rig (contexts/typescript.md §3)
v=$(bun --version 2>/dev/null || echo none)
page=$(reader https://bun.com/docs/runtime/webview 2>/dev/null)
case "$page" in
  "") echo "UNKNOWN (bun $v): docs page unreachable" ;;
  *[Ee]xperimental*) echo "NOT-READY (bun $v): Bun.WebView still marked experimental" ;;
  *) echo "CHECK (bun $v): experimental label gone — manually verify clock pinning + animation disable before migrating the rig" ;;
esac
