#!/usr/bin/env bash
# agy PreToolUse adapter. agy has no read-only flag and headless runs soft-deny
# into silence, so delegate children run with --dangerously-skip-permissions and
# this hook is the gate: an allowlist of read tools when PI_DELEGATE_MODE is
# read-only, then block-secrets.sh with agy's payload rewritten into Claude's.
set -uo pipefail

input=$(cat)
name=$(jq -r '.toolCall.name // ""' <<<"$input")

if [[ "${PI_DELEGATE_MODE:-}" == read-only ]]; then
  case "$name" in
    view_file|find_by_name|grep_search|list_dir|list_resources|read_resource|list_permissions|manage_task|ask_question|finish|wait|wait_5_seconds) ;;
    *)
      jq -nc --arg n "$name" '{decision: "deny", reason: ("read-only delegate child: " + $n + " is not permitted")}'
      exit 0
      ;;
  esac
fi

# Every string argument lands in command so paths and shell lines are both scanned.
claude=$(jq -c '{tool_input: {command: ([.toolCall.args // {} | .. | strings] | join(" "))}}' <<<"$input")
out=$(bash "$(dirname "$0")/block-secrets.sh" <<<"$claude")
reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out" 2>/dev/null)
if [[ -n "$reason" ]]; then
  jq -nc --arg r "$reason" '{decision: "deny", reason: $r}'
elif [[ -n "${PI_DELEGATE_MODE:-}" ]]; then
  # An empty object is treated as deny, so a pass must say so. A delegate child already runs
  # with permissions skipped; an interactive session keeps its own prompts and allow cache.
  echo '{"decision": "allow"}'
else
  echo '{"decision": "ask"}'
fi
