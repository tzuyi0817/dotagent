# Git Workflow

- Commit message 採 Conventional Commits：`<type>: <description>`；type 為 feat / fix / refactor / docs / test / chore / perf / ci。
- Attribution 已全域停用（`~/.claude/settings.json`），commit 與 PR 不附加 AI 署名。
- 建立 PR 前以 `git diff <base>...HEAD` 檢視完整變更範圍（而非只看最後一筆 commit），摘要需附測試計畫；新分支以 `-u` 推送。
- Commit 前確認無 hardcoded secrets。
