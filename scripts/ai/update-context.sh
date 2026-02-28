#!/bin/bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
mkdir -p .ai/context

NOW="$(date '+%Y-%m-%d %H:%M:%S')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

git ls-files > .ai/context/tracked_files.txt || true

{
  echo "# Repo Map"
  echo
  echo "- generated_at: $NOW"
  echo "- current_branch: $BRANCH"
  echo
  echo "## Top directories by tracked file count"
  git ls-files | awk -F/ 'NF>1 {print $1}' | sort | uniq -c | sort -rn | head -20 | awk '{print "- " $2 ": " $1 " files"}'
  echo
  echo "## Root files"
  git ls-files | awk -F/ 'NF==1 {print "- " $0}' | head -50
} > .ai/context/repo_map.md

{
  echo "# Recent Commits"
  echo
  git log --oneline -10 2>/dev/null || true
} > .ai/context/recent_commits.md

git status --short > .ai/context/worktree_status.txt || true
git diff --name-only > .ai/context/unstaged_files.txt || true
git diff --name-only --cached > .ai/context/staged_files.txt || true

if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  git diff --name-only HEAD~1 HEAD > .ai/context/changed_files.txt || true
  git diff --stat HEAD~1 HEAD > .ai/context/last_diff_stat.txt || true
  git diff HEAD~1 HEAD > .ai/context/last_diff.patch || true
else
  : > .ai/context/changed_files.txt
  : > .ai/context/last_diff_stat.txt
  : > .ai/context/last_diff.patch
fi

git grep -nE 'TODO|FIXME|HACK|BUG' | grep -v '^scripts/ai/update-context.sh:' > .ai/context/todo_hotspots.txt 2>/dev/null || true

{
  echo "# AI Context Bundle"
  echo
  echo "Generated: $NOW"
  echo "Branch: $BRANCH"
  echo
  echo "## Worktree Status"
  if [ -s .ai/context/worktree_status.txt ]; then
    cat .ai/context/worktree_status.txt
  else
    echo "- clean"
  fi
  echo
  echo "## Recently Changed Files (last commit)"
  if [ -s .ai/context/changed_files.txt ]; then
    sed 's/^/- /' .ai/context/changed_files.txt
  else
    echo "- none"
  fi
  echo
  echo "## Last Diff Stat"
  if [ -s .ai/context/last_diff_stat.txt ]; then
    cat .ai/context/last_diff_stat.txt
  else
    echo "- no previous commit yet"
  fi
  echo
  echo "## Top TODO/FIXME (first 50)"
  if [ -s .ai/context/todo_hotspots.txt ]; then
    head -50 .ai/context/todo_hotspots.txt
  else
    echo "- none"
  fi
} > .ai/context/context_bundle.md
