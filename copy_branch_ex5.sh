#!/bin/bash
set -e
set -x
set +H

branch=$(git rev-parse --abbrev-ref HEAD)
echo "Branch detected: $branch"

default_ex5="FullKaisaraEA.ex5"

# Use first argument as compiled_ex5 filename, or default if none provided
compiled_ex5="${1:-$default_ex5}"

if [ ! -f "./$compiled_ex5" ]; then
  echo "File not found: $compiled_ex5"
  exit 1
fi

mkdir -p "./$branch"

dest_file="${compiled_ex5%.*} $branch.ex5"

cp "./$compiled_ex5" "./$branch/$dest_file"

echo "Copied $compiled_ex5 to ./$branch/$dest_file"