#!/bin/bash
set -e

branch=$(git rev-parse --abbrev-ref HEAD)
echo "Working on branch: $branch"

if [ -z "$1" ]; then
  echo "Usage: $0 <compiled_ex5_filename>"
  exit 1
fi

compiled_ex5="$1"

while true; do
  echo "Copying $compiled_ex5 for testing..."
  ./copy_branch_ex5.sh "$compiled_ex5"

  echo "Please run your tests now (outside this script)."
  read -p "Did the test pass? (y/n): " test_result

  case "$test_result" in
    y|Y)
      echo "Test passed. Running merge and push script..."
      ./merge_and_push.sh
      echo "Workflow complete. Exiting."
      exit 0
      ;;
    n|N)
      echo "Test failed. Choose an action:"
      echo "1) Revert all local changes to remote state"
      echo "2) Revert selected files"
      echo "3) Fix manually and rerun this script later"
      echo "4) Exit workflow"

      read -p "Enter choice (1-4): " choice

      case "$choice" in
        1)
          git reset --hard origin/"$branch"
          echo "All local changes reverted."
          ;;
        2)
          echo "Enter space-separated filenames to revert:"
          read files_to_revert
          git checkout -- $files_to_revert
          echo "Selected files reverted."
          ;;
        3)
          echo "Please fix your files now, then re-run this script."
          exit 0
          ;;
        4)
          echo "Exiting workflow without merging."
          exit 1
          ;;
        *)
          echo "Invalid choice, please enter 1, 2, 3, or 4."
          ;;
      esac
      ;;
    *)
      echo "Please answer with 'y' or 'n'."
      ;;
  esac
  
done