#!/usr/bin/env bash
# Feeds synthetic PreToolUse payloads at guard-rm.sh and asserts ask/pass.
# ASK cases must still prompt; PASS cases are the cleanups that used to hold sessions up.
#
# The hook only parses and never runs a command, but this file is about rm -rf on real
# paths, so it runs where none can land: re-exec under bubblewrap with the whole
# filesystem read-only, a fresh tmpfs on /tmp, and another over $HOME so the real home
# is not even visible — only this hooks dir is bound back, read-only. The fake home has
# to sit at the real path: one inside /tmp would pass every case as a temp path.
hooks="$(cd "$(dirname "$0")" && pwd)"
HOOK="$hooks/guard-rm.sh"
if [[ -z ${GUARD_RM_SANDBOXED:-} ]]; then
  command -v bwrap >/dev/null || { echo "bwrap not found; refusing to run outside a sandbox" >&2; exit 1; }
  exec bwrap --ro-bind / / --tmpfs /tmp --tmpfs "$HOME" --ro-bind "$hooks" "$hooks" \
    --dev /dev --proc /proc --unshare-all --die-with-parent --setenv GUARD_RM_SANDBOXED 1 \
    bash "$hooks/$(basename "$0")" "$@"
fi
touch /etc/guard-rm-probe 2>/dev/null && { echo "sandbox is writable outside /tmp; aborting" >&2; exit 1; }
[[ -e $HOME/.ssh || -e $HOME/repos ]] && { echo "real home is visible in the sandbox; aborting" >&2; exit 1; }
fixture=$(mktemp -d)
mkdir -p "$HOME/repos/dotfiles/.git" "$HOME/.cache/guard-rm-test-repo/.git"
fail=0

check() { # check <expect: ASK|PASS> <cwd> <command>
  local expect=$1 cwd=$2 cmd=$3 out verdict
  out=$(jq -nc --arg c "$cmd" --arg d "$cwd" '{cwd: $d, tool_input: {command: $c}}' | bash "$HOOK")
  if [[ -n "$out" ]]; then verdict=ASK; else verdict=PASS; fi
  if [[ "$verdict" != "$expect" ]]; then
    printf '  FAIL  expected %-4s got %-4s : %s\n' "$expect" "$verdict" "${cmd//$'\n'/⏎}"
    fail=1
  else
    printf '  ok    %-4s : %s\n' "$verdict" "${cmd//$'\n'/⏎}"
  fi
}

proj="$HOME/repos/dotfiles"
echo "== temp and deep project paths: PASS =="
check PASS "$proj" 'rm -rf /tmp/claude-1000/scratch/build'
check PASS "$proj" 'S=/tmp/claude-1000/x/scratchpad; rm -f $S/info2; rm -rf "$S/iso" "$S/out"'
check PASS "$proj" 'rm -rf /tmp/foo* 2>/dev/null'
check PASS "$proj" "rm -rf $fixture/a"
check PASS "$proj" 'cd /tmp/work && rm -rf build dist'
check PASS "$proj" 'rm -rf /var/tmp/x'
check PASS "$proj" 'rm -rf "$XDG_RUNTIME_DIR/claude-statusline"'
check PASS "$proj" 'rm -rf node_modules target'
check PASS "$proj" 'rm -rf ~/repos/dotfiles/.claude/worktrees/kak-plugin'
check PASS "$proj" 'rm -rf ~/.cache/uv/archive-v0'
check PASS "$proj" 'sudo rm -rf /tmp/mnt-test'
check PASS "$proj" 'git rm -r --cached .'
check PASS "$proj" 'rm notes.txt'
check PASS "$proj" 'echo hi; ls -R'

echo "== home, important dirs, unknowns: ASK =="
check ASK "$proj" 'rm -rf ~'
check ASK "$proj" 'rm -rf $HOME'
check ASK "$proj" 'rm -rf /'
check ASK "$proj" 'rm -rf /tmp'
check PASS "$proj" 'rm -rf /tmp/*'
check ASK "$proj" 'rm -rf /tmp/../home/sugimoto'
check ASK "$proj" 'rm -rf ~/repos'
check ASK "$proj" 'rm -rf ~/repos/dotfiles'
check ASK "$proj" 'rm -rf .git'
check ASK "$proj" 'rm -rf *'
check ASK "$proj" 'rm -rf ~/.config/agents/skills/foo'
check ASK "$proj" 'rm -rf ~/.local/share/Steam/steamapps'
check ASK "$proj" 'rm -rf ~/.ssh/old'
check ASK "$proj" 'rm -rf ~/.cache'
check ASK "$proj" 'rm -rf ~/.cache/guard-rm-test-repo'
check ASK "$proj" 'rm -rf /etc/nixos'
check ASK "$proj" 'rm -rf "$UNSET_GUARD_RM_VAR/"'
check ASK "$proj" 'rm -rf $(mktemp -d)/../..'
check ASK "$proj" 'find . -name x -exec rm -rf {} +'
check ASK "$proj" 'ls | xargs rm -rf'
check ASK "$proj" 'rm -r -f ~/repos'
check ASK "$proj" 'rm --recursive ~/documents/x/y'
check ASK "$proj" 'rm -rf /tmp/x; rm -rf ~/repos'
check ASK "$proj" $'rm -rf /tmp/x\nrm -rf ~'
check ASK "$proj" 'rm -rf "unterminated'
check ASK "/tmp" 'cd ~ && rm -rf repos/x'
HOME="$fixture/home" check ASK "$proj" 'rm -rf ~'  # a home under /tmp is still home

[[ $fail -eq 0 ]] && echo "ALL PASS" || echo "FAILURES"
exit $fail
