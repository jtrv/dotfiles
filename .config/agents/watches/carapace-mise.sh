#!/bin/sh
# Bar: installed carapace ships a built-in mise completer (upstream e3c36952,
# after v1.8.1) -> delete ~/.config/carapace/specs/mise.yaml
command -v carapace >/dev/null || { echo "UNKNOWN: carapace not on PATH"; exit 0; }
v=$(carapace --version 2>/dev/null | cut -d' ' -f2)
g=$(carapace --list 2>/dev/null | jq -r '.mise[]?.group | select(. != "user" and . != "bridge")' 2>/dev/null | head -1)
if [ -n "$g" ]; then
  echo "CHECK: carapace $v has a built-in mise completer ($g) — delete specs/mise.yaml, check 'mise run <TAB>' shows descriptions"
else
  echo "NOT-READY: carapace $v has no built-in mise completer — keep specs/mise.yaml"
fi
