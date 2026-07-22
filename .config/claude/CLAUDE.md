# User-global instructions

## Clipboard for user-run commands
When presenting a command the user must run themselves (a `! ...` session command, sudo, interactive login, key management, etc.), also copy it to the clipboard: pipe the exact command text (without the `!` prefix) to `wl-copy` via Bash, then tell the user it's on their clipboard. Only copy the single command the user is most likely to run next (if several, copy the first and say so). Never copy secrets or values the user must fill in — copy the template with the placeholder instead. Check `command -v wl-copy` first and skip silently (no error, no comment) if it's unavailable.

## Never add co-author
Never add "co-authored by Claude Code" to commit messages.
