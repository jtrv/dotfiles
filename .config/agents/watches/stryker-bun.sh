#!/bin/sh
# Bar: official Stryker bun runner exists -> mutation lane runs native under bun (contexts/typescript.md §2)
code=$(curl -s -o /dev/null -w '%{http_code}' https://registry.npmjs.org/@stryker-mutator%2fbun-runner)
case "$code" in
  200) echo "CHECK: @stryker-mutator/bun-runner exists on npm — evaluate for the mutation lane" ;;
  404) echo "NOT-READY: no official Stryker bun runner on npm" ;;
  *) echo "UNKNOWN: npm registry returned $code" ;;
esac
