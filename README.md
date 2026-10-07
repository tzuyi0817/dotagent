# dotagent

個人 AI coding agent 工作環境的版本庫，作為所有機器設定的**唯一事實來源**。目前承載 Claude Code 的全域指引（`AGENTS.md`）、rules、skills、agents 與 settings；換電腦時 clone 本 repo 並執行 `./install.sh`，即以 symlink 方式部署至 `~/.claude/`。

## 新機器安裝

```bash
# 1. 安裝 Claude Code
# 2. clone 至固定位置（搬移 repo 後需重新執行 install.sh）
git clone <repo-url> ~/Documents/dotagent
# 3. 部署
cd ~/Documents/dotagent && ./install.sh
# 4. 重啟 Claude Code：plugins 會依 settings.json 的
#    enabledPlugins + extraKnownMarketplaces 自動安裝
```

### Windows 前置設定

部署全面依賴 symlink，Windows 在執行 `install.sh` 前需：

1. 開啟 Windows **開發人員模式**（或以系統管理員身分執行）。
2. `git config --global core.symlinks true` 後再 clone。
3. 在 Git Bash 中 `export MSYS=winsymlinks:nativestrict` 再執行 `./install.sh`。未設定時 `ln -s` 會靜默改為複製，`install.sh` 偵測到會中止。

## 部署對照

| repo | `~/.claude/` | 方式 |
|------|--------------|------|
| `AGENTS.md` | `CLAUDE.md` | symlink |
| `rules/` | `rules/` | symlink |
| `agents/` | `agents/` | symlink |
| `skills/vue3-setup` | `skills/vue3-setup` | symlink |
| `skills/vue2-refactor-composable` | `skills/vue2-refactor-composable` | symlink |
| `skills/coding-standards` | `skills/coding-standards` | symlink |
| `skills/e2e-testing` | `skills/e2e-testing` | symlink |
| `skills/unit-testing` | `skills/unit-testing` | symlink |
| `skills/review-pr` | `skills/review-pr` | symlink |
| `skills/address-review` | `skills/address-review` | symlink |
| `skills/writing-for-agents` | `skills/writing-for-agents` | symlink（外部來源，見下） |
| `skills/grill-me` | `skills/grill-me` | symlink（外部來源，見下） |
| `settings.json` | `settings.json` | 複製（見下） |
| `skills/frontend-code-review` | —（不全域部署） | Dify 專案特定（React Flow / workflowStore 規則），需要時複製至該專案的 `.claude/skills/` |

### 來自外部 repo 的 skills

`writing-for-agents`、`grill-me` 譯自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT）。來源路徑、對應的上游 commit、授權與翻譯備註都記在各自 `SKILL.md` 的 frontmatter `metadata` 裡，Claude Code 會忽略這個 key。內容為繁體中文（台灣）翻譯，段落結構、標題順序與格式模板與上游一一對應；英文引導詞（_tight_、_red_、_relentless_、no-op 等）保留原文。

唯一的結構變更是 `grill-me`：上游拆成 `grilling`（原語，給 `grill-with-docs`、`triage` 等 skill 呼叫）與 `grill-me`（給人輸入的入口）兩個，dotagent 沒有其他 skill 需要呼叫原語，因此合併為單一 skill，並維持 `disable-model-invocation: true`，只由 `/grill-me` 手動觸發，與 `review-pr`、`address-review` 一致。將來若有 skill 需要呼叫它，再把原語拆回 model-invoked。

更新時以 frontmatter 記錄的 commit 與上游新版 diff，再把差異移植進翻譯：

```bash
git clone https://github.com/mattpocock/skills.git /tmp/mp-skills
git -C /tmp/mp-skills diff <metadata.source.commit> HEAD -- skills/productivity/grilling skills/productivity/grill-me
```

### 全域指引為何本體是 AGENTS.md

指引內容寫在 `AGENTS.md`，供其他 coding agent 共用：

- **全域**：`~/.claude/CLAUDE.md` 直接 symlink 到 repo 的 `AGENTS.md`。Claude Code 只在專案層級（工作目錄與上層目錄）讀 `AGENTS.md`，不讀 `~/.claude/AGENTS.md`，因此部署目標必須維持 `CLAUDE.md` 檔名。
- **本 repo 的專案層級**：`CLAUDE.md` 是只含 `@AGENTS.md` 的一般檔案，而非 symlink。Windows 在未啟用 `core.symlinks` 時會把 symlink checkout 成一行純文字檔，import 檔則在任何平台都有效。

### settings.json 為何用複製而非 symlink

Claude Code 會在偏好變更（如 `/config`）時覆寫 `settings.json`，symlink 可能被一般檔案悄悄取代而失效，因此採複製部署。變更偏好後執行 `./sync.sh` 回收至 repo 並 commit。

也因為它是被就地改寫的，「現行版與 repo 不一致」是常態。`./install.sh` 在不一致時會備份現行版並蓋回 repo 版；只想修復 symlink 而不想動到當下設定時，用 `./install.sh --skip-settings`。

## 日常維護

- **修改 AGENTS.md / rules / skills / agents**：直接編輯 repo 檔案（symlink 即時生效）→ commit。
- **修改 settings.json**：在 Claude Code 內調整後執行 `./sync.sh` 回收 → commit。
- **搬移 repo 或 symlink 失效後**：`./install.sh --skip-settings`（僅重建 symlink）。
- `./sync.sh` 同時會檢查所有 symlink 是否完好，被覆寫時會提示重新執行 `./install.sh`。

## 不隨庫移植的項目

- **ECC continuous-learning 學習資料**（`~/.claude/homunculus/`）：機器本地資料，需要移植時使用 `/instinct-export` 輸出。
- **Claude Code 專案記憶**（`~/.claude/projects/*/memory/`）：由 harness 管理，不納入版控。
