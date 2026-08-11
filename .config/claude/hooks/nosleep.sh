#!/usr/bin/env bash
# Hold a `lock-no-sleep` inhibitor while Claude is working.
# swayidle's timeout greps `systemd-inhibit --list --who=lock-no-sleep` before
# calling `systemctl suspend`, so that --who value is the contract. Don't rename it.
#
# Usage: nosleep.sh acquire|release|maybe-suspend   (hook JSON on stdin, for session_id)
set -u

self=$(readlink -f "${BASH_SOURCE[0]}")
sid=$(jq -r '.session_id // empty' 2>/dev/null)
unit="claude-nosleep-${sid:-unknown}"
# One shared timer for the whole machine, not per session: whichever session
# releases last is the one whose deferred check should survive.
timer="claude-nosleep-idlecheck"

case "${1:-}" in
  acquire)
    # Work started again -> cancel any pending suspend check.
    systemctl --user stop "$timer.timer" 2>/dev/null
    # ponytail: RuntimeMaxSec is the crash guard — if Claude dies without a Stop
    # hook, the lock expires on its own instead of pinning the box awake forever.
    systemd-run --user --quiet --collect --unit="$unit" \
      --property=RuntimeMaxSec=4h \
      systemd-inhibit --what=idle:sleep --who=lock-no-sleep \
        --why="Claude Code working" \
        sleep infinity 2>/dev/null
    ;;
  release)
    systemctl --user stop "$unit" 2>/dev/null
    # swayidle timeouts are edge-triggered: if its 300s rule already fired and
    # skipped `systemctl suspend` because of our inhibitor, nothing re-evaluates
    # that decision once we let go. So re-check ourselves, 90s later — long
    # enough that a rewake/subagent turn cancels it via `acquire` first.
    # Re-arming while a check is already pending is a harmless no-op.
    systemd-run --user --quiet --collect --on-active=90 --unit="$timer" \
      bash "$self" maybe-suspend 2>/dev/null
    ;;
  maybe-suspend)
    # Idle here means "swayidle's idle rule fired and hasn't been undone": the
    # screen is locked and nobody has typed a password since. Checked at fire
    # time, not at release time, so coming back within the grace period is safe.
    pgrep -x baijia-suo >/dev/null || exit 0
    # Any surviving holder vetoes: another Claude session still working, or a
    # manual `lock-no-sleep` deliberately keeping the box up while locked.
    systemd-inhibit --list --who=lock-no-sleep --no-legend | grep -q . && exit 0
    systemctl suspend
    ;;
esac
exit 0
