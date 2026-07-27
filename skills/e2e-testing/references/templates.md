# E2E 測試模板與程式碼範例

## Page Object Model 範例

```typescript
import { Page, Locator } from '@playwright/test'

export class ItemsPage {
  readonly page: Page
  readonly searchInput: Locator
  readonly itemCards: Locator

  constructor(page: Page) {
    this.page = page
    this.searchInput = page.locator('[data-testid="search-input"]')
    this.itemCards = page.locator('[data-testid="item-card"]')
  }

  async goto() {
    await this.page.goto('/items')
    await this.page.waitForLoadState('networkidle')
  }

  async search(query: string) {
    await this.searchInput.fill(query)
    await this.page.waitForResponse(resp => resp.url().includes('/api/search'))
    await this.page.waitForLoadState('networkidle')
  }

  async getItemCount() {
    return await this.itemCards.count()
  }
}
```

測試檔只描述情境：

```typescript
import { test, expect } from '@playwright/test'
import { ItemsPage } from '../../pages/ItemsPage'

test.describe('項目搜尋', () => {
  let itemsPage: ItemsPage

  test.beforeEach(async ({ page }) => {
    itemsPage = new ItemsPage(page)
    await itemsPage.goto()
  })

  test('應能依關鍵字搜尋', async ({ page }) => {
    await itemsPage.search('test')
    expect(await itemsPage.getItemCount()).toBeGreaterThan(0)
    await expect(itemsPage.itemCards.first()).toContainText(/test/i)
  })

  test('應能處理無搜尋結果的情境', async ({ page }) => {
    await itemsPage.search('xyznonexistent123')
    await expect(page.locator('[data-testid="no-results"]')).toBeVisible()
  })
})
```

## Playwright 設定配置

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['junit', { outputFile: 'playwright-results.xml' }],
    ['json', { outputFile: 'playwright-results.json' }]
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10000,
    navigationTimeout: 30000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
})
```

## 測試產物擷取

```typescript
// 截圖
await page.screenshot({ path: 'artifacts/after-login.png' })
await page.screenshot({ path: 'artifacts/full-page.png', fullPage: true })
await page.locator('[data-testid="chart"]').screenshot({ path: 'artifacts/chart.png' })

// 追蹤記錄（Traces）
await browser.startTracing(page, {
  path: 'artifacts/trace.json',
  screenshots: true,
  snapshots: true,
})
// ... 測試操作 ...
await browser.stopTracing()

// 錄影：在 playwright.config.ts 中設定
// use: { video: 'retain-on-failure' }
```

## CI/CD 整合

```yaml
# .github/workflows/e2e.yml
name: E2E 測試
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test
        env:
          BASE_URL: ${{ vars.STAGING_URL }}
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

## 測試報告範本

```markdown
# E2E 測試報告

**日期：** YYYY-MM-DD HH:MM
**耗時：** Xm Ys
**狀態：** 通過 / 失敗

## 摘要
- 總計：X | 通過：Y（Z%）| 失敗：A | 不穩定：B | 跳過：C

## 失敗測試

### 測試名稱
**檔案：** `tests/e2e/feature.spec.ts:45`
**錯誤：** 預期元素應為可見狀態
**截圖：** artifacts/failed.png
**建議修復：** [說明]

## 測試產物
- HTML 報告：playwright-report/index.html
- 截圖：artifacts/*.png
- 錄影：artifacts/videos/*.webm
- 追蹤記錄：artifacts/*.zip
```
