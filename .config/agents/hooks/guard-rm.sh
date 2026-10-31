#!/usr/bin/env bash
# PreToolUse hook for Bash: ask before a recursive rm outside temp dirs and deep project
# paths. The decision is guard-rm.py; this wrapper keeps python off every other command
# and turns a missing or crashing interpreter into "ask", the old blanket rule, rather
# than a silent pass. Run the cases in guard-rm.test.sh after changing either file.
set -uo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
grep -qE '(^|[^[:alnum:]_-])rm[[:space:]]' <<<"$command" || exit 0
grep -qE '[[:space:]](-[[:alnum:]]*[rR]|--recursive)' <<<"$command" || exit 0

# /usr/bin first: a mise shim resolves per project and errors where none is pinned.
py=/usr/bin/python3
[[ -x $py ]] || py=$(command -v python3) || py=""
if [[ -n $py ]] && out=$("$py" -I "$(dirname "$0")/guard-rm.py" <<<"$input"); then
  printf '%s' "$out"
  exit 0
fi
jq -nc '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask",
  permissionDecisionReason: "guard-rm: could not run its python check, so asking."}}'
