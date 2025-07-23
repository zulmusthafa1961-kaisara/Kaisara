#!/bin/bash
set -e

branch=$(git rev-parse --abbrev-ref HEAD)
main_branch="main"

echo "🛠️  Current branch: $branch"
echo ""

# Step 1: Copy EX5 for testing
echo "➡️  Copying EX5 for testing..."
./copy_branch_ex5.sh "$1"

echo ""
echo "Please run your tests now (outside this script)."
while true; do
  read -p "Did the test pass? (y/n): " test_result
  case $test_result in
    y|Y)
      echo "✅ Test passed. Proceeding to merge and push..."
      break
      ;;
    n|N)
      echo "❌ Test failed. Please fix your code, compile, and test again."
      echo "You can run this script again after you have a passing test."
      exit 1
      ;;
    *)
      echo "Please answer y or n."
      ;;
  esac
done

# Step 2: Interactive merge and push
if [ "$branch" == "$main_branch" ]; then
  echo "⚠️  You are already on '$main_branch' branch. No merge needed."
  exit 0
fi

echo "➡️  Switching to '$main_branch' branch and pulling latest changes..."
git checkout $main_branch
git pull origin $main_branch

echo "➡️  Attempting to merge branch '$branch' into '$main_branch'..."
if git merge --no-ff $branch; then
  echo "✅ Merge successful!"
else
  echo "❌ Merge conflicts detected!"
  echo ""
  echo "📋 Conflicted files:"
  git diff --name-only --diff-filter=U
  echo ""

  while true; do
    echo "Choose how to proceed:"
    echo " 1) Show conflict resolution tips"
    echo " 2) Abort merge and reset $main_branch to remote"
    echo " 3) Exit and resolve conflicts manually later"
    read -p "Enter choice (1/2/3): " choice

    case $choice in
      1)
        echo ""
        echo "💡 Conflict resolution tips:"
        echo " - Open each conflicted file and look for markers <<<<<<<, =======, >>>>>>>"
        echo " - Edit to keep desired changes"
        echo " - Run: git add <file> for each resolved file"
        echo " - After all resolved, run: git commit"
        echo " - Then you can re-run this script or push manually"
        echo ""
        ;;
      2)
        echo "🔄 Aborting merge and resetting $main_branch to match origin/$main_branch..."
        git merge --abort || echo "No merge to abort."
        git reset --hard origin/$main_branch
        echo "Reset complete. You can fix conflicts in your feature branch now."
        exit 0
        ;;
      3)
        echo "Exiting. Please resolve conflicts manually later."
        exit 1
        ;;
      *)
        echo "Invalid choice. Please enter 1, 2, or 3."
        ;;
    esac
  done
fi

echo "➡️  Pushing merged changes to remote..."
git push origin $main_branch

echo "➡️  Returning to your working branch '$branch'..."
git checkout $branch

echo "🎉 Merge and push completed successfully! Have a great day! 🚀"
