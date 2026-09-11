#!/usr/bin/env bash
# PreToolUse hook: hard-deny any tool call that would pull a secret into context.
# Layer 2 of 2 — permissions.deny in settings.json covers the file tools; this covers
# Bash (cat .env, printenv, gh auth token) and MCP tools that take a path.
#
# Escape hatch: put SECRETS_OK=1 anywhere in the command/args to bypass for one call.
set -uo pipefail

input=$(cat)

# Every field a tool might use to name a file or run a command.
target=$(jq -r '
  [ .tool_input.file_path?, .tool_input.notebook_path?, .tool_input.path?,
    .tool_input.pattern?, .tool_input.command?, .tool_input.code?,
    (.tool_input.paths? // [] | .[]?), (.tool_input.commands? // [] | .[]?.command)
  ] | map(select(type == "string")) | join(" ")' <<<"$input")

[[ -z "$target" ]] && exit 0
[[ "$target" == *SECRETS_OK=1* ]] && exit 0

# Drop safe template names before matching, so .env.example never trips the .env rule.
scrubbed=$(sed -E 's/\.env\.(example|sample|template|dist|schema)[[:alnum:].]*//gi' <<<"$target")

deny() {
  jq -nc --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Blocked by block-secrets hook: " + $r +
        " Secrets must never enter context. If this file is genuinely not sensitive, re-run with SECRETS_OK=1 in the command.")
    }
  }'
  exit 0
}

# --- Secret file paths (any tool) ---
paths=(
  '(^|[^[:alnum:]_.-])\.env([^[:alnum:]]|$)'   # .env, .env.local, .env.production
  '\.(pem|key|p12|pfx|jks|keystore|ppk|asc|gpg|p8|kdbx|ovpn)([^[:alnum:]]|$)'
  'id_(rsa|dsa|ecdsa|ed25519)'
  '\.(ssh|aws|gnupg|kube|docker|azure|config/gcloud)/'
  '\.(npmrc|pypirc|netrc|git-credentials|htpasswd|pgpass|my\.cnf)([^[:alnum:]]|$)'
  '(^|[/[:space:]"'"'"'=])credentials?(\.(json|ya?ml|ini|csv))?([^[:alnum:]/]|$)'
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
)
for p in "${paths[@]}"; do
  grep -qEi -- "$p" <<<"$scrubbed" && deny "the path matches a known secret-file pattern (${p})."
done

# --- Bash-only: commands that print secrets even with no secret path in them ---
cmds=(
  '(^|[;&|(]|&&)[[:space:]]*(printenv|env)[[:space:]]*($|[|>])'  # env dump, not `env FOO=1 cmd`
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
)
for c in "${cmds[@]}"; do
  grep -qEi -- "$c" <<<"$scrubbed" && deny "the command would print credentials to stdout (${c})."
done

exit 0
