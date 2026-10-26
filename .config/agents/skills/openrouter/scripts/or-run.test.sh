#!/usr/bin/env bash
# Self-check for or-run with a fake curl: request shape, key off argv, ZDR default, errors.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/curl" <<'F'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$RECORD.argv"
out='' body=''
while [[ $# -gt 0 ]]; do
  case $1 in
    -o) out=$2; shift ;;
    --config) cat "$2" > "$RECORD.config"; shift ;;
    --data-binary) body=${2#@}; shift ;;
  esac
  shift
done
cp "$body" "$RECORD.body"
if jq -e '.model == "bad/model"' "$body" >/dev/null; then
  echo '{"error":{"message":"No allowed providers"}}' > "$out"; printf 404
else
  jq -n --slurpfile b "$body" '{model: $b[0].model, provider: "Fake",
    usage: {prompt_tokens: 3, completion_tokens: 2, cost: 0.0001},
    choices: [{finish_reason: "stop", message: {content: ("echo:" + $b[0].messages[-1].content)}}]}' > "$out"
  printf 200
fi
F
chmod +x "$tmp/curl"
export OR_CURL=$tmp/curl RECORD=$tmp/rec OPENROUTER_API_KEY=sk-test-123

echo "be terse" > "$tmp/sys"
out=$("$here/or-run" --model a/b --system-file "$tmp/sys" --max-tokens 50 "hello world" 2>"$tmp/err")
[[ $out == "echo:hello world" ]] || { echo "FAIL reply: $out"; exit 1; }
grep -q 'sk-test-123' "$tmp/rec.argv" && { echo "FAIL: key in argv"; exit 1; }
grep -q 'Bearer sk-test-123' "$tmp/rec.config" || { echo "FAIL: no auth header"; exit 1; }
jq -e '.model == "a/b" and .max_tokens == 50 and .messages[0].role == "system"
  and .messages[0].content == "be terse" and .provider.zdr == true
  and .provider.data_collection == "deny"' "$tmp/rec.body" >/dev/null \
  || { echo "FAIL body:"; cat "$tmp/rec.body"; exit 1; }
grep -q 'via Fake' "$tmp/err" || { echo "FAIL: no stats line"; exit 1; }

echo "from stdin" | "$here/or-run" --model a/b --allow-retention - >/dev/null 2>&1
jq -e '.provider == null and .messages[0].content == "from stdin"' "$tmp/rec.body" >/dev/null \
  || { echo "FAIL stdin/retention:"; cat "$tmp/rec.body"; exit 1; }

if "$here/or-run" --model bad/model x >/dev/null 2>"$tmp/err"; then echo "FAIL: error exited 0"; exit 1; fi
grep -q 'No allowed providers' "$tmp/err" || { echo "FAIL: error not surfaced"; cat "$tmp/err"; exit 1; }
if "$here/or-run" x >/dev/null 2>"$tmp/err"; then echo "FAIL: ran without --model"; exit 1; fi
if OPENROUTER_API_KEY='' "$here/or-run" --model a/b x >/dev/null 2>"$tmp/err"; then echo "FAIL: ran without key"; exit 1; fi
grep -q 'OPENROUTER_API_KEY' "$tmp/err" || { echo "FAIL: key message"; exit 1; }
echo "or-run: all checks passed"
