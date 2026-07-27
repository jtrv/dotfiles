#!/usr/bin/env bash
# Hold a `lock-no-sleep` inhibitor while Claude is working.
# swayidle's timeout greps `systemd-inhibit --list --who=lock-no-sleep` before
# calling `systemctl suspend`, so that --who value is the contract. Don't rename it.
#
# Usage: nosleep.sh acquire|release   (hook JSON on stdin, for session_id)
set -u

sid=$(jq -r '.session_id // empty' 2>/dev/null)
unit="claude-nosleep-${sid:-unknown}"

case "${1:-}" in
  acquire)
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
    ;;
esac
exit 0
