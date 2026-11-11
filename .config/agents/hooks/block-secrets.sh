#!/usr/bin/env bash
# PreToolUse hook: hard-deny any tool call that would pull a secret into context.
# Layer 2 of 2 — permissions.deny in settings.json covers the file tools; this covers
# Bash (cat .env, printenv, gh auth token) and MCP tools that take a path.
#
# SECRETS_OK=1 anywhere in the command/args turns a deny into an "ask": the user
# approves the call, never the agent alone (it can type SECRETS_OK=1 itself).
set -uo pipefail
shopt -s nocasematch

input=$(cat)

# Every field a tool might use to name a file or run a command.
target=$(jq -r '
  [ .tool_input.file_path?, .tool_input.notebook_path?, .tool_input.path?,
    .tool_input.pattern?, .tool_input.command?, .tool_input.code?,
    (.tool_input.paths? // [] | .[]?), (.tool_input.commands? // [] | .[]?.command)
  ] | map(select(type == "string")) | join(" ")' <<<"$input")

[[ -z "$target" ]] && exit 0
decision=deny
[[ "$target" == *SECRETS_OK=1* ]] && decision=ask

# Drop text that names no file being read before matching. A quoted-delimiter
# heredoc fed to cat/tee is literal data the agent wrote (PLAN.md edits, configs,
# docs); an interpreter heredoc is kept, since its body can open files. jq
# filters (`'.env'`, `.key`) are object paths, and `e.key ===` / `.env(` /
# `.key_event` are code. An env dump piped through a value-stripping sed/cut or
# a counting grep prints no values. Safe template names keep .env.example off
# the .env rule.
scrubbed=$(awk '
  skip { t = $0; sub(/^\t+/, "", t); if (t == delim) skip = 0; next }
  /(^|[;&|(`[:space:]])(cat|tee)[[:space:]]/ && match($0, /<<-?[[:space:]]*["\047][A-Za-z_][A-Za-z0-9_]*["\047]/) {
    delim = substr($0, RSTART, RLENGTH); gsub(/^<<-?[[:space:]]*["\047]|["\047]$/, "", delim)
    print; skip = 1; next
  }
  { print }' <<<"$target" | sed -E \
  -e "s/(^|[^[:alnum:]_-])jq([[:space:]]+-[[:alnum:]-]+)*[[:space:]]+'[^']*'/\1jq/g" \
  -e 's/\.(env|key)[[:space:]]*[!=]==?//gi' \
  -e "s/(printenv|env)[[:space:]]*(\|[^;&|]*)*\|[[:space:]]*(sed[[:space:]]+(-E[[:space:]]+)?'s\/=\.\*\/[^']*'|cut[[:space:]]+-d[[:space:]]*'?='?[[:space:]]*-f[[:space:]]*1|(rg|grep)([[:space:]]+-[[:alpha:]]+)*[[:space:]]+-[[:alpha:]]*c[[:alpha:]]*[[:space:]])/env-redacted/g" \
  -e 's/\.env\.(example|sample|template|dist|schema)[[:alnum:].]*//gi')

deny() {
  jq -nc --arg r "$1" --arg d "$decision" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $d,
      permissionDecisionReason: ("Blocked by block-secrets hook: " + $r +
        " Secrets must never enter context. If this is genuinely not sensitive, re-run with SECRETS_OK=1 in the command to ask the user to approve it.")
    }
  }'
  exit 0
}

# One combined regex per list, tested per line (grep -E semantics: ^ and $ are
# line anchors); the loop that names the rule only runs on a hit. A grep per
# pattern cost ~120 ms on every tool call of every harness.
mapfile -t lines <<<"$scrubbed"
scan() { # scan <reason-prefix> <patterns...>
  local why=$1 all="" p line; shift
  for p in "$@"; do all+="${all:+|}($p)"; done
  for line in "${lines[@]}"; do
    [[ $line =~ $all ]] || continue
    for p in "$@"; do [[ $line =~ $p ]] && deny "$why (${p})."; done
  done
}

# --- Secret file paths (any tool) ---
paths=(
  # A backslash before the dot is a search regex (`rg '\.env'`); `(` or `_`
  # after it is a method call (`.env("PATH", …)`, `.env_clear()`).
  '(^|[^[:alnum:]_.\\-])\.env([^[:alnum:]_(]|$)'   # .env, .env.local, .env.production
  # A basename char must precede the dot: jq's `.key` / `select(.key|…)` has none.
  '[[:alnum:]_-]\.(pem|key|p12|pfx|jks|keystore|ppk|asc|gpg|p8|kdbx|ovpn)([^[:alnum:]_(]|$)'
  'id_(rsa|dsa|ecdsa|ed25519)'
  '\.(ssh|aws|gnupg|kube|docker|azure|config/gcloud)/'
  '\.(npmrc|pypirc|netrc|git-credentials|htpasswd|pgpass|my\.cnf)([^[:alnum:]]|$)'
  # The bare word is prose ("client credentials, logs"); a file needs an
  # extension or a path separator in front of it.
  '(^|[/[:space:]"'"'"'=])credentials?\.(json|ya?ml|ini|csv)([^[:alnum:]]|$)'
  '/credentials?([[:space:]"'"'"';|)]|$)'
  # A leading dot puts the char before "credentials" outside the class above, so
  # ~/.claude/.credentials.json needs its own rule. Kept suffixed so it cannot
  # fire on a plain `obj.credentials` attribute access in code being read.
  '\.credentials\.(json|ya?ml)([^[:alnum:]]|$)'
  'secrets?\.(json|ya?ml|toml|env|ini|txt|enc)'
  'service[-_]?account.*\.json'
  'terraform\.tfvars'
  '(client_secret|serviceAccountKey|firebase-adminsdk)'
  # Per-tool token stores. auth.json is what codex, pi and the vercel CLI all
  # use; the leading-char class keeps it off "oauth.json".
  '(^|[^[:alnum:]_-])\.?auth\.json'
  'gh/hosts\.ya?ml'
  'rclone\.conf'
  '(^|[^[:alnum:]_-])\.?authinfo(\.gpg)?([^[:alnum:]]|$)'
  # Local secret vaults.
  '\.local/share/keyrings/'
  '\.password-store/'
  'age/keys\.txt'
  # Documented convention: mise.toml is committed, mise.local.toml is where the
  # secrets go and is never tracked.
  'mise\.local\.toml'
  # sops-nix decrypted secrets, and any process's environment.
  '/run/secrets(\.d)?([/[:space:]"'"'"';|)]|$)'
  '/proc/[^/[:space:]]+/environ'
)
scan "the path matches a known secret-file pattern" "${paths[@]}"

# --- Bash-only: commands that print secrets even with no secret path in them ---
cmds=(
  # env dump, not `env FOO=1 cmd` or the `|env|` alternation inside a quoted regex
  '(^|[;&|(]|&&)[[:space:]]*(printenv|env)[[:space:]]*($|>|\|[[:space:]])'
  '(^|[;&|(])[[:space:]]*export[[:space:]]+-p'
  'gh[[:space:]]+auth[[:space:]]+token'
  'aws[[:space:]]+configure[[:space:]]+get'
  'gcloud[[:space:]]+auth[[:space:]]+print-(access|identity)-token'
  'az[[:space:]]+account[[:space:]]+get-access-token'
  '\bop[[:space:]]+read\b'
  '(^|[;&|(])[[:space:]]*pass[[:space:]]+show\b'
  '(^|[;&|(])[[:space:]]*bw[[:space:]]+get\b'
  'security[[:space:]]+find-(generic|internet)-password'
  'secret-tool[[:space:]]+lookup'
  'kubectl[[:space:]]+get[[:space:]]+secret'
  'vault[[:space:]]+(kv[[:space:]]+get|read)'
  '(echo|printf|print)[^;|&]*\$\{?[A-Za-z_]*(KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|APIKEY)'
  'printenv[[:space:]]+[A-Za-z_]*(KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|APIKEY)'
  # Shell variable dumps: bash/fish `set`, `declare -p`, `typeset -p`.
  '(^|[;&|(])[[:space:]]*(set|(declare|typeset)[[:space:]]+-p)[[:space:]]*($|>|\|)'
  # A secret variable handed to a network client leaves the machine.
  '(curl|wget2?|xh|https?|nc|ncat|socat)[[:space:]][^;|&]*\$\{?[A-Za-z_]*(KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|APIKEY)'
)
scan "the command would expose credentials" "${cmds[@]}"

exit 0
