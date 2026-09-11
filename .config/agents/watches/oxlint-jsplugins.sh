#!/bin/sh
# Bar: oxlint JS plugins leave alpha -> enforce networkidle ban via eslint-plugin-playwright in lint, not review (contexts/typescript.md §3)
page=$(reader https://oxc.rs/docs/guide/usage/linter/js-plugins 2>/dev/null)
case "$page" in
  "") echo "UNKNOWN: oxc.rs docs unreachable" ;;
  *[Aa]lpha*) echo "NOT-READY: oxlint JS plugins still alpha" ;;
  *) echo "CHECK: alpha label gone from JS plugins docs — try eslint-plugin-playwright no-networkidle in the gate" ;;
esac
