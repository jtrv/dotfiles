#!/usr/bin/env bash
# ponytail: only reads the fields the toml actually renders, not the full stdin schema
input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<< "$input")
[ -n "$dir" ] && cd "$dir" 2>/dev/null

export CC_MODEL=$(jq -r '.model.display_name // empty' <<< "$input")

added=$(jq -r '.cost.total_lines_added // 0' <<< "$input")
removed=$(jq -r '.cost.total_lines_removed // 0' <<< "$input")
[ "$added" = 0 ] && [ "$removed" = 0 ] || export CC_LINES="+${added}/-${removed}"

# Every usage number shares one severity ladder. A reading renders in its provider's own
# colour while it is unremarkable and repaints amber/red past the thresholds, so a warm
# colour anywhere in this bar always means "look at this" and never just "this is Claude".
# The repaint happens in place: each number keeps its column, and the bar's left-to-right
# order (7d, then codex, then 5h) is fixed rather than a function of who is alarming.
# ponytail: the override rides inside the env value — starship passes the escape through
# untouched, which beats a matched pair of amber/red modules per column in the toml.
# amber #FBBF24 / red #F87171 — the same two the context ladder uses in the toml, so one
# alarm colour means one thing no matter which number is wearing it
sev() { # $1 percent, $2 warn at, $3 high at — nothing at all while unremarkable
    if [ "$1" -ge "${3:-90}" ]; then printf '\033[1;38;2;248;113;113m'
    elif [ "$1" -ge "${2:-75}" ]; then printf '\033[1;38;2;251;191;36m'; fi
}

rate5h=$(jq -r '.rate_limits.five_hour.used_percentage | numbers | round' <<< "$input")
[ -n "$rate5h" ] && export CC_RATE_5H="$(sev "$rate5h")${rate5h}%"

rate7d=$(jq -r '.rate_limits.seven_day.used_percentage | numbers | round' <<< "$input")
[ -n "$rate7d" ] && export CC_RATE_7D="$(sev "$rate7d")${rate7d}%"

# Codex has no usage API: the live window percentages ride along on every token_count
# event in the newest session rollout, so read the last one. tac|grep -m1 short-circuits,
# so this reads from the end of the file, not all of it. Requires the absolute `resets_at`
# field — a record whose window already reset is stale and renders nothing.
codex_rollout=$(ls -t "${CODEX_HOME:-$HOME/.codex}"/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -1)
if [ -f "$codex_rollout" ]; then
    codex="" codex_max=0
    # percentage first: `read` swallows a leading empty field, since tab counts as whitespace.
    # Both windows share one colour, keyed to the worse of the two — colouring them
    # separately would need a reset between them, and the reset has no way to name the
    # module's own teal to return to.
    while IFS=$'\t' read -r pct label; do
        codex="${codex}${codex:+ }${label:+$label }${pct}%"
        [ "$pct" -gt "$codex_max" ] && codex_max=$pct
    done < <(tac "$codex_rollout" | grep -m1 '"rate_limits":{' | jq -r '
        (.payload.rate_limits // .rate_limits) as $rl | [$rl.primary, $rl.secondary]
        | map(select(. != null and .resets_at > now))
        # a bare percentage is unambiguous while one window is live, which is the norm;
        # the plan reporting two again is what earns them their labels back
        | (length > 1) as $multi
        | .[] | "\(.used_percent | round)\t\(if $multi then (if .window_minutes < 1440 then "5h" else "7d" end) else "" end)"')
    [ -n "$codex" ] && export CC_CODEX="$(sev "$codex_max")$codex"
fi

# the context window fills faster than any other number here, so it alarms earlier than the
# 75/90 the rate limits use — 80% is already the point of no return for a long task
pct=$(jq -r '.context_window.used_percentage | numbers | round' <<< "$input")
[ -n "$pct" ] && export CC_CTX="$(sev "$pct" 50 80)${pct}%"

# mode flags: first line of the file is the level, missing file = mode off. The level is
# always spelled out — hiding it at "full" left the module as a lone icon that said only
# "on", when which rung is enforced is the part worth reading. ponytail's flag is
# plugin-managed; caveman's is written by hooks/caveman-track.sh, since caveman is a user
# skill with no hook of its own.
read_mode_flag() {
    local flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/$1"
    [ -f "$flag" ] || return
    local mode
    mode=$(head -n1 "$flag" | tr -d '[:space:]')
    echo "${mode:-full}"
}

mode=$(read_mode_flag .ponytail-active) && [ -n "$mode" ] && export CC_PONYTAIL="$mode"
mode=$(read_mode_flag .caveman-active) && [ -n "$mode" ] && export CC_CAVEMAN="$mode"

STARSHIP_CONFIG="$HOME/.config/claude/statusline/starship.toml" starship prompt
