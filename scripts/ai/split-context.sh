#!/bin/bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
mkdir -p .ai/context

write_section () {
  DIR_LABEL="$1"
  DIR_PATH="$2"
  OUT_FILE="$3"

  {
    echo "# Context: $DIR_LABEL"
    echo
    echo "## Tracked Files"
    if [ -d "$DIR_PATH" ]; then
      git ls-files "$DIR_PATH" | sed 's/^/- /' | head -100
    else
      echo "- none"
    fi
    echo
    echo "## Recently Changed In This Scope"
    if [ -f .ai/context/changed_files.txt ]; then
      grep "^$DIR_PATH" .ai/context/changed_files.txt 2>/dev/null | sed 's/^/- /' || true
    else
      echo "- none"
    fi
  } > "$OUT_FILE"
}

{
  echo "# Context: root"
  echo
  echo "## Root Files"
  git ls-files | awk -F/ 'NF==1 {print "- " $0}' | head -100
  echo
  echo "## Recently Changed Root Files"
  if [ -f .ai/context/changed_files.txt ]; then
    awk -F/ 'NF==1 {print "- " $0}' .ai/context/changed_files.txt 2>/dev/null || true
  else
    echo "- none"
  fi
} > .ai/context/by_folder_root.md

write_section "src" "src/" ".ai/context/by_folder_src.md"
write_section "docs" "docs/" ".ai/context/by_folder_docs.md"
write_section "app" "app/" ".ai/context/by_folder_app.md"
