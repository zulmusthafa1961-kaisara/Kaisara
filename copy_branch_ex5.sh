#!/bin/bash

# Arguments:
# $1 = branch name (e.g. kaisara-version-6)
# $2 = compiled .ex5 filename (e.g. FullKaisaraEA_rev6.ex5)

BRANCH_NAME="$1"
EX5_FILE="$2"
REPO_DIR="$(pwd)"

if [ -z "$BRANCH_NAME" ] || [ -z "$EX5_FILE" ]; then
    echo "Usage: $0 <branch-name> <compiled-ex5-file>"
    exit 1
fi

# Folder for this branch's compiled EA
BRANCH_DIR="$REPO_DIR/$BRANCH_NAME"

# Create branch folder if it doesn't exist
mkdir -p "$BRANCH_DIR"

# Copy the compiled .ex5 file to the branch folder
cp -v "$REPO_DIR/$EX5_FILE" "$BRANCH_DIR/"

echo "Copied $EX5_FILE to $BRANCH_DIR"

