# User-global instructions

## Clipboard for user-run commands
When presenting a command the user must run themselves (a `! ...` session command, sudo, interactive login, key management, etc.), also copy it to the clipboard: pipe the exact command text (without the `!` prefix) to `wl-copy` via Bash, then tell the user it's on their clipboard. Only copy the single command the user is most likely to run next (if several, copy the first and say so). Never copy secrets or values the user must fill in — copy the template with the placeholder instead. Check `command -v wl-copy` first and skip silently (no error, no comment) if it's unavailable.

## Never add co-author
Never add "co-authored by Claude Code" to commit messages.

## Parallel edit agents: no tree-wide git state changes
When dispatching multiple agents that edit the same working tree concurrently, every agent brief must forbid `git stash`, `git reset`, `git checkout`/`git restore` on paths outside the agent's assigned files, and any other tree-wide git state change. One agent stashing to A/B against HEAD silently wipes the others' uncommitted edits. If an agent needs a pristine baseline to compare against, it must use an isolated `git worktree` instead. Commit each agent's files as soon as it finishes rather than batching at the end.
