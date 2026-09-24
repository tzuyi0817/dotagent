# 測試模板

## Setup 檔

`vitest.config.ts`：

```typescript
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: { provider: 'v8', reporter: ['text', 'html'] },
  },
})
```

`tests/setup.ts`：

```typescript
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/vue'
import { afterAll, afterEach, beforeAll, vi } from 'vitest'
import { server } from './mocks/server'

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => {
  // 未開啟 globals 時 Testing Library 不會自動 cleanup
  cleanup()
  server.resetHandlers()
  vi.restoreAllMocks()
  vi.useRealTimers()
})
afterAll(() => server.close())
```

## MSW（v2）

```typescript
// tests/mocks/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/users', () => HttpResponse.json({ success: true, data: [] })),
]

// tests/mocks/server.ts
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

單一測試覆寫回應：

```typescript
server.use(
  http.get('/api/users', () => HttpResponse.json({ success: false, error: '伺服器錯誤' }, { status: 500 })),
)
```

## Vue 元件

```typescript
import { render, screen } from '@testing-library/vue'
import userEvent from '@testing-library/user-event'
import { createTestingPinia } from '@pinia/testing'
import { describe, expect, it, vi } from 'vitest'
import UserForm from './UserForm.vue'
import { useUserStore } from '@/stores/user'

describe('UserForm', () => {
  it('當填寫名稱並送出時，呼叫儲存 action', async () => {
    const user = userEvent.setup()
    render(UserForm, {
      props: { title: '新增使用者' },
      global: { plugins: [createTestingPinia({ createSpy: vi.fn })] },
    })
    const store = useUserStore()

    await user.type(screen.getByLabelText('名稱'), '王小明')
    await user.click(screen.getByRole('button', { name: '送出' }))

    expect(store.save).toHaveBeenCalledWith({ name: '王小明' })
  })
})
```

## Vue Query

```typescript
import { render, screen, type RenderOptions } from '@testing-library/vue'
import { QueryClient, VueQueryPlugin } from '@tanstack/vue-query'
import type { Component } from 'vue'

function renderWithQuery(component: Component, options: RenderOptions = {}) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(component, {
    ...options,
    global: { ...options.global, plugins: [[VueQueryPlugin, { queryClient }]] },
  })
}

it('當 API 回傳資料時，顯示使用者列表', async () => {
  renderWithQuery(UserList)
  expect(await screen.findByText('王小明')).toBeInTheDocument()
})
```

## Composable

不依賴生命週期時直接呼叫：

```typescript
it('當呼叫 increment 時，count 加一', () => {
  const { count, increment } = useCounter({ initial: 1 })
  increment()
  expect(count.value).toBe(2)
})
```

依賴 `onMounted` / `onUnmounted` / `inject` 時，用 `withSetup` 掛載：

```typescript
// tests/utils/with-setup.ts
import { createApp, type App } from 'vue'

/** 在臨時 app 的 setup 中執行 Composable，讓生命週期 hook 與 inject 生效 */
export function withSetup<T>(composable: () => T, configure?: (app: App) => void) {
  let result!: T
  const app = createApp({
    setup() {
      result = composable()
      return () => null
    },
  })
  configure?.(app)
  app.mount(document.createElement('div'))
  return { result, app }
}

it('當元件卸載時，移除 resize 監聽', () => {
  const removeSpy = vi.spyOn(window, 'removeEventListener')
  const { app } = withSetup(() => useWindowSize())
  app.unmount()
  expect(removeSpy).toHaveBeenCalledWith('resize', expect.any(Function))
})
```

## Fake Timers

```typescript
it('當停止輸入 300ms 後，才觸發搜尋', async () => {
  vi.useFakeTimers()
  const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
  const { emitted } = render(SearchInput)

  await user.type(screen.getByRole('searchbox'), 'vue')
  expect(emitted().search).toBeUndefined()

  await vi.advanceTimersByTimeAsync(300)
  expect(emitted().search).toEqual([['vue']])
})
```

## React 差異

- 改用 `@testing-library/react` 的 `render` / `renderHook`；Hook 測試用 `renderHook`，不需 `withSetup`。
- Provider（QueryClientProvider 等）以 `wrapper` 選項注入。
