#!/usr/bin/env bash
set -euo pipefail

dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fixture=$(mktemp -d "$dir/.cholo-test.XXXXXX")
trap 'rm -rf -- "$fixture"' EXIT
export CHOLO_SKILL="$fixture/SKILL.md"
export CHOLO_OFF=0
printf '%s\n' '' '# Cholo' 'Keep "quotes", backslashes \, and Unicode: λ.' '' > "$fixture/body"
{ printf '%s\n' '---' 'name: cholo' 'description: test' '---'; cat "$fixture/body"; } > "$CHOLO_SKILL"
count=0

injected() {
  local output
  output=$(printf '%s' "$1" | bash "$dir/cholo-context.sh" "${3:-}")
  jq -e --arg event "$2" --rawfile body "$fixture/body" '
    . == {hookSpecificOutput: {hookEventName: $event, additionalContext: $body}}
  ' <<< "$output" >/dev/null
  count=$((count + 1))
}

empty() {
  local output
  output=$(printf '%s' "$1" | bash "$dir/cholo-context.sh")
  [[ -z $output ]]
  count=$((count + 1))
}

injected '{"hook_event_name":"SessionStart"}' SessionStart
empty '{"hook_event_name":"SubagentStart","agent_type":"Explore"}'
empty '{"hook_event_name":"SubagentStart","agent_type":"CLAUDE-CODE-GUIDE"}'
empty '{"hook_event_name":"SubagentStart","agent_type":"Statusline-Setup"}'
injected '{"hook_event_name":"SubagentStart","agent_type":"general-purpose"}' SubagentStart
injected '{"hook_event_name":"SubagentStart"}' SubagentStart
injected '{"hook_event_name":"SubagentStart","agent_type":{}}' SubagentStart
injected '{"hook_event_name":"SubagentStart","agent_type":"Explore-more"}' SubagentStart
injected '{}' SessionStart SessionStart
injected '{"hook_event_name":"SessionStart"}' SessionStart SubagentStart
CHOLO_SKILL="$fixture/missing" empty '{"hook_event_name":"SessionStart"}'
CHOLO_OFF=1 empty '{"hook_event_name":"SessionStart"}'
empty 'not json'
empty ''
empty '[]'
empty '{"hook_event_name":"Other"}'
output=$(bash "$dir/cholo-context.sh" <&-)
[[ -z $output ]]
count=$((count + 1))
printf 'PASS: %s assertions\n' "$count"
