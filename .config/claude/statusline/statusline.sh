#!/usr/bin/env bash
# ponytail: only reads the fields the toml actually renders, not the full stdin schema
input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<< "$input")
[ -n "$dir" ] && cd "$dir" 2>/dev/null

export CC_MODEL=$(jq -r '.model.display_name // empty' <<< "$input")

added=$(jq -r '.cost.total_lines_added // 0' <<< "$input")
removed=$(jq -r '.cost.total_lines_removed // 0' <<< "$input")
[ "$added" = 0 ] && [ "$removed" = 0 ] || export CC_LINES="+${added}/-${removed}"

rate5h=$(jq -r '.rate_limits.five_hour.used_percentage | numbers | round' <<< "$input")
[ -n "$rate5h" ] && export CC_RATE_5H="${rate5h}%"

rate7d=$(jq -r '.rate_limits.seven_day.used_percentage | numbers | round' <<< "$input")
[ -n "$rate7d" ] && export CC_RATE_7D="${rate7d}%"

pct=$(jq -r '.context_window.used_percentage | numbers | round' <<< "$input")
if [ -n "$pct" ]; then
    if [ "$pct" -lt 50 ]; then
        export CC_CTX_OK="${pct}%"
    elif [ "$pct" -lt 80 ]; then
        export CC_CTX_WARN="${pct}%"
    else
        export CC_CTX_HIGH="${pct}%"
    fi
fi

# mode flags: first line of the file is the level, missing file = mode off, missing/"full"
# line = default (icon only, no word). ponytail's flag is plugin-managed; caveman's is
# written by hooks/caveman-track.sh since caveman is a user skill with no hook of its own.
read_mode_flag() {
    local flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/$1"
    [ -f "$flag" ] || return
    local mode
    mode=$(head -n1 "$flag" | tr -d '[:space:]')
    [ -z "$mode" ] || [ "$mode" = "full" ] && echo "" || echo "$mode"
}

if [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.ponytail-active" ]; then
    export CC_PONYTAIL=$(read_mode_flag .ponytail-active)
fi
if [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active" ]; then
    export CC_CAVEMAN=$(read_mode_flag .caveman-active)
fi

STARSHIP_CONFIG="$HOME/.config/claude/statusline/starship.toml" starship prompt
