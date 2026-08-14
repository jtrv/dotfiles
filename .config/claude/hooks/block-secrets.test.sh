#!/usr/bin/env bash
# Feeds synthetic PreToolUse payloads at block-secrets.sh and asserts deny/allow.
# DENY cases are what we want blocked; ALLOW cases are the false positives we must not create.
HOOK="$HOME/.config/claude/hooks/block-secrets.sh"
fail=0

check() { # check <expect: DENY|ALLOW> <field> <value>
  local expect=$1 field=$2 value=$3 out verdict
  out=$(jq -nc --arg v "$value" --arg f "$field" '{tool_input: {($f): $v}}' | bash "$HOOK")
  if [[ -n "$out" ]]; then verdict=DENY; else verdict=ALLOW; fi
  if [[ "$verdict" != "$expect" ]]; then
    printf '  FAIL  expected %-5s got %-5s : %s\n' "$expect" "$verdict" "$value"
    fail=1
  else
    printf '  ok    %-5s : %s\n' "$verdict" "$value"
  fi
}

echo "== new path rules: must DENY =="
check DENY file_path "$HOME/.config/codex/auth.json"
check DENY file_path "$HOME/.config/pi/auth.json"
check DENY file_path "$HOME/.local/share/com.vercel.cli/auth.json"
check DENY file_path "$HOME/.claude/.credentials.json"
check DENY file_path "$HOME/.config/gh/hosts.yml"
check DENY file_path "$HOME/.config/rclone/rclone.conf"
check DENY file_path "$HOME/.local/share/keyrings/login.keyring"
check DENY file_path "$HOME/.password-store/mail/work.gpg"
check DENY file_path "$HOME/.config/sops/age/keys.txt"
check DENY file_path "$HOME/repos/quickword/mise.local.toml"
check DENY file_path "$HOME/.my.cnf"
check DENY file_path "$HOME/vault.kdbx"
check DENY file_path "$HOME/work.ovpn"
check DENY file_path "$HOME/AuthKey_ABC123.p8"
check DENY file_path "$HOME/.authinfo.gpg"
check DENY command   'cat ~/.config/codex/auth.json'

echo "== pre-existing rules still fire =="
check DENY file_path "/srv/app/.env"
check DENY file_path "$HOME/.ssh/id_ed25519"
check DENY command   'gh auth token'
check DENY command   'gcloud auth print-access-token'
check DENY command   'az account get-access-token'
check DENY command   'pass show mail/work'
check DENY command   'bw get password github'

echo "== must ALLOW (false positives we must not introduce) =="
check ALLOW file_path "$HOME/repos/quickword/mise.toml"
check ALLOW file_path "$HOME/.config/mise/config.toml"
check ALLOW file_path "/srv/app/src/oauth.json"
check ALLOW file_path "/srv/app/.env.example"
check ALLOW file_path "/srv/app/src/auth.ts"
check ALLOW file_path "/srv/app/public/cert.crt"
check ALLOW file_path "$HOME/.ssh_config_notes.md"
check ALLOW pattern   'session.credentials'
check ALLOW pattern   'user.age'
check ALLOW pattern   'const authJson = 1'
check ALLOW command   'rg "authentication" src/'
check ALLOW command   'git pass-through --show'
check ALLOW command   'env FOO=1 bun test'
check ALLOW command   'bw list items'

echo "== escape hatch =="
check ALLOW command   'SECRETS_OK=1 cat ~/.config/codex/auth.json'

[[ $fail -eq 0 ]] && echo "ALL PASS" || echo "FAILURES"
exit $fail
