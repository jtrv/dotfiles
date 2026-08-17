#!/usr/bin/env bash
# Hold a block sleep inhibitor while Claude or a detached codex job is working.
# logind (≥257) refuses `systemctl suspend` while any block inhibitor is held,
# even the caller's own — the inhibitor itself is the safety boundary.
#
# Usage: nosleep.sh acquire|release|maybe-suspend   (hook JSON on stdin, for session_id)
set -u

self=$(readlink -f "${BASH_SOURCE[0]}")
sid=$(jq -r '.session_id // empty' 2>/dev/null)
unit="claude-nosleep-${sid:-unknown}"
# Shared machine-wide: whichever session releases last owns the deferred check.
timer="claude-nosleep-idlecheck"
codexunit="claude-nosleep-codex"

codex_busy() {
  # Busy = record says running AND pid alive; stale files must not pin the box.
  local pid
  for pid in $(jq -r 'select(.status == "running") | .pid // empty' \
      "$HOME"/.config/claude/plugins/data/codex-openai-codex/state/*/jobs/*.json 2>/dev/null); do
    kill -0 "$pid" 2>/dev/null && return 0
  done
  return 1
}

watch_codex() {
  # Hold the inhibitor for the codex jobs' lifetime, not the session's.
  systemd-run --user --quiet --collect --unit="$codexunit" \
    --property=RuntimeMaxSec=4h \
    systemd-inhibit --what=sleep --who=lock-no-sleep \
      --why="Codex job running" \
      bash "$self" codex-wait 2>/dev/null
}

case "${1:-}" in
  acquire)
    systemctl --user stop "$timer.timer" 2>/dev/null
    # RuntimeMaxSec: crash guard. --what=sleep, not idle:sleep — an idle
    # inhibitor makes swayidle 1.9 pause its whole timeout chain, so the
    # screen would never lock during long runs.
    systemd-run --user --quiet --collect --unit="$unit" \
      --property=RuntimeMaxSec=4h \
      systemd-inhibit --what=sleep --who=lock-no-sleep \
        --why="Claude Code working" \
        sleep infinity 2>/dev/null
    ;;
  release)
    # Watcher starts before our inhibitor drops: no uninhibited window between.
    codex_busy && watch_codex
    systemctl --user stop "$unit" 2>/dev/null
    # swayidle is edge-triggered: a suspend it skipped is never retried, so
    # re-check ourselves. 90s gives a rewake turn time to cancel via acquire.
    systemd-run --user --quiet --collect --on-active=90 --unit="$timer" \
      bash "$self" maybe-suspend 2>/dev/null
    ;;
  maybe-suspend)
    # Locker running = swayidle's idle rule fired and nobody unlocked since.
    pgrep -x baijia-suo >/dev/null || exit 0
    # Codex job that appeared after release checked: adopt, don't suspend under it.
    if codex_busy; then watch_codex; exit 0; fi
    # logind vetoes this if any other block inhibitor survives.
    systemctl suspend
    ;;
  codex-wait)
    # Runs under systemd-inhibit in $codexunit; exiting drops the inhibitor.
    # Trap so the deferred check re-arms even if systemd kills us (RuntimeMaxSec).
    trap 'systemd-run --user --quiet --collect --on-active=90 --unit="$timer" \
      bash "$self" maybe-suspend 2>/dev/null' EXIT
    trap 'exit 143' TERM
    while codex_busy; do sleep 30; done
    ;;
esac
exit 0
