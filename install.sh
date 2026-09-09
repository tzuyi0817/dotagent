#!/bin/bash
# 將此 repo 部署至 ~/.claude/
# - CLAUDE.md、rules、agents、指定 skills 以 symlink 部署（repo 為唯一事實來源）
# - settings.json 以複製部署（Claude Code 會覆寫此檔，symlink 有被一般檔案取代的風險）
# 可重複執行（idempotent），既有檔案會先備份。
#
# 用法: ./install.sh [--skip-settings]
set -euo pipefail

usage() {
  cat <<'EOF'
用法: ./install.sh [--skip-settings]

  --skip-settings  只部署 symlink，完全不碰 ~/.claude/settings.json。

    Claude Code 會就地改寫 settings.json（切模型、開關 plugin），所以「與 repo 不一致」
    是常態而非異常。不加旗標時，不一致就會備份現行版並蓋回 repo 版——只想更新
    skills/rules/agents 時用這個旗標，才不會順手把當下的設定退回去。
    要反向把現行設定回收進 repo，跑 sync.sh。
EOF
}

SKIP_SETTINGS=0
for arg in "$@"; do
  case "$arg" in
    --skip-settings) SKIP_SETTINGS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知參數: $arg" >&2; echo "" >&2; usage >&2; exit 2 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/install-$(date +%Y%m%d-%H%M%S)"

# 全域部署清單（skills/frontend-code-review 為 Dify 專案特定，不在此列，
# 需要時部署至該專案的 .claude/skills/）
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

backup() {
  mkdir -p "$BACKUP_DIR"
  mv "$1" "$BACKUP_DIR/"
  echo "備份: $1 -> $BACKUP_DIR/"
}

mkdir -p "$CLAUDE_DIR/skills"

for item in "${ITEMS[@]}"; do
  src="$REPO_DIR/$item"
  dst="$CLAUDE_DIR/$item"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "跳過（已連結）: $dst"
    continue
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup "$dst"
  fi
  ln -sfn "$src" "$dst"
  echo "連結: $dst -> $src"
done

# settings.json：複製部署
if [ "$SKIP_SETTINGS" -eq 1 ]; then
  echo "略過（--skip-settings）: settings.json"
elif [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "複製: settings.json"
elif diff -q "$CLAUDE_DIR/settings.json" "$REPO_DIR/settings.json" >/dev/null 2>&1; then
  echo "跳過（已一致）: settings.json"
else
  backup "$CLAUDE_DIR/settings.json"
  cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "複製: settings.json（現行版已備份，內容以 repo 版為準）"
fi

echo ""
echo "部署完成。備份（如有）位於: $BACKUP_DIR"
echo "提醒: repo 位置移動後需重新執行 install.sh。"
