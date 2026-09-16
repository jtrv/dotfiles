#!/usr/bin/env bash
# Self-check for agy-run with a fake agy: arg contract, mode env, gate refusal, error exit.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/gemini/config"
cat > "$tmp/agy-pretool.sh" <<'H'
#!/usr/bin/env bash
echo '{"decision":"allow"}'
H
chmod +x "$tmp/agy-pretool.sh"
echo "{\"g\":{\"PreToolUse\":[{\"matcher\":\"*\",\"hooks\":[{\"command\":\"bash $tmp/agy-pretool.sh\"}]}]}}" > "$tmp/gemini/config/hooks.json"
cat > "$tmp/agy" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$RECORD"
echo "mode=$PI_DELEGATE_MODE" >> "$RECORD"
task=${@: -1}; task=${task#-p=}
echo "Waiting for authentication..."   # non-JSON noise must be skipped
if [[ $task == fail ]]; then
  echo '{"event":"result","result":{"status":"ERROR","response":"","error":"auth failed","num_turns":0,"duration_seconds":0,"usage":{"total_tokens":0}}}'
else
  echo '{"event":"step_update","step_update":{"step_type":"tool","tool_info":{"parameters":{"BypassSandbox":true}}}}'
  echo '{"event":"step_update","step_update":{"step_type":"agent_response","state":"DONE"}}'   # a later step must not mask the bypass
  echo "{\"event\":\"result\",\"result\":{\"status\":\"SUCCESS\",\"response\":\"echo:$task\",\"num_turns\":1,\"duration_seconds\":1,\"usage\":{\"total_tokens\":5}}}"
fi
F
chmod +x "$tmp/agy"
export AGY=$tmp/agy AGY_GEMINI_DIR=$tmp/gemini RECORD=$tmp/args

out=$("$here/agy-run" --model gemini-x --timeout 30 "hello world" 2>"$tmp/err")
[[ $out == "echo:hello world" ]] || { echo "FAIL response: $out"; exit 1; }
grep -qx -- "--gemini_dir=$tmp/gemini" "$RECORD" && grep -qx -- '--dangerously-skip-permissions' "$RECORD" \
  && grep -qx -- '--output-format=stream-json' "$RECORD" && grep -qx -- '--print-timeout=30s' "$RECORD" \
  && grep -qx -- '--model=gemini-x' "$RECORD" && grep -qx -- '-p=hello world' "$RECORD" \
  && grep -qx 'mode=read-only' "$RECORD" || { echo "FAIL args:"; cat "$RECORD"; exit 1; }
grep -q '^--sandbox$' "$RECORD" && { echo "FAIL: sandbox on by default"; exit 1; }
grep -q BypassSandbox "$tmp/err" || { echo "FAIL: no bypass warning"; exit 1; }

echo "via stdin" | "$here/agy-run" --write - >/dev/null 2>&1
grep -qx 'mode=write' "$RECORD" && grep -qx -- '-p=via stdin' "$RECORD" || { echo "FAIL write/stdin"; cat "$RECORD"; exit 1; }

if "$here/agy-run" fail >/dev/null 2>"$tmp/err"; then echo "FAIL: error status exited 0"; exit 1; fi
grep -q 'auth failed' "$tmp/err" || { echo "FAIL: error not surfaced"; exit 1; }

echo '{}' > "$tmp/gemini/config/hooks.json"
if "$here/agy-run" x >/dev/null 2>"$tmp/err"; then echo "FAIL: launched without gate"; exit 1; fi
grep -q 'refusing to launch' "$tmp/err" || { echo "FAIL: wrong gate error"; cat "$tmp/err"; exit 1; }
if "$here/agy-run" --model 2>"$tmp/err"; then echo "FAIL: dangling --model accepted"; exit 1; fi
grep -q 'needs a value' "$tmp/err" || { echo "FAIL: dangling flag message"; cat "$tmp/err"; exit 1; }
echo "agy-run: all checks passed"
