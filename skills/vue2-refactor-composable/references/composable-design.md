# 規則目錄 — Composable 設計原則

## 規則 1：完全移除 `this`

IsUrgent: True
Category: Composable Design

### 說明

Composable 內禁止出現任何 `this`，所有狀態透過閉包直接存取。

### 範例

```js
// ❌ 轉換前
methods: {
  fetchData() {
    this.loading = true
    api.get(this.url).then(res => {
      this.data = res
      this.loading = false
    })
  }
}
```

```ts
// ✅ 轉換後
const loading = ref(false)
const data = ref<ResponseType | null>(null)

async function fetchData(url: string) {
  loading.value = true
  const res = await api.get(url)
  data.value = res
  loading.value = false
}
```

---

## 規則 2：外部傳入參數使用 `MaybeRef` + `toRef` 規格化

IsUrgent: True
Category: Composable Design

### 說明

Composable 接收的外部參數應設計為 `MaybeRef<T>`，內部以 `toRef` 統一為 Ref 以保持響應性。

### 範例

```ts
import { toRef } from 'vue'
import type { Ref } from 'vue'

type MaybeRef<T> = T | Ref<T>

/**
 * 分頁 Composable
 * @param pageSize - 每頁筆數（純值或 Ref）
 */
export function usePagination(pageSize: MaybeRef<number> = 10) {
  // toRef：若傳入純值則包裝為 Ref，若已為 Ref 則直接使用
  const normalizedPageSize = toRef(pageSize)
  const currentPage = ref(1)

  const offset = computed(() => (currentPage.value - 1) * normalizedPageSize.value)

  return { currentPage, offset }
}
```

---

## 規則 3：禁止使用 `provide` / `inject`

IsUrgent: True
Category: Composable Design

### 說明

Composable 內禁止使用 `provide` 與 `inject` 進行隱式依賴傳遞。所有依賴應透過參數顯式傳入或回傳值顯式傳出，以確保可追蹤性與可測試性。

### 範例

```ts
// ❌ 錯誤：隱式依賴
export function useTheme() {
  const theme = inject('theme')
  return { theme }
}

// ✅ 正確：透過參數顯式傳入
export function useTheme(theme: MaybeRef<'light' | 'dark'>) {
  const normalizedTheme = toRef(theme)
  const isDark = computed(() => normalizedTheme.value === 'dark')
  return { isDark }
}
```

---

## 規則 4：回傳 Plain Object（解構友善）

IsUrgent: True
Category: Composable Design

### 說明

Composable 必須回傳一個包含多個 `ref` / `computed` / `function` 的 Plain Object，禁止回傳陣列或單一值。

### 範例

```ts
// ❌ 錯誤：回傳陣列
export function useCounter() {
  const count = ref(0)
  return [count, () => count.value++]  // 解構不具語意
}

// ✅ 正確：回傳物件
export function useCounter() {
  const count = ref(0)
  function increment() { count.value++ }
  return { count, increment }
}
```

---

## 規則 7：禁止將 `emit` 和 `store` 直接傳入 Composable

IsUrgent: True
Category: Composable Design

### 說明

Composable 應保持純粹邏輯，不應耦合元件的 `emit` 或 Pinia/Vuex Store。改由 Composable 回傳狀態或 callback，由元件層自行呼叫 `emit` 和 `store`。

### 範例

```ts
// ❌ 錯誤：Composable 直接依賴 emit 和 store
export function useForm(emit: (event: string, ...args: unknown[]) => void, store: SomeStore) {
  function submit() {
    store.saveData(formData.value)
    emit('submitted')
  }
  return { submit }
}

// ✅ 正確：Composable 回傳結果，元件層自行處理
export function useForm() {
  const formData = ref<FormData>({ name: '', email: '' })
  const isValid = computed(() => formData.value.name !== '' && formData.value.email !== '')

  function getSubmitPayload() {
    return { ...formData.value }
  }

  return { formData, isValid, getSubmitPayload }
}
```

```vue
<!-- 元件層：由元件自行呼叫 emit 與 store -->
<script setup lang="ts">
import { useForm } from '@/hooks/useForm'
import { useSomeStore } from '@/stores/someStore'

const emit = defineEmits<{
  submitted: []
}>()
const store = useSomeStore()

const { formData, isValid, getSubmitPayload } = useForm()

function handleSubmit() {
  if (!isValid.value) return
  store.saveData(getSubmitPayload())
  emit('submitted')
}
</script>
```

---

## 規則 8：所有 Mixin 必須轉為 Composable

IsUrgent: True
Category: Composable Design

### 說明

專案中不應殘留任何 `mixins: [...]` 的使用。所有 Mixin 邏輯必須完整遷移為 Composable，並在相應元件中替換。

### 範例

```js
// ❌ 轉換前：元件使用 Mixin
export default {
  mixins: [formMixin, validationMixin],
  // ...
}
```

```vue
<!-- ✅ 轉換後：元件使用 Composable -->
<script setup lang="ts">
import { useForm } from '@/hooks/useForm'
import { useValidation } from '@/hooks/useValidation'

const { formData, resetForm } = useForm()
const { errors, validate } = useValidation()
</script>
```

---

## 規則 9：響應式資料優先使用 `ref`

Category: Composable Design

### 說明

宣告響應式資料時優先選擇 `ref()` 而非 `reactive()`，原因：
- `ref` 解構不會失去響應性
- `ref` 型別推導更穩定
- `ref` 在 Composable 回傳時語意更明確

### 範例

```ts
// ❌ 不推薦
const state = reactive({ count: 0, name: '' })

// ✅ 推薦
const count = ref(0)
const name = ref('')
```

---

## 核心工具：MaybeRef (Vue 2.7 兼容)

由於 Vue 2.7 不內建 `toValue`（Vue 3.3+），建議在專案中建立以下工具型別：

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
 * @param val - 純值或 Ref 包裝的值
 * @returns 解析後的實際值
 */
export function resolveRef<T>(val: MaybeRef<T>): T {
  return isRef(val) ? val.value : val
}
```

> **註**：Vue 2.7 已內建 `toRef` 可接受純值（會自動包裝為 Ref），優先使用 `toRef` 即可。`resolveRef` 用於需要取出原始值的場景。

新增、編輯或移除 Composable 設計規則時，請同步更新此檔案，確保目錄保持正確。
