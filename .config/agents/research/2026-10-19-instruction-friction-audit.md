# Did skills, context files or plugins trip us up? (2026-09-19 → 2026-10-19)

Source: every Claude Code transcript under `~/.config/claude/projects` modified in
the window — 930 files, 335 of them subagent transcripts. No Codex or Pi session
logs exist on this machine, so those harnesses are not covered. Mining scripts
were throwaway (scratchpad); the counts below are from them.

## Real trips

1. **Co-author trailer vs the harness reminder.** 151 `git commit` calls carried
   `Co-Authored-By: Claude` between 09-17 and 09-28, despite the AGENTS.md rule
   (since 09-10). Histories still hold them: tscan-rs 104, dotfiles 17,
   career/runway 9, bdown-rs 2, laritech-practice 2. Most came from `grind`
   workers and subagents in tscan-rs and whats-up-doc. After the 09-29
   "outranks the reminder" wording: no local leaks found. Two runway commits on
   10-05 (`5ee994c`, `9e3eb6e`, `+0000` timezone) look like cloud sessions,
   which never load `~/.config/agents/AGENTS.md`. Not confirmed.
2. **Disabled plugin kept running.** The `learning-output-style` plugin injected
   "learning mode" into non-learning work. One user complaint: tscan-rs
   `cb440c21`, 09-26: "Stop running in the learning style, I never asked for
   that". It was disabled 09-27 (`e4e3863c`). It still fired in 15 sessions up
   to 10-09, every one a `SessionStart:clear` in a process started before the
   disable. `/clear` does not reload plugin config.
3. **block-secrets false positives.** 64 blocks across 15 days. About two thirds
   matched text inside heredocs or edits rather than any secret read: a `cp` of a
   `.tsx` file, PLAN.md rewrites that mention sops or `cert.pem`, espanso
   snippets, a resume README. One fix landed (`62f07df6`, `jq .key`). The rest
   of the pattern set still matches command text it should skip.
4. **Stale duplicate skill.** `skills/flutter-verify-loop/` (14 KB, 08-18) has
   the same description as the `flutter` shim, which points at
   `contexts/flutter.md` (updated 09-21). Either can trigger, and the old one
   loads outdated instructions. No Flutter work happened this month, so this is
   latent.
5. **The global gitignore drops project AGENTS.md.** `AGENTS.md` is on line 7 of
   the global excludes file. laritech-practice and tide-time-date keep their
   agent rules only on this machine. This came up 09-27, when the tutor rules
   would not have reached the laptop.

## Friction that is working as designed

- **context-mode redirects:** 43 blocked calls (34 curl/wget in Bash, 7
  WebFetch). Each costs one wasted tool call, and none caused a failure.
- **security-guidance plugin:** 440 headless review sessions (whats-up-doc 236,
  tscan-rs 92) about 212M tokens in all, running on `claude-opus-4-7`. They fire
  on trivial diffs too, such as a dependency bump or a test tweak. It is not
  broken, but it is the largest hidden cost in the window.

## Things that held up

- Startup context shrank: the median first-request context went from 34k tokens
  (week of 09-22) to 23k (week of 10-15).
- Only 7 compactions, across 4 sessions.
- Skill invocations were few and on target (dotfiles 10, plan-refute 7, tutor 7,
  handoff 6, grind 5). No calls named a missing skill.
- No user correction blamed a skill or context file apart from the learning
  style one above. "Stop, you stole my cursor" (09-30) came before the
  screen/focus rule existed, and it led to that rule.

## Not checked

Whether security-guidance findings changed any code. How cloud sessions are
configured. Codex and Pi usage.
