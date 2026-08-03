---
name: go
description: Tight verify loop for Go repos — golangci-lint v2 as a single format+vet+lint step (curated enable list, nolintlint documented-ignore contract, no baselines in any costume), gotestsum with -race -shuffle -count=1 plus go-test-coverage thresholds, workspace fan-out for go.work multi-module repos, and nightly flake/fuzz/mutation lanes. Use whenever editing Go code, before committing Go work, when a golangci-lint or test gate is red, when setting up tooling for a new Go module or workspace. Also carries Go's named idioms (happy path left-aligned, accept interfaces return structs, zero value useful) and the shared review discipline.
---

Read `~/.config/claude/contexts/go.md` and follow it. That file is the single source of truth for this skill.
