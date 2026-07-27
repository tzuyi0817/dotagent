---
name: e2e-testing
description: Playwright E2E 測試模式、Page Object Model、設定配置、CI/CD 整合、測試產物管理，以及不穩定測試的處理策略。
---

# E2E 測試模式

使用 Playwright 建構穩定、快速且易於維護的 E2E 測試套件。此檔收錄團隊慣例與不穩定測試處理策略；完整範例與模板（POM、playwright.config、CI workflow、測試報告、產物擷取）見 `references/templates.md`。

## 測試檔案組織

```
tests/
├── e2e/
│   ├── auth/          # login.spec.ts、logout.spec.ts、register.spec.ts
│   ├── features/      # 依功能劃分的測試
│   └── api/           # API 端點測試
├── fixtures/          # 共用測試資料與登入狀態
└── playwright.config.ts
```

## 團隊慣例

- **定位器**：一律優先 `[data-testid="..."]`，避免 CSS 選擇器與 XPath。
- **Page Object Model**：每個頁面建立 Page class，封裝定位器與操作，測試檔只描述情境。
- **等待條件而非時間**：使用 `waitForResponse()`、`waitFor({ state })`，禁止 `waitForTimeout()`。
- **測試相互獨立**：不共享狀態，每個測試可單獨執行。
- **產物路徑**：截圖、錄影、追蹤記錄統一輸出至 `artifacts/`。
- **追蹤設定**：`trace: 'on-first-retry'`，失敗才留截圖與錄影。

## 不穩定測試（Flaky）處理

發現不穩定測試時，先隔離並附上 issue 編號，再另行修復：

```typescript
test('不穩定：複雜搜尋', async ({ page }) => {
  test.fixme(true, '不穩定測試 - Issue #123')
})
```

識別方式：`npx playwright test <file> --repeat-each=10`

常見原因與對應修法：

- **競態條件** → 改用自動等待的 locator（`page.locator().click()` 而非 `page.click()`）
- **網路時序** → `waitForResponse()` 等待特定 API 回應
- **動畫時序** → `waitFor({ state: 'visible' })` 加 `waitForLoadState('networkidle')` 後再操作
