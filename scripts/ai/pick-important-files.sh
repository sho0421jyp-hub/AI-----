#!/bin/bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
mkdir -p .ai/context

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

# 1) 最近変更したファイルを優先
[ -f .ai/context/changed_files.txt ] && cat .ai/context/changed_files.txt >> "$TMP_FILE" || true

# 2) プロジェクトの重要ファイル候補
git ls-files | grep -E '(^README(\.md)?$|^docs/.*\.md$|^src/(main|app|index)\.|^app/|^main\.|^index\.|package\.json$|package-lock\.json$|pnpm-lock\.yaml$|yarn\.lock$|requirements\.txt$|pyproject\.toml$|Pipfile$|Dockerfile$|docker-compose\.ya?ml$|compose\.ya?ml$|Makefile$|tsconfig\.json$|vite\.config|next\.config|nuxt\.config|go\.mod$|Cargo\.toml$|Gemfile$)' >> "$TMP_FILE" || true

# 3) 重複削除して最大30件
awk 'NF && !seen[$0]++' "$TMP_FILE" | head -30 > .ai/context/key_files_list.txt

{
  echo "# Key Files"
  echo
  echo "AIが先に確認すべき重要ファイル一覧です。"
  echo
  if [ -s .ai/context/key_files_list.txt ]; then
    nl -w1 -s'. ' .ai/context/key_files_list.txt
  else
    echo "- 重要ファイル候補なし"
  fi
} > .ai/context/key_files.md
