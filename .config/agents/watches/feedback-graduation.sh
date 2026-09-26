#!/bin/sh
# Bar: feedback memories newer than the last review -> fold each into the context/skill it belongs to, or ack.
# Warp's improver loop, read-only half (research/2026-09-18-warp-self-improving-agents-check.md).
# `feedback-graduation.sh ack` marks everything current as reviewed.
marker="${XDG_STATE_HOME:-$HOME/.local/state}/agents/feedback-reviewed"
mem="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}/projects"
[ "$1" = ack ] && { mkdir -p "$(dirname "$marker")" && touch "$marker" && echo "acked $(date +%F)"; exit 0; }
[ -d "$mem" ] || { echo "UNKNOWN: no memory dirs under $mem"; exit 0; }
if [ -f "$marker" ]; then since=$(date -r "$marker" +%F); newer="-newer $marker"; else since=never; newer=; fi
# shellcheck disable=SC2086
list=$(find "$mem" -path '*/memory/*.md' ! -name MEMORY.md $newer -exec grep -l '^  type: feedback' {} + 2>/dev/null | xargs -r ls -t)
n=$(printf '%s\n' "$list" | grep -c .)
[ "$n" -eq 0 ] && { echo "NOT-READY: no feedback memories since $since"; exit 0; }
echo "CHECK: $n feedback memories since $since — fold into a context/skill or run '$0 ack'"
printf '%s\n' "$list" | while read -r f; do
  target=$(grep -oE '(contexts/[a-z-]+\.md|skills/[a-z-]+|AGENTS\.md|CLAUDE\.md)' "$f" | sort -u | tr '\n' ' ')
  printf '  %s  %s  ->%s\n' "$(date -r "$f" +%F)" "${f#"$mem"/}" " ${target:-(no target named)}"
done
