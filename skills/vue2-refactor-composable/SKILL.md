---
name: vue2-refactor-composable
description: 將 Vue 2 Options API（mixins/元件）重構為與 Vue 2.7 相容的可組合元件。重點在於將資料/計算屬性/方法轉換為響應式參考和函數，同時使用 MaybeRef/toRef 模式來確保與 Vue 2 的響應式系統和舊版橋接器的限制相容。
compatibility: Requires Vue 2.6+ with @vue/composition-api or Vue 2.7+
---

# Vue 2 Options to Adaptable Composable

此 Skill 專門用於將 Vue 2 的 Options API 邏輯（特別是 Mixins）重構為可複用的 Composables。針對 Vue 2.7 環境優化，確保在不破壞舊有組件的前提下，提供現代化的開發體驗。

---

## 執行步驟

當使用者要求執行此 Skill 時，請依照以下步驟進行：

1. **讀取原始碼**：先完整閱讀目標 Mixin 或元件檔案，理解其邏輯結構。
2. **分析副作用**：列出所有依賴的外部狀態、事件監聽、Store 呼叫等副作用。
3. **識別轉換項目**：依照下方映射表，逐一列出需要轉換的 Options。
4. **決定 Composable 命名**：以 `use` 為前綴，採用 camelCase（例如 `useFormValidation`）。
5. **產生轉換後的程式碼**：確保所有輸出皆有 `return`，且型別標註完整。
6. **說明 Trade-offs**：在輸出後簡短說明轉換的設計考量與潛在風險。

---

## 轉換映射表

### 狀態與資料

| Options API (Vue 2) | Composition API (Vue 2.7) | 注意事項 |
| :--- | :--- | :--- |
| `data()` | `ref()` / `reactive()` | 優先使用 `ref` 以利於解構。 |
| `computed` | `computed()` | 需導入 `{ computed } from 'vue'`。 |
| `methods` | `function` | 直接定義普通函數並回傳。 |
| `props` (傳入邏輯) | `MaybeRef<T>` | 允許 Composable 接收 Ref 或純值。 |

### 生命週期鉤子

| Options API (Vue 2) | Composition API (Vue 2.7) | 注意事項 |
| :--- | :--- | :--- |
| `beforeCreate` | 無對應（setup 本身即為此階段） | 直接寫在 `setup()` 頂層。 |
| `created` | 無對應（setup 本身即為此階段） | 直接寫在 `setup()` 頂層。 |
| `beforeMount` | `onBeforeMount()` | 需導入 `{ onBeforeMount } from 'vue'`。 |
| `mounted` | `onMounted()` | 需導入 `{ onMounted } from 'vue'`。 |
| `beforeUpdate` | `onBeforeUpdate()` | 需導入 `{ onBeforeUpdate } from 'vue'`。 |
| `updated` | `onUpdated()` | 需導入 `{ onUpdated } from 'vue'`。 |
| `beforeDestroy` | `onBeforeUnmount()` | Vue 2.7 已支援此別名。 |
| `destroyed` | `onUnmounted()` | Vue 2.7 已支援此別名。 |
| `activated` | `onActivated()` | 用於 `<keep-alive>` 場景。 |
| `deactivated` | `onDeactivated()` | 用於 `<keep-alive>` 場景。 |
| `errorCaptured` | `onErrorCaptured()` | 捕獲子組件錯誤。 |

### 監聽器

| Options API (Vue 2) | Composition API (Vue 2.7) | 注意事項 |
| :--- | :--- | :--- |
| `watch: { key(val) {} }` | `watch(source, callback)` | 支援 Ref、Getter 函數作為 source。 |
| `watch: { key: { handler, deep, immediate } }` | `watch(source, callback, { deep, immediate })` | 選項物件第三個參數。 |
| `this.$watch(...)` | `watch(...)` | 回傳 `stop` 函數可停止監聽。 |

### 依賴注入

| Options API (Vue 2) | Composition API (Vue 2.7) | 注意事項 |
| :--- | :--- | :--- |
| `provide()` | `provide(key, value)` | key 可使用 Symbol 強化型別安全。 |
| `inject` | `inject(key, defaultValue?)` | 建議搭配 InjectionKey 使用。 |

---

## 核心規格化工具 (Vue 2 兼容版)

由於 Vue 2.7 不內建 `toValue` (Vue 3.3+)，我們在設計 Composable 時需手動處理或是透過 `toRef` 轉換：

```ts
import { isRef, ref } from 'vue'
import type { Ref } from 'vue'

/**
 * Vue 2 兼容的 MaybeRef 類型。
 * 允許 Composable 同時接受純值或響應式 Ref，提升彈性。
 */
export type MaybeRef<T> = T | Ref<T>

/**
 * 手動實作類 toValue 邏輯，用於解析 MaybeRef 的實際值。
 * Vue 2.7 不支援 Getter 作為 Ref，因此不處理函數形式。
 * @param val - 純值或 Ref 包裝的值
 * @returns 解析後的實際值
 */
export function resolveRef<T>(val: MaybeRef<T>): T {
  return isRef(val) ? val.value : val
}

/**
 * 將 MaybeRef 統一正規化為 Ref，方便後續響應式操作。
 * @param val - 純值或 Ref 包裝的值
 * @returns Ref 包裝的值
 */
export function normalizeRef<T>(val: MaybeRef<T>): Ref<T> {
  return isRef(val) ? val : ref(val)
}
```

---

## 完整轉換範例

### 範例一：基礎 Mixin 轉換

**轉換前（Vue 2 Mixin）**

```js
// mixins/useCounter.js
export default {
  data() {
    return {
      count: 0,
      step: 1,
    }
  },
  computed: {
    doubleCount() {
      return this.count * 2
    },
  },
  methods: {
    increment() {
      this.count += this.step
    },
    decrement() {
      this.count -= this.step
    },
    reset() {
      this.count = 0
    },
  },
}
```

**轉換後（Vue 2.7 Composable）**

```ts
// hooks/useCounter.ts
import { ref, computed } from 'vue'
import type { Ref } from 'vue'
import type { MaybeRef } from '@/types/common'
import { normalizeRef } from '@/utils/refUtils'

/**
 * 計數器 Composable，支援自訂步進值。
 * @param initialStep - 每次增減的步進值（純值或 Ref）
 * @returns 計數器的狀態與操作方法
 */
export function useCounter(initialStep: MaybeRef<number> = 1) {
  const count = ref(0)
  const step = normalizeRef(initialStep)

  const doubleCount = computed(() => count.value * 2)

  function increment() {
    count.value += step.value
  }

  function decrement() {
    count.value -= step.value
  }

  function reset() {
    count.value = 0
  }

  return {
    count,
    doubleCount,
    increment,
    decrement,
    reset,
  }
}
```

---

### 範例二：含生命週期與監聽器的 Mixin

**轉換前（Vue 2 Mixin）**

```js
// mixins/windowResize.js
export default {
  data() {
    return {
      windowWidth: window.innerWidth,
      windowHeight: window.innerHeight,
    }
  },
  watch: {
    windowWidth(newVal) {
      console.log('寬度改變:', newVal)
    },
  },
  mounted() {
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleResize)
  },
  methods: {
    handleResize() {
      this.windowWidth = window.innerWidth
      this.windowHeight = window.innerHeight
    },
  },
}
```

**轉換後（Vue 2.7 Composable）**

```ts
// hooks/useWindowResize.ts
import { ref, watch, onMounted, onUnmounted } from 'vue'

/**
 * 監聽視窗大小變化的 Composable。
 * 自動在元件掛載時綁定事件，卸載時清除，避免記憶體洩漏。
 * @returns 視窗的寬度與高度響應式資料
 */
export function useWindowResize() {
  const windowWidth = ref(window.innerWidth)
  const windowHeight = ref(window.innerHeight)

  function handleResize() {
    windowWidth.value = window.innerWidth
    windowHeight.value = window.innerHeight
  }

  watch(windowWidth, (newVal) => {
    console.log('寬度改變:', newVal)
  })

  onMounted(() => {
    window.addEventListener('resize', handleResize)
  })

  onUnmounted(() => {
    window.removeEventListener('resize', handleResize)
  })

  return {
    windowWidth,
    windowHeight,
  }
}
```

---

### 範例三：含 Provide/Inject 的 Mixin

**轉換前（Vue 2 Mixin）**

```js
// mixins/themeProvider.js（父層使用）
export const ThemeProviderMixin = {
  provide() {
    return {
      theme: this.currentTheme,
    }
  },
  data() {
    return {
      currentTheme: 'light',
    }
  },
  methods: {
    toggleTheme() {
      this.currentTheme = this.currentTheme === 'light' ? 'dark' : 'light'
    },
  },
}

// mixins/themeConsumer.js（子層使用）
export const ThemeConsumerMixin = {
  inject: ['theme'],
}
```

**轉換後（Vue 2.7 Composable）**

```ts
// hooks/useTheme.ts
import { ref, provide, inject, readonly } from 'vue'
import type { Ref, InjectionKey } from 'vue'

/** 主題類型定義 */
type Theme = 'light' | 'dark'

/** 注入鍵，使用 Symbol 確保唯一性與型別安全 */
export const ThemeKey: InjectionKey<Readonly<Ref<Theme>>> = Symbol('theme')

/**
 * 主題提供者 Composable，供父層元件使用。
 * 透過 provide 向子孫元件提供唯讀的主題狀態。
 * @returns 當前主題狀態與切換方法
 */
export function useThemeProvider() {
  const currentTheme = ref<Theme>('light')

  // 提供唯讀 Ref，防止子層直接修改
  provide(ThemeKey, readonly(currentTheme))

  function toggleTheme() {
    currentTheme.value = currentTheme.value === 'light' ? 'dark' : 'light'
  }

  return {
    currentTheme,
    toggleTheme,
  }
}

/**
 * 主題消費者 Composable，供子層元件使用。
 * @returns 注入的主題狀態（唯讀）
 */
export function useThemeConsumer() {
  const theme = inject(ThemeKey)

  if (!theme) {
    throw new Error('useThemeConsumer 必須在 useThemeProvider 的子層元件中使用')
  }

  return { theme }
}
```

---

## 常見問題與注意事項

### `this` 的消失

Options API 中大量使用 `this` 存取狀態和方法。轉換後所有狀態透過閉包存取，無需 `this`。

```js
// 轉換前
methods: {
  fetchData() {
    this.loading = true
    api.get(this.url).then(res => {
      this.data = res
      this.loading = false
    })
  }
}

// 轉換後
const loading = ref(false)
const data = ref(null)

async function fetchData() {
  loading.value = true
  const res = await api.get(url.value)
  data.value = res
  loading.value = false
}
```

### Mixin 命名衝突

Mixin 的隱式合併是已知的維護難題。Composable 透過解構重命名解決此問題：

```ts
// 明確命名，避免衝突
const { count: cartCount } = useCartCounter()
const { count: viewCount } = useViewCounter()
```

### Vue 2.7 響應式限制

Vue 2 的響應式系統無法偵測以下操作，需使用 `set` 或替換整個物件：

```ts
import { set } from 'vue'

// 新增物件屬性（Vue 2 限制）
set(state, 'newKey', 'value')  // 正確
// state.newKey = 'value'      // 不響應（錯誤）

// 陣列索引賦值（Vue 2 限制）
set(list, index, newItem)      // 正確
// list[index] = newItem       // 不響應（錯誤）
```

---

## 輸出規範

產生 Composable 時，請遵循以下規範：

- **檔案位置**：`src/hooks/use{FeatureName}.ts`
- **函數命名**：`use` 前綴 + 功能描述，camelCase（例如 `useFormValidation`）
- **匯出方式**：具名匯出（Named Export），禁止預設匯出
- **型別標註**：參數與回傳值必須有完整的 TypeScript 型別，嚴禁使用 `any`
- **JSDoc**：所有公開函數必須撰寫 JSDoc，使用繁體中文描述
- **回傳結構**：統一回傳物件（非陣列），方便使用端按需解構
