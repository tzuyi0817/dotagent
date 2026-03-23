# 進階元件 API 與模式

此文件涵蓋非每個元件都需要、但在特定場景下不可或缺的 Vue 3 `<script setup>` 進階用法。

## 目錄

- [進階元件 API 與模式](#進階元件-api-與模式)
  - [目錄](#目錄)
  - [defineExpose](#defineexpose)
  - [defineSlots](#defineslots)
  - [defineOptions](#defineoptions)
  - [Template Refs](#template-refs)
  - [watch vs watchEffect](#watch-vs-watcheffect)
    - [`watch` — 明確指定監聽目標](#watch--明確指定監聽目標)
    - [`watchEffect` — 自動追蹤依賴](#watcheffect--自動追蹤依賴)
    - [選擇指南](#選擇指南)
    - [清理副作用](#清理副作用)
  - [非同步處理](#非同步處理)
  - [Style scoped 規範](#style-scoped-規範)
    - [預設使用 `<style scoped>`](#預設使用-style-scoped)
    - [CSS Modules 的使用時機](#css-modules-的使用時機)
    - [選擇指南](#選擇指南-1)

---

## defineExpose

`<script setup>` 的元件預設不會暴露任何屬性或方法給父元件。當父元件需要透過 ref 呼叫子元件方法時，必須使用 `defineExpose` 明確宣告要暴露的介面，否則父元件拿到的會是空物件：

```vue
<!-- ChildForm.vue -->
<script setup lang="ts">
import { ref } from 'vue'

const formData = ref({ name: '', email: '' })

/** 驗證表單，回傳是否通過 */
function validate(): boolean {
  return formData.value.name.length > 0
}

/** 重置表單至初始狀態 */
function reset() {
  formData.value = { name: '', email: '' }
}

// 只暴露必要的方法，內部狀態保持封裝
defineExpose({ validate, reset })
</script>
```

父元件使用方式（搭配 `useTemplateRef`）：

```vue
<script setup lang="ts">
import { useTemplateRef } from 'vue'
import ChildForm from './ChildForm.vue'

const formRef = useTemplateRef('formRef')

function handleSubmit() {
  if (formRef.value?.validate()) {
    // 驗證通過，送出表單
  }
}
</script>

<template>
  <child-form ref="formRef" />
  <button @click="handleSubmit">送出</button>
</template>
```

**設計原則：** 只暴露父元件真正需要的方法，遵循最小介面原則。內部的響應式狀態（如 `formData`）不應暴露，保持元件封裝性。

---

## defineSlots

`defineSlots`（Vue 3.3+）為 Slot 提供型別定義，與 Props/Emits 的 interface 風格保持一致。有了型別定義，父元件在傳入 slot 內容時可以獲得 IDE 自動補全與型別檢查：

```vue
<script setup lang="ts">
interface Slots {
  /** 預設插槽，接收資料項目 */
  default: (props: { item: DataItem; index: number }) => void
  /** 表頭插槽 */
  header: (props: { title: string }) => void
  /** 空狀態插槽，無參數 */
  empty: () => void
}

defineSlots<Slots>()
</script>

<template>
  <div class="list">
    <div class="list__header">
      <slot name="header" :title="listTitle" />
    </div>

    <template v-if="items.length > 0">
      <div v-for="(item, index) in items" :key="item.id" class="list__item">
        <slot :item="item" :index="index" />
      </div>
    </template>

    <div v-else class="list__empty">
      <slot name="empty" />
    </div>
  </div>
</template>
```

**何時需要 `defineSlots`：**
- 元件有 scoped slot（需要傳遞參數給父元件的插槽）。
- 作為公共元件或跨團隊使用的元件，需要明確的插槽契約。
- 簡單的無參數 slot（如 `<slot />`）可以不定義，但有 scoped slot 時建議定義。

---

## defineOptions

`defineOptions`（Vue 3.3+）用於設定無法在 `<script setup>` 中直接宣告的元件選項，取代額外的 `<script>` 區塊，保持單一 script 區塊的簡潔性：

```vue
<script setup lang="ts">
// 停用 attribute 繼承，適用於需要手動分配 attrs 的 wrapper 元件
defineOptions({
  inheritAttrs: false,
})

import { useAttrs } from 'vue'

const attrs = useAttrs()
</script>

<template>
  <label class="form-field">
    <span class="form-field__label">{{ label }}</span>
    <input v-bind="attrs" class="form-field__input" />
  </label>
</template>
```

**常見使用場景：**
- `inheritAttrs: false`：wrapper 元件需要手動控制 attrs 分配位置。
- `name: 'MyComponent'`：遞迴元件需要明確的元件名稱、或 DevTools 中需要自訂顯示名稱。

---

## Template Refs

使用 `useTemplateRef`（Vue 3.5+）取得模板中的元素或元件參考，透過字串 key 對應 template 中的 `ref` 屬性：

```vue
<script setup lang="ts">
import { useTemplateRef, onMounted } from 'vue'

/** 輸入框的 DOM 參考 */
const inputRef = useTemplateRef('inputRef')

onMounted(() => {
  inputRef.value?.focus()
})
</script>

<template>
  <input ref="inputRef" />
</template>
```

元件 Ref 的型別取用：

```vue
<script setup lang="ts">
import { useTemplateRef } from 'vue'
import MyForm from './MyForm.vue'

const formRef = useTemplateRef('formRef')

function validate() {
  formRef.value?.validate()
}
</script>

<template>
  <my-form ref="formRef" />
</template>
```

**為什麼用 `useTemplateRef` 而非 `ref(null)`：**
- 語意更明確，一看就知道是模板參考而非響應式資料。
- 變數名稱與 template 的 `ref` 字串解耦，重新命名變數不會影響 template。

---

## watch vs watchEffect

兩者都用於追蹤響應式資料變化並執行副作用，但適用場景不同：

### `watch` — 明確指定監聽目標

適合需要知道「新值 vs 舊值」或只想監聽特定來源的場景。Vue 只在指定的來源變化時才會執行回呼，不會在初始化時自動執行（除非設定 `immediate: true`）：

```typescript
import { ref, watch } from 'vue'

const userId = ref('123')
const filters = ref({ status: 'active', page: 1 })

// 監聽單一來源
watch(userId, (newId, oldId) => {
  console.log(`使用者從 ${oldId} 切換到 ${newId}`)
  fetchUserData(newId)
})

// 監聽多個來源
watch([userId, () => filters.value.status], ([newId, newStatus]) => {
  fetchFilteredData(newId, newStatus)
})

// 深層監聽物件（注意性能開銷）
watch(filters, (newFilters) => {
  updateQueryParams(newFilters)
}, { deep: true })
```

### `watchEffect` — 自動追蹤依賴

適合「只要依賴變了就重新執行」的場景，不需要手動列出依賴。Vue 會在回呼首次執行時自動收集所有被讀取的響應式來源，並在任一來源變化時重新執行：

```typescript
import { ref, watchEffect } from 'vue'

const searchKeyword = ref('')
const selectedCategory = ref('all')

// 自動追蹤 searchKeyword 和 selectedCategory
watchEffect(() => {
  const params = new URLSearchParams()

  if (searchKeyword.value) {
    params.set('q', searchKeyword.value)
  }
  if (selectedCategory.value !== 'all') {
    params.set('category', selectedCategory.value)
  }

  window.history.replaceState(null, '', `?${params}`)
})
```

### 選擇指南

| 場景 | 選擇 |
|------|------|
| 需要比較新舊值 | `watch` |
| 只監聽特定一兩個來源 | `watch` |
| 需要 `immediate: false`（預設不執行） | `watch` |
| 依賴很多、列出來很冗長 | `watchEffect` |
| 只關心「任一依賴變化就執行」 | `watchEffect` |
| 同步副作用（如更新 URL） | `watchEffect` |

### 清理副作用

兩者都支援 `onCleanup` 來取消上一次未完成的副作用（例如 abort 前一次的 API 請求）：

```typescript
watch(userId, (newId, _oldId, onCleanup) => {
  const controller = new AbortController()

  fetchUser(newId, { signal: controller.signal })

  onCleanup(() => {
    controller.abort()
  })
})
```

---

## 非同步處理

`<script setup>` 頂層不能直接使用 `await`——如果使用了，整個元件會變成非同步元件，必須搭配 `<Suspense>` 才能正確渲染。大多數場景下不需要 `<Suspense>`，應將非同步操作放在 lifecycle hook 或獨立函式中。

使用 Promise chain（`.then/.catch/.finally`）而非 `async/await`，讓非同步流程更明確、鏈式結構一目了然：

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import type { UserInfo } from '@/types/user'

const user = ref<UserInfo | null>(null)
const isLoading = ref(false)
const error = ref<string | null>(null)

// ✅ 正確：使用 Promise chain 處理非同步
function fetchUser() {
  isLoading.value = true
  error.value = null

  api.getUser(props.userId)
    .then((response) => {
      user.value = response.data
    })
    .catch((err) => {
      error.value = err instanceof Error ? err.message : '載入失敗'
    })
    .finally(() => {
      isLoading.value = false
    })
}

onMounted(() => {
  fetchUser()
})
</script>
```

```vue
<script setup lang="ts">
// ❌ 錯誤：頂層 await 會讓元件變成 async setup，需要 <Suspense> 包裹
const response = await api.getUser(props.userId)
const user = ref(response.data)
</script>
```

**例外情況：** 如果你的應用架構已經設計好 `<Suspense>` 邊界（例如路由層級的 loading 狀態），頂層 `await` 是可以的。但預設情況下，避免使用。

---

## Style scoped 規範

### 預設使用 `<style scoped>`

`scoped` 透過 attribute selector 將樣式限定在當前元件，防止樣式洩漏。這是大多數元件的預設選擇：

```vue
<style scoped>
.card {
  padding: 16px;
  border-radius: 8px;
}

/* 深層選擇器：修改子元件內部樣式 */
.card :deep(.el-input__inner) {
  border-color: var(--primary-color);
}
</style>
```

### CSS Modules 的使用時機

當需要在 script 中動態引用 class name 時，CSS Modules 比 scoped 更適合，因為它提供了 JavaScript 可存取的 class 映射：

```vue
<script setup lang="ts">
const isActive = ref(true)
</script>

<template>
  <div :class="[$style.card, isActive && $style.active]">
    內容
  </div>
</template>

<style module>
.card {
  padding: 16px;
}

.active {
  border-color: var(--primary-color);
}
</style>
```

### 選擇指南

| 場景 | 選擇 |
|------|------|
| 一般元件樣式 | `<style scoped>` |
| 需要在 script 中動態切換 class | `<style module>` |
| 全域樣式（reset、typography） | `<style>`（無 scoped，放在 App 層級） |
| 修改第三方元件內部樣式 | `<style scoped>` + `:deep()` |
