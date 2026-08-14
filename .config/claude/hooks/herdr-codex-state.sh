#!/usr/bin/env bash
# Keep Herdr showing "working" while detached Codex plugin jobs dispatched by
# this Claude session outlive the turn that spawned them.
#
# Herdr keeps Claude Code on screen-manifest authority BY DESIGN (the claude
# integration is session-only; pane.report_agent from any source is suppressed
# for natively-detected agents — verified live, server answers ok but state
# never changes). The one sanctioned external signal is the manifest's top
# rule: an OSC title starting with a braille spinner char => working
# (osc_title_working, priority 1100). So the watcher writes such a title to
# the pane's tty while jobs are alive, and restores Claude's idle glyph (✳,
# osc_title_idle) when they finish. Claude Code rewrites the title itself on
# every state change, so a stale write self-heals within one turn.
#
# Usage: herdr-codex-state.sh stop|clear|codex-wait <sid>  (hook JSON on stdin)
set -u

self=$(readlink -f "${BASH_SOURCE[0]}")

codex_busy() {
  # Same liveness contract as nosleep.sh: record says running AND pid alive,
  # scoped to this session so one pane never reports another's jobs.
  local sid="$1" pid
  for pid in $(jq -r --arg sid "$sid" \
      'select(.sessionId == $sid and .status == "running") | .pid // empty' \
      "$HOME"/.config/claude/plugins/data/codex-openai-codex/state/*/jobs/*.json 2>/dev/null); do
    kill -0 "$pid" 2>/dev/null && return 0
  done
  return 1
}

pane_tty() {
  # Walk our ancestor chain to the claude TUI process; its stdout is the
  # pane's pts. Hooks run with piped fds, so $TTY/tty(1) are useless here.
  local p=$$ t
  while [ "$p" -gt 1 ] 2>/dev/null; do
    t=$(readlink "/proc/$p/fd/1" 2>/dev/null) || t=""
    case "$t" in /dev/pts/*) printf '%s\n' "$t"; return 0 ;; esac
    p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null) || return 1
  done
  return 1
}

set_title() { # $1: title text; writes OSC 0 to the pane tty
  [ -n "${CLAUDE_TTY:-}" ] && [ -w "$CLAUDE_TTY" ] || return 0
  printf '\033]0;%s\007' "$1" > "$CLAUDE_TTY" 2>/dev/null
}

case "${1:-}" in
  stop)
    # Main-agent turn ended; adopt any codex jobs still working for it.
    [ "${HERDR_ENV:-}" = 1 ] || exit 0
    [ -n "${HERDR_PANE_ID:-}" ] || exit 0
    sid=$(jq -r 'select((.agent_id // "") == "") | .session_id // empty' 2>/dev/null)
    [ -n "$sid" ] || exit 0
    codex_busy "$sid" || exit 0
    tty=$(pane_tty) || exit 0
    # Unit name doubles as dedupe: re-spawn while one runs is a silent no-op.
    # RuntimeMaxSec is the crash guard; TERM path still restores via trap.
    systemd-run --user --quiet --collect --unit="claude-herdr-codex-${sid}" \
      --property=RuntimeMaxSec=4h \
      --setenv=CLAUDE_TTY="$tty" \
      bash "$self" codex-wait "$sid" 2>/dev/null
    ;;
  clear)
    # Pane needs its real state visible (approval prompt, session end):
    # stop the watcher; its EXIT trap restores the idle title so herdr's
    # blocked/idle screen rules win again.
    #
    # NOT for the 60s "waiting for your input" idle notification — that fires
    # on every quiet turn end and is exactly the case this hook exists for.
    # Letting it through killed the watcher ~60s in, every time (journal:
    # started 15:29:26, stopped 15:30:27). Only a real blocker clears.
    hook=$(cat 2>/dev/null)
    sid=$(printf '%s' "$hook" | jq -r '.session_id // empty' 2>/dev/null)
    [ -n "$sid" ] || exit 0
    msg=$(printf '%s' "$hook" | jq -r '.message // empty' 2>/dev/null)
    case "$msg" in *"waiting for your input"*) exit 0 ;; esac
    systemctl --user stop "claude-herdr-codex-${sid}" 2>/dev/null
    ;;
  codex-wait)
    sid="${2:-}"
    [ -n "$sid" ] || exit 0
    trap 'set_title "✳ codex jobs finished"' EXIT
    trap 'exit 143' TERM
    # Re-write each loop: Claude overwrites the title whenever it is actually
    # active (spinner animation rewrites constantly), so losing a race to it
    # is both harmless and correct — braille title means working either way.
    while codex_busy "$sid"; do
      set_title "⠋ codex subagent working"
      sleep 20
    done
    ;;
esac
exit 0
