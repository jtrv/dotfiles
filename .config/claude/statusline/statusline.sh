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
# catppuccin mocha yellow #f9e2af / red #f38ba8 — the same two the toml names as `yellow`
# and `red`, so one alarm colour means one thing no matter which number is wearing it
sev() { # $1 percent, $2 warn at, $3 high at — nothing at all while unremarkable
    if [ "$1" -ge "${3:-90}" ]; then printf '\033[1;38;2;243;139;168m'
    elif [ "$1" -ge "${2:-75}" ]; then printf '\033[1;38;2;249;226;175m'; fi
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
        | map(select(. != null and .resets_at > now)) | sort_by(.window_minutes) | reverse
        # windows are labelled the way Claude labels its own: the vendor mark the toml
        # prepends stands for the weekly one, and the 5h one wears the same clock glyph as
        # the Claude 5h chip. Weekly first, so both providers read 7d-then-5h.
        | .[] | "\(.used_percent | round)\t\(if .window_minutes < 1440 then "󰥔" else "" end)"')
    [ -n "$codex" ] && export CC_CODEX="$(sev "$codex_max")$codex"
fi

# the context window fills faster than any other number here, so it gets its own, earlier
# ladder, the same colours as the cache chip: green, amber from 30%, pink from 45%, red past 60%
pct=$(jq -r '.context_window.used_percentage | numbers | round' <<< "$input")
if [ -n "$pct" ]; then
    if [ "$pct" -gt 60 ]; then ctx='\033[1;38;2;243;139;168m'
    elif [ "$pct" -ge 45 ]; then ctx='\033[1;38;2;245;194;231m'
    elif [ "$pct" -ge 30 ]; then ctx='\033[1;38;2;249;226;175m'
    else ctx=''; fi
    # the glyph rides inside the value, after the colour, so the icon repaints with the digits
    export CC_CTX="$(printf "$ctx")󰕯 ${pct}%"
fi

# Prompt-cache time left. No API reports cache liveness, so this is the timestamp of the
# last response in the transcript plus the TTL — the newest server-confirmed point the
# cache was written or read. 3600 is the subscription's 1h TTL; an API-key session caches
# for 5m and this chip would overstate it. Its own ladder, off the shared one: green while
# warm, amber in the last 30 minutes, pink in the last 15, red once cold, when the next
# send re-writes the whole context.
transcript=$(jq -r '.transcript_path // empty' <<< "$input")
if [ -f "$transcript" ]; then
    last=$(tac "$transcript" | grep -m1 '"usage":{' | jq -r '.timestamp // empty | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601')
    if [ -n "$last" ]; then
        age=$(( $(date +%s) - last ))
        if [ "$age" -ge 3600 ]; then color='\033[1;38;2;243;139;168m'
        elif [ "$age" -ge 2700 ]; then color='\033[1;38;2;245;194;231m'
        elif [ "$age" -ge 1800 ]; then color='\033[1;38;2;249;226;175m'
        else color=''; fi
        [ "$age" -lt 3600 ] && cache="$(( 60 - age / 60 ))m" || cache="cold"
        export CC_CACHE="$(printf "$color")󰔟 $cache"
    fi
fi

# cholo has no levels: it is on whenever its hook would inject it, so mirror the hook's test.
[ "${CHOLO_OFF:-}" != 1 ] && [ -f "$HOME/.config/agents/skills/cholo/SKILL.md" ] && export CC_CHOLO=cholo

STARSHIP_CONFIG="$HOME/.config/claude/statusline/starship.toml" starship prompt
