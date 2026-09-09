# Vue 3 審查檢查點

給步驟 2「專案慣例」lens 用。這裡列的不是風格偏好，而是**違反後會造成使用者可見失效**的點——只有這種才配得到候選。

## 規範來源

回報慣例違規前，先逐字引用出處，順序為：專案的 `CLAUDE.md` / `AGENTS.md` → 專案 `rules/` → `vue3-setup` skill（含 `references/advanced-patterns.md`）。引不出原文就不回報。

`vue3-setup` 內已明列的規範（`hooks/` 目錄、kebab-case 呼叫、`import type`、`<script setup>` 區塊順序、Emits tuple 語法等）不在此重複；違反時直接引用該 skill 原文。

## 響應式遺失

Vue 的響應式靠 proxy 追蹤，斷掉不會報錯，只會**畫面不更新**——這是這裡最常見、也最難從 diff 看出的失效。

- 解構 `props`、`reactive()` 物件或 store 而取出原始值。`const { items } = props` 之後 `items` 就是快照，父層更新不再反映。
- 把 `ref` 傳進只接受原始值的函式，或在 template 外忘記 `.value`。
- `watch` 的來源給了 `foo.value` 而非 `foo` 或 `() => foo.value`：只在建立當下求值一次，之後不再觸發。
- 巢狀物件用 `watch` 但沒開 `deep`，或反過來對大型結構開了 `deep` 造成每次都全量比對。
- **`storeToRefs` 為團隊禁用**（見 `vue3-setup`）：它對 store 全部屬性建立追蹤。看到它時引用該規則。

## 生命週期與副作用

- Composable 或元件內註冊了事件監聽、`setInterval`、`IntersectionObserver`、WebSocket，但 `onUnmounted` 沒清理。後果是路由切換後回呼仍在跑，重複掛載會疊加。
- 元件被 `<keep-alive>` 包住時，`onMounted` 只跑一次；需要每次進入都執行的邏輯放 `onActivated`。diff 若把邏輯從 `onActivated` 移到 `onMounted`（或反之），追它的使用端確認。
- `onMounted` 中直接讀取 template ref 的子元件內部狀態，而該子元件是 `v-if` 或非同步元件——此時 ref 仍是 `null`。
- 在 Pinia 安裝前（模組頂層、router guard 外層）呼叫 `useXxxStore()`。

## Props、Emits 與 v-model

- 陣列或物件的 `withDefaults` 預設值沒用工廠函式，多個元件實例共享同一參考，改動一個會污染其他。
- 直接改動 props（`props.list.push(...)`）。物件與陣列 props 不是唯讀的，改得動，但父層不知情，狀態會分岔。
- `defineModel` 與手寫 `props` + `update:` emit 混用在同一個值上，造成更新互相覆蓋或迴圈。
- Emits 的 payload 型別與實際 `emit()` 傳的參數不符——TypeScript 只在有型別標註時擋得住。

## Template

- `v-for` 的 `key` 用陣列 index，而該列表會排序、篩選或中間插入。後果是 DOM 節點被複用到錯誤的資料上，輸入框內容與 checkbox 狀態錯位。
- `v-if` 與 `v-for` 在同一元素上（Vue 3 中 `v-if` 優先權較高，拿不到 `v-for` 的變數）。
- `v-html` 綁定了任何非硬編碼的內容：這是 XSS，一律列為阻擋。
- 事件處理器寫成 `@click="doSomething()"` 但 `doSomething` 回傳一個函式，或反過來該傳參卻寫成 `@click="doSomething"`。

## computed 與效能

- `computed` 內有副作用（改其他 ref、發 request、寫 storage）。它會被快取，也可能被跳過，執行次數不保證。
- `computed` 內每次回傳新物件或新陣列，而該值又被當成子元件 props 或 `watch` 來源，造成無窮更新。
- 大型列表在 template 中即時 `filter`/`sort`，每次無關的重繪都重算一次。

## 測試

- 新增或修改的分支沒有對應的 Vitest 測試。搭配步驟 6 的突變驗證：把該行刪掉或反向，測試若仍全綠，就在意見中要求補測試。
- 元件測試斷言的是內部狀態（`wrapper.vm.xxx`）而非使用者可見的輸出。專案測試工具鏈為 Vitest + Testing Library，斷言應走可存取的查詢。
