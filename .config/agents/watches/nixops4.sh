#!/bin/sh
# Bar: nixops4 cuts its first tag -> weigh it against deploy-rs for remote deploy (nixos-config docs/plan.md, morpheus section)
n=$(curl -sf https://api.github.com/repos/nixops4/nixops4/tags | grep -c '"name"')
case "$n" in
  "") echo "UNKNOWN: GitHub API unreachable" ;;
  0) echo "NOT-READY: nixops4 has no tags - still pre-release" ;;
  *) echo "CHECK: nixops4 has $n tag(s) - read the release notes, compare with deploy-rs for morpheus" ;;
esac
