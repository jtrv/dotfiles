#!/usr/bin/env bash
# caveman has no plugin-provided flag file (it's a user skill, not a plugin with hooks),
# so mirror ponytail's own pattern: UserPromptSubmit hook writes level to a flag file
# statusline.sh can read. See plugins/marketplaces/ponytail/hooks/ponytail-mode-tracker.js.
flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
prompt=$(jq -r '.prompt // empty' | tr '[:upper:]' '[:lower:]' | xargs 2>/dev/null)

# Claude Code hands a slash command to hooks as an envelope rather than the text the user
# typed: <command-name>/caveman</command-name> <command-args>ultra</command-args>. Rebuild
# the literal form so the match below sees it. Without this every slash invocation was a
# silent no-op and the flag froze at whatever it last held.
if [[ "$prompt" =~ \<command-name\>[[:space:]]*([^\<[:space:]]+) ]]; then
    name="${BASH_REMATCH[1]}"
    # a foreign command's args must not misfire our triggers
    [[ "$name" == /caveman* ]] || exit 0
    args=""
    [[ "$prompt" =~ \<command-args\>([^\<]*) ]] && args=$(xargs <<< "${BASH_REMATCH[1]}" 2>/dev/null)
    prompt="$name${args:+ $args}"
fi

if [[ "$prompt" =~ ^/caveman(:caveman)?([[:space:]]+([a-z-]+))?$ ]]; then
    case "${BASH_REMATCH[3]}" in
        lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra) echo "${BASH_REMATCH[3]}" > "$flag" ;;
        off) rm -f "$flag" ;;
        "") echo "full" > "$flag" ;;
    esac
elif [[ "$prompt" == "stop caveman" || "$prompt" == "normal mode" ]]; then
    rm -f "$flag"
fi

exit 0
