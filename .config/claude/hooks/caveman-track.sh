#!/usr/bin/env bash
# caveman has no plugin-provided flag file (it's a user skill, not a plugin with hooks),
# so mirror ponytail's own pattern: UserPromptSubmit hook writes level to a flag file
# statusline.sh can read. See plugins/marketplaces/ponytail/hooks/ponytail-mode-tracker.js.
flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
prompt=$(jq -r '.prompt // empty' | tr '[:upper:]' '[:lower:]' | xargs 2>/dev/null)

if [[ "$prompt" =~ ^/caveman(:caveman)?([[:space:]]+([a-z-]+))?$ ]]; then
    case "${BASH_REMATCH[3]}" in
        lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra) echo "${BASH_REMATCH[3]}" > "$flag" ;;
        "") echo "full" > "$flag" ;;
    esac
elif [[ "$prompt" == "stop caveman" || "$prompt" == "normal mode" ]]; then
    rm -f "$flag"
fi

exit 0
