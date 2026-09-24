---
name: unit-testing
description: Vitest + Testing Library 單元與元件測試團隊慣例。撰寫或修改 Vue / React 元件測試、Composable / Hook 測試、Pinia store 測試、API mock（MSW），或排查測試不穩定時使用。E2E 測試改用 e2e-testing skill。
---

# 單元與元件測試（Vitest + Testing Library）

此檔收錄團隊慣例與容易寫錯的地方；完整範例（setup 檔、元件 / Composable / Pinia / Vue Query / MSW 測試模板）見 `references/templates.md`。TDD 流程與覆蓋率目標見 rules `testing`，不在此重複。

## 測什麼

- **測行為而非實作**：從使用者視角斷言畫面與事件（看得到什麼、點了之後發生什麼），不斷言內部 `ref` 值、私有方法或元件實例。
- **分層**：純函式與 Composable 用單元測試；元件用 Testing Library 渲染；跨頁流程交給 E2E。
- 測試名稱使用繁體中文的行為描述（例如「當沒有結果時，顯示空狀態」）。

## 查詢元素

依序優先：`getByRole`（搭配 `name`）→ `getByLabelText` → `getByPlaceholderText` → `getByText` → `getByTestId`。

- 與 E2E 優先 `data-testid` 不同：元件測試以無障礙語意查詢，同時驗證 a11y。
- 斷言「不存在」用 `queryBy*`；等待非同步出現用 `findBy*`，不包 `waitFor` + `getBy*`。
- 互動一律用 `@testing-library/user-event`（`const user = userEvent.setup()`，`await user.click()`），不用 `fireEvent`。

## Mock 策略

- **API 一律用 MSW 攔截網路層**，不 `vi.mock` API 模組——測試才涵蓋到真正的 request 組裝與回應解析。`onUnhandledRequest: 'error'`，漏 mock 的請求直接失敗。
- `vi.mock` 只用於無法經網路層攔截的模組（第三方 SDK、瀏覽器 API 包裝）。注意 `vi.mock` 會被 hoist 到檔案頂端，工廠函式內不可引用外部變數（需用 `vi.hoisted`）。
- 每個測試後還原：`vi.restoreAllMocks()`、`server.resetHandlers()`，避免測試互相污染。

## Vue 專屬

- **Pinia**：元件測試用 `@pinia/testing` 的 `createTestingPinia({ createSpy: vi.fn })`，actions 預設被 stub，只驗證「有被呼叫」；要測 store 本身邏輯時，改在 store 單元測試中用 `setActivePinia(createPinia())`。
- **Composable**：不依賴生命週期或 `inject` 的直接呼叫；有依賴時用 `withSetup` helper 掛載到臨時 app 後測試，結束時 `app.unmount()` 觸發清理邏輯。
- **Vue Query**：每個測試建立新的 `QueryClient`，並關閉 `retry`，否則失敗案例會重試到逾時。
- 需要 `v-model` 時以 `props` 傳入 `modelValue`，並斷言 `emitted()['update:modelValue']`。

## 時間與非同步

- Timer 相關邏輯用 `vi.useFakeTimers()`，搭配 user-event 時需 `userEvent.setup({ advanceTimers: vi.advanceTimersByTime })`，否則互動會卡住。
- `afterEach` 中 `vi.useRealTimers()`。
- 禁止以固定 `setTimeout` 等待結果，改用 `findBy*` 或 `vi.waitFor`。

## 常用指令

- `vitest`（watch 模式，TDD 時使用）
- `vitest run --coverage`（CI 與提交前）
- `vitest run <path> -t "<測試名稱>"`（只跑單一測試）
