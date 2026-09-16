# Artifacts context

## Decision artifacts: always add a Copy-for-Claude button

Any artifact whose point is collecting the user's choices — Yes/No triage boards,
review forms, note collectors, anything with inputs or toggle buttons — MUST include a
`position: fixed` button (bottom-right, label "Copy for Claude") that serializes the
current state into readable markdown and copies it to the clipboard, so the user can
paste it into the prompt.

Why: network read-back of artifact state is fragile (live-doc journals aren't visible
to WebFetch; hooks and permission classifiers can block fetches — an hour lost
2026-08-19). The clipboard path is user-controlled and always works. Treat any
network/journal persistence as a bonus channel, never the only one.

Implementation sketch:
- Markdown, one line per item: label + decision/note; skip empties; heading naming the
  board.
- `navigator.clipboard.writeText`, with a selectable readonly `<textarea>` overlay as
  fallback (clipboard API can be blocked in the artifact iframe).
- "Copied ✓" feedback on the button; keep the button inside `<artifact-local>` on
  live-doc pages so its state stays per-viewer.
