---
name: coding-standards
description: 適用於 TypeScript、JavaScript、React 與 Node.js 開發的通用程式碼規範、最佳實踐與設計模式。
---

# 程式碼規範與最佳實踐

適用於所有專案的通用程式碼規範。

## 啟用時機

- 開始一個新的專案或模組
- 審查程式碼的品質與可維護性
- 重構現有程式碼以符合規範
- 強制執行命名、格式或結構一致性
- 設定 linting、格式化或型別檢查規則
- 協助新成員了解程式碼規範

## 程式碼品質原則

### 1. 可讀性優先
- 程式碼被閱讀的次數遠多於被撰寫的次數
- 使用清晰的變數與函式名稱
- 優先使用自我說明的程式碼，而非依賴註解
- 保持一致的格式

### 2. KISS（保持簡單）
- 採用能解決問題的最簡方案
- 避免過度設計
- 不做過早的效能優化
- 易於理解 > 聰明的程式碼

### 3. DRY（避免重複）
- 將共用邏輯抽取為函式
- 建立可重用的元件
- 跨模組共享工具函式
- 避免複製貼上式的程式設計

### 4. YAGNI（你不會需要它）
- 不要在需求出現前就建構功能
- 避免投機性的通用化設計
- 只在必要時增加複雜度
- 從簡單開始，有需要再重構

## TypeScript/JavaScript 規範

### 變數命名

```typescript
// ✅ 正確：具描述性的名稱
const marketSearchQuery = 'election'
const isUserAuthenticated = true
const totalRevenue = 1000

// ❌ 錯誤：不清楚的名稱
const q = 'election'
const flag = true
const x = 1000
```

### 函式命名

```typescript
// ✅ 正確：動詞-名詞命名模式
async function fetchMarketData(marketId: string) { }
function calculateSimilarity(a: number[], b: number[]) { }
function isValidEmail(email: string): boolean { }

// ❌ 錯誤：不清楚或只有名詞
async function market(id: string) { }
function similarity(a, b) { }
function email(e) { }
```

### 不可變模式（重要）

```typescript
// ✅ 正確：永遠使用展開運算子
const updatedUser = {
  ...user,
  name: 'New Name'
}

const updatedArray = [...items, newItem]

// ❌ 錯誤：直接修改原資料
user.name = 'New Name'  // 錯誤
items.push(newItem)     // 錯誤
```

### 錯誤處理

```typescript
// ✅ 正確：完整的錯誤處理
async function fetchData(url: string) {
  try {
    const response = await fetch(url)

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('Fetch 失敗:', error)
    throw new Error('無法取得資料')
  }
}

// ❌ 錯誤：沒有錯誤處理
async function fetchData(url) {
  const response = await fetch(url)
  return response.json()
}
```

### Async/Await 最佳實踐

```typescript
// ✅ 正確：盡可能並行執行
const [users, markets, stats] = await Promise.all([
  fetchUsers(),
  fetchMarkets(),
  fetchStats()
])

// ❌ 錯誤：不必要的循序執行
const users = await fetchUsers()
const markets = await fetchMarkets()
const stats = await fetchStats()
```

### 型別安全

```typescript
// ✅ 正確：使用明確的型別
interface Market {
  id: string
  name: string
  status: 'active' | 'resolved' | 'closed'
  created_at: Date
}

function getMarket(id: string): Promise<Market> {
  // 實作內容
}

// ❌ 錯誤：使用 'any'
function getMarket(id: any): Promise<any> {
  // 實作內容
}
```

## React 最佳實踐

### 元件結構

```typescript
// ✅ 正確：有型別定義的函式元件
interface ButtonProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

export function Button({
  children,
  onClick,
  disabled = false,
  variant = 'primary'
}: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`btn btn-${variant}`}
    >
      {children}
    </button>
  )
}

// ❌ 錯誤：無型別、結構不清晰
export function Button(props) {
  return <button onClick={props.onClick}>{props.children}</button>
}
```

### Custom Hooks

```typescript
// ✅ 正確：可重用的 Custom Hook
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}

// 使用範例
const debouncedQuery = useDebounce(searchQuery, 500)
```

### 狀態管理

```typescript
// ✅ 正確：正確的狀態更新方式
const [count, setCount] = useState(0)

// 使用函式形式更新，避免依賴舊的 state 參考
setCount(prev => prev + 1)

// ❌ 錯誤：直接參考 state 變數
setCount(count + 1)  // 在非同步場景下可能讀到過時的值
```

### 條件渲染

```typescript
// ✅ 正確：清晰的條件渲染
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}

// ❌ 錯誤：巢狀三元地獄
{isLoading ? <Spinner /> : error ? <ErrorMessage error={error} /> : data ? <DataDisplay data={data} /> : null}
```

## API 設計規範

### REST API 慣例

```
GET    /api/markets              # 取得所有市場列表
GET    /api/markets/:id          # 取得特定市場
POST   /api/markets              # 建立新市場
PUT    /api/markets/:id          # 更新市場（完整替換）
PATCH  /api/markets/:id          # 更新市場（部分更新）
DELETE /api/markets/:id          # 刪除市場

# 使用查詢參數進行篩選
GET /api/markets?status=active&limit=10&offset=0
```

### 回應格式

```typescript
// ✅ 正確：一致的回應結構
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  meta?: {
    total: number
    page: number
    limit: number
  }
}

// 成功回應
return NextResponse.json({
  success: true,
  data: markets,
  meta: { total: 100, page: 1, limit: 10 }
})

// 錯誤回應
return NextResponse.json({
  success: false,
  error: '無效的請求'
}, { status: 400 })
```

### 輸入驗證

```typescript
import { z } from 'zod'

// ✅ 正確：使用 Schema 驗證
const CreateMarketSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().min(1).max(2000),
  endDate: z.string().datetime(),
  categories: z.array(z.string()).min(1)
})

export async function POST(request: Request) {
  const body = await request.json()

  try {
    const validated = CreateMarketSchema.parse(body)
    // 使用驗證後的資料繼續處理
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({
        success: false,
        error: '驗證失敗',
        details: error.errors
      }, { status: 400 })
    }
  }
}
```

## 檔案組織

### 專案結構

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # API 路由
│   ├── markets/           # 市場頁面
│   └── (auth)/           # 驗證頁面（路由群組）
├── components/            # React 元件
│   ├── ui/               # 通用 UI 元件
│   ├── forms/            # 表單元件
│   └── layouts/          # 版面元件
├── hooks/                # Custom React Hooks
├── lib/                  # 工具函式與設定
│   ├── api/             # API 客戶端
│   ├── utils/           # 輔助函式
│   └── constants/       # 常數
├── types/                # TypeScript 型別定義
└── styles/              # 全域樣式
```

### 檔案命名

```
components/Button.tsx          # 元件使用 PascalCase
hooks/use-auth.ts              # Hook 使用 KebabCase 並加上 'use' 前綴
lib/format-date.ts             # 工具函式使用 KebabCase
types/market.types.ts         # 型別定義使用 KebabCase 並加上 .types 後綴
```

## 註解與文件

### 何時撰寫註解

```typescript
// ✅ 正確：說明「為什麼」，而非「做什麼」
// 使用指數退避策略，避免在服務中斷時對 API 造成過大壓力
const delay = Math.min(1000 * Math.pow(2, retryCount), 30000)

// 此處刻意使用 mutation，以提升大型陣列的效能
items.push(newItem)

// ❌ 錯誤：說明顯而易見的事情
// 將計數器加 1
count++

// 將名稱設定為使用者的名稱
name = user.name
```

### 公開 API 的 JSDoc

```typescript
/**
 * 使用語意相似度搜尋市場。
 *
 * @param query - 自然語言搜尋字串
 * @param limit - 最大回傳筆數（預設：10）
 * @returns 依相似度分數排序的市場陣列
 * @throws {Error} 若 OpenAI API 失敗或 Redis 無法連線時拋出
 *
 * @example
 * ```typescript
 * const results = await searchMarkets('election', 5)
 * console.log(results[0].name) // "Trump vs Biden"
 * ```
 */
export async function searchMarkets(
  query: string,
  limit: number = 10
): Promise<Market[]> {
  // 實作內容
}
```

## 效能最佳實踐

### Memoization

```typescript
import { useMemo, useCallback } from 'react'

// ✅ 正確：對高成本的計算進行 memoize
const sortedMarkets = useMemo(() => {
  return markets.sort((a, b) => b.volume - a.volume)
}, [markets])

// ✅ 正確：對 callback 進行 memoize
const handleSearch = useCallback((query: string) => {
  setSearchQuery(query)
}, [])
```

### 延遲載入

```typescript
import { lazy, Suspense } from 'react'

// ✅ 正確：延遲載入較重的元件
const HeavyChart = lazy(() => import('./HeavyChart'))

export function Dashboard() {
  return (
    <Suspense fallback={<Spinner />}>
      <HeavyChart />
    </Suspense>
  )
}
```

### 資料庫查詢

```typescript
// ✅ 正確：只查詢需要的欄位
const { data } = await supabase
  .from('markets')
  .select('id, name, status')
  .limit(10)

// ❌ 錯誤：查詢所有欄位
const { data } = await supabase
  .from('markets')
  .select('*')
```

## 測試規範

### 測試結構（AAA 模式）

```typescript
test('正確計算相似度', () => {
  // Arrange（準備）
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act（執行）
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert（驗證）
  expect(similarity).toBe(0)
})
```

### 測試命名

```typescript
// ✅ 正確：具描述性的測試名稱
test('當沒有市場符合查詢時，回傳空陣列', () => { })
test('當缺少 OpenAI API 金鑰時，拋出錯誤', () => { })
test('當 Redis 無法連線時，退回使用子字串搜尋', () => { })

// ❌ 錯誤：模糊的測試名稱
test('works', () => { })
test('test search', () => { })
```

## 程式碼異味偵測

留意以下反模式：

### 1. 過長的函式
```typescript
// ❌ 錯誤：函式超過 50 行
function processMarketData() {
  // 100 行程式碼
}

// ✅ 正確：拆分為較小的函式
function processMarketData() {
  const validated = validateData()
  const transformed = transformData(validated)
  return saveData(transformed)
}
```

### 2. 過深的巢狀結構
```typescript
// ❌ 錯誤：5 層以上的巢狀
if (user) {
  if (user.isAdmin) {
    if (market) {
      if (market.isActive) {
        if (hasPermission) {
          // 做某些事
        }
      }
    }
  }
}

// ✅ 正確：提前返回（Early Return）
if (!user) return
if (!user.isAdmin) return
if (!market) return
if (!market.isActive) return
if (!hasPermission) return

// 做某些事
```

### 3. 魔術數字
```typescript
// ❌ 錯誤：無法解釋的數字
if (retryCount > 3) { }
setTimeout(callback, 500)

// ✅ 正確：使用具名常數
const MAX_RETRIES = 3
const DEBOUNCE_DELAY_MS = 500

if (retryCount > MAX_RETRIES) { }
setTimeout(callback, DEBOUNCE_DELAY_MS)
```

**謹記**：程式碼品質沒有妥協的空間。清晰、可維護的程式碼能加速開發速度，並讓重構更有信心。
