#!/usr/bin/env bash
# SessionStart hook: remember which niri window this Claude Code session is running in,
# so a later SubagentStop notification can focus back to it.
set -euo pipefail

command -v niri >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"
[ -n "$session_id" ] || exit 0

window_id="$(niri msg -j windows 2>/dev/null | jq -r '.[] | select(.is_focused==true) | .id' | head -n1)"
[ -n "$window_id" ] || exit 0

session_dir="$HOME/.config/claude/session-env/$session_id"
mkdir -p "$session_dir"
echo "$window_id" > "$session_dir/window_id"
