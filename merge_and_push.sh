#!/bin/bash
set -e

branch=$(git rev-parse --abbrev-ref HEAD)
main_branch="main"

if [ "$branch" == "$main_branch" ]; then
  echo "Already on '$main_branch' branch. No merge needed."
  exit 0
fi

echo "Merging branch '$branch' into '$main_branch'..."

git checkout $main_branch
git pull origin $main_branch
git merge --no-ff $branch
git push origin $main_branch
git checkout $branch

echo "Merge and push completed successfully."