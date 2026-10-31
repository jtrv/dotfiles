#!/bin/sh
# Bar: nixops4 cuts its first tag (none as of 2026-10-28) -> weigh it against deploy-rs (nixos-config docs/plan.md, "remote deploy" item)
command -v gh >/dev/null || { echo "UNKNOWN: gh not installed"; exit 0; }
t=$(gh api repos/nixops4/nixops4/tags --jq '.[0].name // empty' 2>/dev/null) || { echo "UNKNOWN: gh api failed (auth/network)"; exit 0; }
if [ -z "$t" ]; then echo "NOT-READY: nixops4 has no tags - still pre-release"
else echo "CHECK: nixops4 tagged $t - read the release notes, compare with deploy-rs for morpheus"
fi
