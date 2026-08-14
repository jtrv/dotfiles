#!/usr/bin/env bash
# Recreate user-scope MCP servers.
#
# These live in ~/.claude.json, which is the only user-scope location Claude Code
# reads (settings.json has no mcpServers key) and is untracked because it also
# holds auth state and per-project history. So the definitions live here instead
# and this script replays them onto a fresh machine.
#
# Skips servers that already exist — `claude mcp add` has no --force, and a
# rebuild script has no business clobbering a definition you tuned by hand.
# To re-apply a changed definition: claude mcp remove <name>, then re-run.

set -euo pipefail

# Chromium is passed explicitly: @playwright/mcp defaults to the `chrome`
# channel at /opt/google/chrome/chrome, which does not exist on this box.
if claude mcp get playwright >/dev/null 2>&1; then
	echo "skip: playwright"
else
	claude mcp add --scope user playwright -- \
		bunx @playwright/mcp@latest --executable-path "$(command -v chromium)" --headless
fi

echo "Done. Verify with: claude mcp list"
