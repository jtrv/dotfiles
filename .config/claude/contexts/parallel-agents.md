# Parallel edit agents

When multiple agents edit one working tree concurrently, each brief must forbid `git stash`, `git reset`, `git checkout`/`git restore` outside the agent's assigned files, and any other tree-wide git state change — one agent stashing silently wipes the others' uncommitted edits. For a pristine baseline, use an isolated `git worktree`. Commit each agent's files as soon as it finishes; don't batch.
