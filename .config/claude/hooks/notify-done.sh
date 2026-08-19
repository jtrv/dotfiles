#!/usr/bin/env bash
# Stop / Notification hook: tell me when Claude is done and the ball is in my court.
#
# Deliberately NOT wired to SubagentStop — a subagent finishing is a minor task,
# not "your turn". Only end-of-turn and permission prompts fire this.
# Silent when the session's own niri window is already focused: if you're watching
# it happen, a popup is noise.
set -euo pipefail

command -v notify-send >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
event="$(jq -r '.hook_event_name // "Stop"' <<<"$payload")"
msg="$(jq -r '.message // empty' <<<"$payload")"

# Claude Code's idle Notification ("waiting for your input") lands ~60s after the
# Stop we already notified on. Only the permission ones say anything new.
case "$event" in
  Notification) [[ "$msg" == *[Pp]ermission* ]] || exit 0 ;;
esac

session_id="$(jq -r '.session_id // empty' <<<"$payload")"
window_id=""
if [ -n "$session_id" ] && [ -f "$HOME/.config/claude/session-env/$session_id/window_id" ]; then
  window_id="$(cat "$HOME/.config/claude/session-env/$session_id/window_id")"
fi

if [ -n "$window_id" ] && command -v niri >/dev/null 2>&1; then
  focused="$(niri msg -j windows 2>/dev/null | jq -r '.[] | select(.is_focused==true) | .id' | head -n1)"
  [ "$focused" = "$window_id" ] && exit 0
fi

where="$(basename "$(jq -r '.cwd // empty' <<<"$payload")")"
if [ "$event" = "Notification" ]; then
  title="Claude needs permission${where:+ — $where}"
  body="$msg"
else
  title="Claude finished${where:+ — $where}"
  body="$(jq -r '.last_assistant_message // empty' <<<"$payload" | tr '\n' ' ' | cut -c1-200)"
  body="${body:-Waiting for your input.}"
fi

setsid bash -c '
  action="$(notify-send -u critical -A default=Open "$1" "$2" 2>/dev/null || true)"
  if [ "$action" = "default" ] && [ -n "$3" ] && command -v niri >/dev/null 2>&1; then
    if niri msg -j windows 2>/dev/null | jq -e --arg id "$3" ".[] | select((.id|tostring)==\$id)" >/dev/null; then
      niri msg action focus-window --id "$3" >/dev/null 2>&1
    fi
  fi
' _ "$title" "$body" "$window_id" </dev/null >/dev/null 2>&1 &
disown
