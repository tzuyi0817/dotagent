# Claude 個人設定移植庫

個人 Claude Code 偏好設定的版本庫，作為所有機器設定的**唯一事實來源**。換電腦時 clone 本 repo 並執行 `./install.sh`，即以 symlink 方式部署至 `~/.claude/`。

## 新機器安裝

```bash
# 1. 安裝 Claude Code
# 2. clone 至固定位置（搬移 repo 後需重新執行 install.sh）
git clone <repo-url> ~/Documents/claude
# 3. 部署
cd ~/Documents/claude && ./install.sh
# 4. 重啟 Claude Code：plugins 會依 settings.json 的
#    enabledPlugins + extraKnownMarketplaces 自動安裝
```

## 部署對照

| repo | `~/.claude/` | 方式 |
|------|--------------|------|
| `CLAUDE.md` | `CLAUDE.md` | symlink |
| `rules/` | `rules/` | symlink |
| `agents/` | `agents/` | symlink |
| `skills/vue3-setup` | `skills/vue3-setup` | symlink |
| `skills/vue2-refactor-composable` | `skills/vue2-refactor-composable` | symlink |
| `skills/coding-standards` | `skills/coding-standards` | symlink |
| `skills/e2e-testing` | `skills/e2e-testing` | symlink |
| `settings.json` | `settings.json` | 複製（見下） |
| `skills/frontend-code-review` | —（不全域部署） | Dify 專案特定（React Flow / workflowStore 規則），需要時複製至該專案的 `.claude/skills/` |

### settings.json 為何用複製而非 symlink

Claude Code 會在偏好變更（如 `/config`）時覆寫 `settings.json`，symlink 可能被一般檔案悄悄取代而失效，因此採複製部署。變更偏好後執行 `./sync.sh` 回收至 repo 並 commit。

## 日常維護

- **修改 CLAUDE.md / rules / skills / agents**：直接編輯 repo 檔案（symlink 即時生效）→ commit。
- **修改 settings.json**：在 Claude Code 內調整後執行 `./sync.sh` 回收 → commit。
- `./sync.sh` 同時會檢查所有 symlink 是否完好，被覆寫時會提示重新執行 `./install.sh`。

## 不隨庫移植的項目

- **ECC continuous-learning 學習資料**（`~/.claude/homunculus/`）：機器本地資料，需要移植時使用 `/instinct-export` 輸出。
- **Claude Code 專案記憶**（`~/.claude/projects/*/memory/`）：由 harness 管理，不納入版控。
