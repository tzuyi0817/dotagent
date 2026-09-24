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
- React / Next.js → `frontend-patterns`、`coding-standards` skill（everything-claude-code plugin）
