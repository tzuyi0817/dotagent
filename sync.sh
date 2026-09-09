#!/bin/bash
# 回收 ~/.claude 的 settings.json 變更至 repo，並檢查 symlink 部署是否完好。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# settings.json 回收
if ! diff -q "$CLAUDE_DIR/settings.json" "$REPO_DIR/settings.json" >/dev/null 2>&1; then
  cp "$CLAUDE_DIR/settings.json" "$REPO_DIR/settings.json"
  echo "已回收 settings.json，請以 git diff 檢視變更後 commit。"
else
  echo "settings.json 無變更。"
fi

# symlink 完整性檢查（與 install.sh 的部署清單一致）
ITEMS=(
  "CLAUDE.md"
  "rules"
  "agents"
  "skills/vue3-setup"
  "skills/vue2-refactor-composable"
  "skills/coding-standards"
  "skills/e2e-testing"
  "skills/review-pr"
)

broken=0
for item in "${ITEMS[@]}"; do
  dst="$CLAUDE_DIR/$item"
  if [ ! -L "$dst" ] || [ "$(readlink "$dst")" != "$REPO_DIR/$item" ]; then
    echo "警告: $dst 不是指向 repo 的 symlink（可能被覆寫），請重新執行 install.sh。"
    broken=1
  fi
done
[ "$broken" -eq 0 ] && echo "所有 symlink 完好。"
