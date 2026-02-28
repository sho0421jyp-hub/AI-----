#!/bin/bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
mkdir -p .ai/context

NOW="$(date '+%Y-%m-%d %H:%M:%S')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

CHANGED_COUNT="$(grep -c . .ai/context/changed_files.txt 2>/dev/null || true)"
TODO_COUNT="$(grep -c . .ai/context/todo_hotspots.txt 2>/dev/null || true)"

FIRST_CHANGED="$(head -1 .ai/context/changed_files.txt 2>/dev/null || true)"
LAST_COMMIT="$(git log --oneline -1 2>/dev/null || true)"

{
  echo "# Latest Summary"
  echo
  echo "- generated_at: $NOW"
  echo "- branch: $BRANCH"
  echo "- last_commit: ${LAST_COMMIT:-none}"
  echo
  echo "## Summary"
  if [ "${CHANGED_COUNT:-0}" -eq 0 ]; then
    echo "直近コミット差分はまだありません。初回セットアップ直後、または比較可能な前コミットが未作成です。"
  else
    echo "直近コミットでは ${CHANGED_COUNT} 件のファイルが変更されました。主な変更対象は ${FIRST_CHANGED} です。差分統計は .ai/context/last_diff_stat.txt を確認してください。"
  fi
  echo
  echo "## Risk Check"
  if [ "${TODO_COUNT:-0}" -eq 0 ]; then
    echo "TODO / FIXME / HACK / BUG の検出はありません。"
  else
    echo "未解決メモが ${TODO_COUNT} 件検出されています。優先確認が必要です。"
  fi
  echo
  echo "## Next Action"
  if [ "${CHANGED_COUNT:-0}" -eq 0 ]; then
    echo "ファイルを1つ変更して commit し、差分追跡を開始してください。"
  else
    echo "まず .ai/context/last_diff.patch を確認し、その後に変更ファイル本体を読ませて修正方針を確定してください。"
  fi
} > .ai/context/summary_latest.md

{
  echo "## $NOW | $BRANCH"
  echo "- ${LAST_COMMIT:-none}"
  if [ "${CHANGED_COUNT:-0}" -eq 0 ]; then
    echo "- 差分なし"
  else
    echo "- 変更ファイル数: ${CHANGED_COUNT}"
    echo "- 主変更ファイル: ${FIRST_CHANGED}"
  fi
  if [ "${TODO_COUNT:-0}" -eq 0 ]; then
    echo "- TODO検出: なし"
  else
    echo "- TODO検出: ${TODO_COUNT}件"
  fi
  echo
} >> .ai/context/summary_history.md
