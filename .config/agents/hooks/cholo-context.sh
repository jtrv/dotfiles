#!/usr/bin/env bash

[[ ${CHOLO_OFF:-} == 1 ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
skill=${CHOLO_SKILL:-${HOME}/.config/agents/skills/cholo/SKILL.md}
[[ -f $skill && -r $skill && ! -t 0 ]] || exit 0

# EOF need not include a newline; a still-open idle pipe must not stall startup.
payload=''
IFS= read -r -d '' -t 2 payload 2>/dev/null || [[ $? == 1 ]] || exit 0

jq -cn --arg payload "$payload" --arg fallback "${1:-}" --rawfile skill "$skill" '
  ($payload | fromjson | select(type == "object")) as $input
  | ($input.hook_event_name | if type == "string" and length > 0 then . else $fallback end) as $event
  | select($event == "SessionStart" or $event == "SubagentStart")
  | ($input.agent_type | if type == "string" then ascii_downcase else "" end) as $agent
  | select($event != "SubagentStart" or
      (["explore", "claude-code-guide", "statusline-setup"] | index($agent) | not))
  | {hookSpecificOutput: {
      hookEventName: $event,
      additionalContext: ($skill | sub("^---\\r?\\n[\\s\\S]*?\\r?\\n---(?:\\r?\\n|$)"; ""))
    }}
' 2>/dev/null || :
exit 0
