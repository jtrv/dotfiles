#!/bin/sh
# Bar: an LSP plugin in the Codex catalog, or a native LSP feature flag -> give Codex
# cross-file navigation instead of shell linters (PLUGINS.md, Language servers row)
command -v codex >/dev/null || { echo "UNKNOWN: codex not installed"; exit 0; }
plugins=$(codex plugin list 2>/dev/null) || { echo "UNKNOWN: codex plugin list failed (auth/network)"; exit 0; }
# The catalog is remote; an empty list means the fetch failed, not that it is empty.
[ -z "$plugins" ] && { echo "UNKNOWN: empty plugin catalog — fetch likely failed"; exit 0; }
feats=$(codex features list 2>/dev/null)

# 'pyright' matches inside 'copyright', so anchor on LSP terms that do not hide in prose.
hit=$(printf '%s\n%s\n' "$plugins" "$feats" | grep -iE 'lsp|language.server|rust-analyzer|gopls|clangd|tsserver')
if [ -n "$hit" ]; then
  echo "CHECK: Codex LSP surfaced — $(echo "$hit" | head -3 | tr '\n' ';')"
else
  echo "NOT-READY: no LSP plugin in the Codex catalog and no LSP feature flag"
fi
