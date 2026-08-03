---
name: typescript
description: Tight verify loop for TypeScript/JavaScript repos on bun — oxfmt + oxlint (type-aware, --deny-warnings) + tsc --noEmit + bun test as one gate, zero warnings, no ignore-file baselines, plus a Playwright headless screenshot rig so web UI decisions come from pixels instead of imagination. Use whenever editing TypeScript or JavaScript in any package, before committing JS/TS work, when the lint/type gate is red, when setting up tooling for a new bun project, and for any web UI/UX/layout task. Also covers test discipline (junit output, coverage gating, mutation/property lanes) and the review discipline around it all.
---

Read `~/.config/claude/contexts/typescript.md` and follow it. That file is the single source of truth for this skill.
