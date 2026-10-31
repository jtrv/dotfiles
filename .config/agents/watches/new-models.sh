#!/usr/bin/env bash
# Bar: a model reachable from agy or Codex that no routing review has looked at
# -> place it per contexts/harnesses.md "Changing a routing table", then `ack`.
# Gemini 4 Argon sat in `agy models` for three weeks unnoticed (2026-10-23).
set -uo pipefail
known="$(dirname "$0")/new-models.known"
touch "$known"

ids=$(
  { command -v agy >/dev/null && timeout 30 agy models 2>/dev/null | cut -f1 | sed -E 's/-(low|medium|high)$//'
    jq -r '.models[]?.slug' "${CODEX_HOME:-$HOME/.cache/codex}/models_cache.json" 2>/dev/null
  } | grep -E '^[a-z0-9.-]+$' | sort -u
)
[ -z "$ids" ] && { echo "UNKNOWN: neither agy models nor the Codex model cache returned ids"; exit 0; }

if [ "${1:-}" = ack ]; then
  printf '%s\n' "$ids" | sort -u - "$known" -o "$known"
  echo "acked $(wc -l <"$known") model ids"
  exit 0
fi

new=$(printf '%s\n' "$ids" | grep -vxF -f "$known")
if [ -n "$new" ]; then
  echo "CHECK: unreviewed models — $(echo "$new" | tr '\n' ' ')"
else
  echo "NOT-READY: no models beyond the last routing review"
fi
