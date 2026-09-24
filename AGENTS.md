# 全域指引

## 溝通偏好

- 始終使用繁體中文（台灣）溝通。
- 提供程式碼後，簡短說明設計背後的考量與取捨（Trade-offs）。

## 技術背景

資深前端工程師，主力為 Vue 3 + TypeScript monorepo，偶爾使用 React / Next.js 開發。

## 通用慣例

- **JSDoc 與註解一律使用繁體中文（台灣）**。
- 新功能採 **Feature-based** 目錄結構（例如 `features/auth/*`）；既有專案以現況為準。
- 前端測試工具鏈為 **Vitest + Testing Library**。

## 技術規範（漸進式揭露）

框架與領域的細節規範以 skills 承載，需要時載入，不在此重複：

- Vue 3 → `vue3-setup` skill
- React / Next.js → 本地 `coding-standards` skill（團隊決策）；通用 patterns 參考 `everything-claude-code:frontend-patterns`
- 單元 / 元件測試 → `unit-testing` skill；E2E → `e2e-testing` skill

本地 agents / skills 與 everything-claude-code plugin 同名時（`code-reviewer`、`e2e-runner`、`refactor-cleaner`、`coding-standards`、`e2e-testing`），一律使用本地版（無 `everything-claude-code:` 前綴者）。
