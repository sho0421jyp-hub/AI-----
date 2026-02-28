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
      TRACKED="$(git ls-files "$DIR_PATH" | head -100 || true)"
      if [ -n "$TRACKED" ]; then
        printf '%s\n' "$TRACKED" | sed 's/^/- /'
      else
        echo "- none"
      fi
    else
      echo "- none"
    fi
    echo
    echo "## Recently Changed In This Scope"
    if [ -f .ai/context/changed_files.txt ]; then
      CHANGED="$(grep "^$DIR_PATH" .ai/context/changed_files.txt 2>/dev/null || true)"
      if [ -n "$CHANGED" ]; then
        printf '%s\n' "$CHANGED" | sed 's/^/- /'
      else
        echo "- none"
      fi
    else
      echo "- none"
    fi
  } > "$OUT_FILE"
}

{
  echo "# Context: root"
  echo
  echo "## Root Files"
  ROOT_FILES="$(git ls-files | awk -F/ 'NF==1 {print $0}' | head -100 || true)"
  if [ -n "$ROOT_FILES" ]; then
    printf '%s\n' "$ROOT_FILES" | sed 's/^/- /'
  else
    echo "- none"
  fi
  echo
  echo "## Recently Changed Root Files"
  if [ -f .ai/context/changed_files.txt ]; then
    ROOT_CHANGED="$(awk -F/ 'NF==1 {print $0}' .ai/context/changed_files.txt 2>/dev/null || true)"
    if [ -n "$ROOT_CHANGED" ]; then
      printf '%s\n' "$ROOT_CHANGED" | sed 's/^/- /'
    else
      echo "- none"
    fi
  else
    echo "- none"
  fi
} > .ai/context/by_folder_root.md

write_section "src" "src/" ".ai/context/by_folder_src.md"
write_section "docs" "docs/" ".ai/context/by_folder_docs.md"
write_section "app" "app/" ".ai/context/by_folder_app.md"
