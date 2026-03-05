---
name: vue2-refactor-composable
description: 將 Vue 2 Options API（mixins/元件）重構為與 Vue 2.7 相容的 Composable 與 `<script setup>` 元件。涵蓋 Mixin 抽離、this 移除、MaybeRef 參數設計、emit/store 解耦、副作用清理、JSX 轉 template 等完整流程。
compatibility: Requires Vue 2.6+ with @vue/composition-api or Vue 2.7+
---

# Vue 2 Options to Adaptable Composable

此 Skill 專門用於將 Vue 2 的 Options API 邏輯（特別是 Mixins）重構為可複用的 Composables，並將元件遷移至 `<script setup>` 語法。針對 Vue 2.7 環境優化，確保在不破壞舊有組件的前提下，提供現代化的開發體驗。

## 規則清單

請參閱 [references/composable-design.md](references/composable-design.md)、[references/side-effects.md](references/side-effects.md)、[references/component-migration.md](references/component-migration.md)，這些檔案依分類列出了完整的 11 條強制規則，視為必須遵守的規範依據。

## 執行步驟

當使用者要求執行此 Skill 時，請依照以下步驟進行：

1. **讀取原始碼**：完整閱讀目標 Mixin 與使用該 Mixin 的元件檔案，理解邏輯結構與依賴關係。
2. **分析副作用**：列出所有 DOM 事件監聽、Timer、外部 API 呼叫等副作用，確認清理策略。
3. **識別耦合點**：標記元件中 `emit`、`store`、`provide/inject` 的使用處，設計解耦方案。
4. **抽離 Composable**：將 Mixin 邏輯轉為 Composable，遵循下方核心規則。
5. **改寫元件**：將元件遷移至 `<script setup>` 語法，JSX 轉為 `<template>`。
6. **執行自檢清單**：逐條確認 11 項規則全部通過。
7. **說明 Trade-offs**：簡短說明轉換的設計考量與潛在風險。

## 輸出規範

產生 Composable 時，請遵循以下規範：

- **檔案位置**：`src/hooks/use{FeatureName}.ts`
- **函數命名**：`use` 前綴 + 功能描述，camelCase（例如 `useFormValidation`）
- **匯出方式**：具名匯出（Named Export），禁止預設匯出
- **型別標註**：參數與回傳值必須有完整的 TypeScript 型別，嚴禁使用 `any`
- **JSDoc**：所有公開函數必須撰寫 JSDoc，使用繁體中文描述
- **回傳結構**：統一回傳物件（非陣列），方便使用端按需解構

## AI 執行自檢清單

在輸出重構程式碼前，請逐條確認：

1. [ ] 是否完全移除了 `this`？
2. [ ] 是否對所有外部傳入參數使用了 `MaybeRef` 並透過 `toRef` 規格化？
3. [ ] 是否避免了使用 `provide/inject`？
4. [ ] 回傳的是否為一個包含多個 `ref` 的 Plain Object（確保解構友善）？
5. [ ] 所有的副作用（如 DOM 事件、Timer）是否都在 `onUnmounted` 中清理？
6. [ ] `props` 傳入 Composable 時，是否使用 `toRef(props, 'key')` 轉換？
7. [ ] 是否避免了把 `emit` 和 `store` 直接傳進 Composable？
8. [ ] 所有的 `mixin` 是否已遷移為 Composable？
9. [ ] 響應式資料是否優先使用 `ref` 宣告？
10. [ ] 元件是否使用 `<script setup>` 語法？
11. [ ] 所有的 `jsx` 語法是否已轉換成 `<template>`？
