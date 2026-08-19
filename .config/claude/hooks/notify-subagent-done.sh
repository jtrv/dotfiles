#!/usr/bin/env bash
# SubagentStop hook: persistent desktop notification when a subagent finishes.
# Clicking it refocuses the niri window this Claude Code session is running in.
set -euo pipefail

command -v notify-send >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$payload")"
agent_type="$(jq -r '.agent_type // "subagent"' <<<"$payload")"
summary="$(jq -r '.last_assistant_message // ""' <<<"$payload" | tr '\n' ' ' | cut -c1-200)"
[ -n "$summary" ] || summary="(no summary available)"

window_id=""
if [ -n "$session_id" ] && [ -f "$HOME/.config/claude/session-env/$session_id/window_id" ]; then
  window_id="$(cat "$HOME/.config/claude/session-env/$session_id/window_id")"
fi

setsid bash -c '
  action="$(notify-send -u critical -A default=Open "$1 finished" "$2" 2>/dev/null || true)"
  if [ "$action" = "default" ] && [ -n "$3" ] && command -v niri >/dev/null 2>&1; then
    if niri msg -j windows 2>/dev/null | jq -e --arg id "$3" ".[] | select((.id|tostring)==\$id)" >/dev/null; then
      niri msg action focus-window --id "$3" >/dev/null 2>&1
    fi
  fi
' _ "$agent_type" "$summary" "$window_id" </dev/null >/dev/null 2>&1 &
disown
