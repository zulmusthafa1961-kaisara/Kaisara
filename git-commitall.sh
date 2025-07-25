#!/bin/bash
# git-commitall.sh
# Usage: git-commitall.sh "Your commit message"

if [ -z "$1" ]; then
  echo "Error: Commit message is required."
  echo "Usage: git-commitall.sh \"Your commit message\""
  exit 1
fi

# Get current branch name
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Error: Not a git repository or no git repo found."
  exit 1
fi

echo "Current branch: $branch"

# Stage all changes (tracked and untracked)
git add -A

# Commit with user message
git commit -m "$1"
if [ $? -eq 0 ]; then
  echo "Changes committed successfully on branch $branch."
else
  echo "No changes to commit."
fi

