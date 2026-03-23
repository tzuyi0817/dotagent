---
name: vue3-setup
description: Vue 3 `<script setup>` 元件開發規範與實作指南。涵蓋 Props、Emits、Pinia Store、Composable、v-model、Template Refs、defineExpose、defineSlots、watch/watchEffect 等慣用寫法。當使用者撰寫 Vue 3 元件、建立新頁面、定義 Props/Emits、使用 Pinia Store、或任何涉及 `<script setup>` 的開發工作時，都應啟用此 skill。即使使用者只是詢問 Vue 3 寫法建議，也請使用此 skill。
---

# Vue 3 `<script setup>` 開發規範

此 Skill 定義了 Vue 3 `<script setup>` 元件的完整開發規範。所有範例皆基於實務經驗，目的是避免常見陷阱並維持團隊一致性。

進階元件 API（defineExpose、defineSlots、defineOptions、Template Refs、watch/watchEffect、非同步處理、Style scoped）請參閱 `references/advanced-patterns.md`。

## 基礎規範

- **語法標準**：必須使用 `<script setup>` 與 Composition API。
- **響應式選擇**：優先使用 `ref()` 以保持型別推導與解構的穩定性。
- **狀態管理**：優先使用 Pinia 或 Vue Query（TanStack Query）。
- **顯式參數傳遞**：避免使用 `provide` 與 `inject` 進行隱式傳遞。
- **邏輯抽離**：複雜邏輯必須封裝為 Composables（`hooks/use*.ts`）。
- **元件命名與使用**：
  - **定義**：組件檔案與元件名稱使用 **PascalCase**（例如 `EformListWay.vue`）。
  - **模板使用**：在 Template 中呼叫元件時，必須使用 **kebab-case**（例如 `<eform-list-way />`）。
  - **閉合標籤**：優先使用自閉合標籤（Self-closing），除非該元件有 Slot 內容。

### `import type` 規範

型別導入必須使用 `import type` 語法，避免打包時殘留無用的 runtime import。這讓 bundler 能在 tree-shaking 階段安全移除型別相關的 import，減少最終產物大小：

```typescript
// ✅ 正確：型別使用 import type
import type { UserInfo, RoleType } from '@/types/user'
import type { FormInstance } from 'element-plus'

// ✅ 混合導入：runtime 值與型別分開
import { ElMessage } from 'element-plus'
import type { FormInstance } from 'element-plus'

// ❌ 錯誤：型別混在 runtime import 中
import { ElMessage, FormInstance } from 'element-plus'
```

### `<script setup>` 區塊排列順序

統一的排列順序讓團隊成員能快速定位程式碼，降低 code review 的認知負擔：

```vue
<script setup lang="ts">
// 1. 外部套件 imports
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'

// 2. 內部模組 imports
import UserCard from '@/components/UserCard.vue'
import { useUserStore } from '@/stores/user'
import { formatDate } from '@/utils/date'

// 3. 型別 imports
import type { UserInfo } from '@/types/user'

// 4. Props / Emits / Model 定義
interface Props {
  userId: string
}

interface Emits {
  select: [user: UserInfo]
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const keyword = defineModel<string>('keyword', { default: '' })

// 5. Store / Router / 外部 Composable
const userStore = useUserStore()
const router = useRouter()

// 6. 響應式狀態（ref / reactive）
const isLoading = ref(false)
const userList = ref<UserInfo[]>([])

// 7. Computed
const filteredUsers = computed(() =>
  userList.value.filter(u => u.name.includes(keyword.value))
)

// 8. Watch
watch(() => props.userId, (newId) => {
  fetchUser(newId)
})

// 9. Methods
function fetchUser(id: string) {
  // ...
}

// 10. Lifecycle Hooks
onMounted(() => {
  fetchUser(props.userId)
})
</script>
```

### `computed` 規範

`computed` 是純粹的衍生計算，其中不應包含副作用。Vue 會在依賴未變動時直接回傳快取值，如果 computed 內含副作用（API 呼叫、DOM 操作、mutation），這些副作用的執行時機會變得不可預測：

```typescript
// ✅ 正確：純粹計算，無副作用
const fullName = computed(() => `${firstName.value} ${lastName.value}`)
const isValid = computed(() => name.value.length > 0 && email.value.includes('@'))

// ❌ 錯誤：computed 中包含副作用
const userData = computed(() => {
  api.trackView(userId.value) // 副作用：API 呼叫
  return userStore.getUser(userId.value)
})
```

需要在值變化時執行副作用，應改用 `watch` 或 `watchEffect`（見 `references/advanced-patterns.md`）。

## Props 定義

使用 `defineProps` 搭配編譯時泛型，型別定義放在 `interface`：

```vue
<script setup lang="ts">
interface Props {
  /** 表單標題 */
  title: string
  /** 是否為唯讀模式 */
  readonly?: boolean
  /** 資料列表 */
  items: DataItem[]
}

const props = withDefaults(defineProps<Props>(), {
  readonly: false,
  items: () => [],
})
</script>
```

**注意事項：**
- 陣列與物件的預設值必須使用工廠函式 `() => []`，避免多個元件實例共享同一參考。
- 當 Props 僅在 template 中使用時，可省略 `const props =`，直接 `defineProps<Props>()`。
- **Template 中直接使用屬性名稱**：`<script setup>` 的 `defineProps` 會自動將所有 props 暴露到 template 作用域，不需要透過 `props.xxx` 存取，直接用屬性名稱即可。

```vue
<script setup lang="ts">
interface Props {
  title: string
  readonly?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  readonly: false,
})

// ✅ script 中需要透過 props.title 存取
console.log(props.title)
</script>

<template>
  <!-- ✅ template 中直接使用屬性名稱，不需要 props. 前綴 -->
  <h1>{{ title }}</h1>
  <span v-if="readonly">唯讀模式</span>
</template>
```

## Emits 定義

使用 `interface Emits` 搭配 tuple 語法定義事件型別，key 為事件名稱，value 為參數的 tuple 型別：

```vue
<script setup lang="ts">
interface Emits {
  /** 當關閉動畫開始時觸發 */
  close: []
  /** 當關閉動畫結束時觸發 */
  closed: []
  /** 當元件掛載完成時觸發，回傳元件高度 */
  mounted: [height: number]
  /** 當表單送出時觸發 */
  submit: [payload: FormData]
}

const emit = defineEmits<Emits>()
</script>
```

`update:` 開頭的事件不需要在 Emits 中定義，改用 `defineModel` 處理（見下方 v-model 章節）。

**為什麼用 tuple 語法而非 call signature `(e: 'xxx'): void`：**
- Vue 3.3+ 原生支援，語法更簡潔，不需要重複寫 `(e: '...', ...): void`。
- 事件名稱即為 key，閱讀時一目了然。
- 與 `interface Props` 保持對稱的物件結構風格。

## Pinia Store 使用

### 禁止使用 `storeToRefs`

`storeToRefs` 會對 store 中所有屬性建立 ref 追蹤，即使你只需要其中一兩個屬性，仍會為整個 store 建立響應式連結，造成不必要的性能開銷。直接透過 store 實例存取即可：

```vue
<script setup lang="ts">
// ✅ 正確：直接透過 store 實例存取
const configStore = useConfigStore()

// template 中使用 configStore.theme、configStore.locale
// script 中使用 configStore.updateTheme('dark')
</script>

<template>
  <div :class="configStore.theme">
    <span>{{ configStore.locale }}</span>
  </div>
</template>
```

```vue
<script setup lang="ts">
// ❌ 錯誤：storeToRefs 會對所有屬性建立追蹤，造成性能浪費
import { storeToRefs } from 'pinia'

const configStore = useConfigStore()
const { theme, locale } = storeToRefs(configStore)
</script>
```

### Store 的定義位置

根據使用範圍決定 store 的宣告位置：

```vue
<script setup lang="ts">
// ✅ 多處使用：定義在 setup 最外層
const userStore = useUserStore()

function handleLogin() {
  userStore.login(credentials)
}

function handleLogout() {
  userStore.logout()
}
</script>
```

```vue
<script setup lang="ts">
// ✅ 僅在單一函式中使用：定義在函式內部，縮小作用範圍
function submitOrder() {
  const orderStore = useOrderStore()
  orderStore.create(orderData)
}
</script>
```

背後的考量是作用範圍最小化原則（Principle of Least Scope）——變數的生命週期應與其使用範圍一致，避免不必要的全域狀態參考。

## v-model 雙向綁定

使用 `defineModel`（Vue 3.4+）取代手動的 Props + Emits `update:` 模式。`defineModel` 會自動宣告對應的 prop 與 `update:` 事件，大幅減少樣板程式碼。

### 單一 v-model

```vue
<script setup lang="ts">
const modelValue = defineModel<string>({ required: true })
</script>

<template>
  <input v-model="modelValue" />
</template>
```

### 帶預設值的 v-model

```vue
<script setup lang="ts">
const visible = defineModel<boolean>({ default: false })
</script>
```

### 多重 v-model

```vue
<script setup lang="ts">
const firstName = defineModel<string>('firstName', { required: true })
const lastName = defineModel<string>('lastName', { required: true })
</script>

<template>
  <input v-model="firstName" />
  <input v-model="lastName" />
</template>
```

父元件使用方式：

```vue
<template>
  <name-input v-model:first-name="first" v-model:last-name="last" />
</template>
```

### 搭配第三方元件

`defineModel` 回傳的是一個 ref，可直接傳給第三方元件的 `v-model`：

```vue
<script setup lang="ts">
const inputValue = defineModel<string>({ required: true })
</script>

<template>
  <el-input v-model="inputValue" />
</template>
```

## Composable 設計

Composable 是邏輯復用的核心單位，放置於 `hooks/` 目錄：

```typescript
// hooks/useCounter.ts
import { ref, computed } from 'vue'

interface UseCounterOptions {
  /** 初始值 */
  initialValue?: number
  /** 最小值 */
  min?: number
  /** 最大值 */
  max?: number
}

/**
 * 計數器邏輯
 *
 * @param options - 計數器設定物件
 * @returns 計數器狀態與操作方法
 */
export function useCounter(options: UseCounterOptions = {}) {
  const { initialValue = 0, min = -Infinity, max = Infinity } = options

  const count = ref(initialValue)
  const isMax = computed(() => count.value >= max)

  function increment() {
    if (count.value < max) {
      count.value++
    }
  }

  function decrement() {
    if (count.value > min) {
      count.value--
    }
  }

  function reset() {
    count.value = initialValue
  }

  return { count, isMax, increment, decrement, reset }
}
```

**設計要點：**
- 回傳物件（非陣列），讓使用端按需解構。
- 不需要定義 Return 型別，TypeScript 會自動推導回傳型別。
- 參數使用 Options 物件，方便日後擴充而不破壞介面。
- 副作用（事件監聽、Timer）必須在 `onUnmounted` 中清理。

## AI 執行自檢清單

撰寫 Vue 3 `<script setup>` 元件時，逐條確認：

1. [ ] 是否使用 `<script setup lang="ts">` 語法？
2. [ ] Props 是否透過 `interface Props` + `defineProps<Props>()` 定義？
3. [ ] Emits 是否透過 `interface Emits`（tuple 語法）+ `defineEmits<Emits>()` 定義？
4. [ ] v-model 是否使用 `defineModel` 而非手動 Props + `update:` emit？
5. [ ] 是否完全避免使用 `storeToRefs`？
6. [ ] Store 是否根據使用範圍選擇正確的定義位置？
7. [ ] Template 中的元件是否使用 kebab-case（`<my-component />`）？
8. [ ] Template 中使用 props 是否直接用屬性名稱（非 `props.xxx`）？
9. [ ] 響應式資料是否優先使用 `ref()` 宣告？
10. [ ] `computed` 是否為純粹計算，無副作用？
11. [ ] 型別導入是否使用 `import type`？
12. [ ] `<script setup>` 區塊是否遵循排列順序規範？
13. [ ] 複雜邏輯是否抽離為 Composable（`hooks/use*.ts`）？
14. [ ] 型別定義是否完整，無 `any` 使用？
15. [ ] JSDoc 是否使用繁體中文描述？
16. [ ] 需要暴露方法給父元件時，是否使用 `defineExpose`？（見 `references/advanced-patterns.md`）
