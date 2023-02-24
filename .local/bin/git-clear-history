#!/bin/sh

default_branch=$(basename "$(git symbolic-ref --short refs/remotes/origin/HEAD)")

git checkout --orphan tmp
git add -A # Add all files and commit them
git commit
git branch -D "$default_branch"      # Deletes the default branch
git branch -m "$default_branch"      # Rename the current branch to default
git push -f origin "$default_branch" # Force push default branch to github
git gc --aggressive --prune=all      # remove the old files
