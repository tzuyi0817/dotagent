# 規則目錄 — 副作用與響應性

## 規則 5：副作用必須在 `onUnmounted` 中清理

IsUrgent: True
Category: Side Effects

### 說明

所有 DOM 事件監聽、`setInterval`、`setTimeout`、WebSocket 連線等副作用，必須在 `onUnmounted` 中清除，避免記憶體洩漏。

### 範例

```ts
export function useWindowResize() {
  const width = ref(window.innerWidth)

  function handleResize() {
    width.value = window.innerWidth
  }

  onMounted(() => {
    window.addEventListener('resize', handleResize)
  })

  // 必須清理
  onUnmounted(() => {
    window.removeEventListener('resize', handleResize)
  })

  return { width }
}
```

```ts
export function usePolling(callback: () => void, interval: MaybeRef<number> = 3000) {
  const normalizedInterval = toRef(interval)
  let timerId: ReturnType<typeof setInterval> | null = null

  function start() {
    stop()
    timerId = setInterval(callback, normalizedInterval.value)
  }

  function stop() {
    if (timerId !== null) {
      clearInterval(timerId)
      timerId = null
    }
  }

  // 必須清理
  onUnmounted(stop)

  return { start, stop }
}
```

---

## 規則 6：`props` 傳遞給 Composable 時使用 `toRef` 轉換

IsUrgent: True
Category: Side Effects

### 說明

元件中的 `props` 屬性直接傳遞會失去響應性。必須使用 `toRef(props, 'key')` 轉換後再傳入 Composable。

### 範例

```vue
<script setup lang="ts">
import { toRef } from 'vue'
import { useSearch } from '@/hooks/useSearch'

const props = defineProps<{
  keyword: string
  categoryId: number
}>()

// ✅ 使用 toRef 保持響應性
const { results, isLoading } = useSearch(
  toRef(props, 'keyword'),
  toRef(props, 'categoryId')
)
</script>
```

```ts
// hooks/useSearch.ts
export function useSearch(keyword: MaybeRef<string>, categoryId: MaybeRef<number>) {
  const normalizedKeyword = toRef(keyword)
  const normalizedCategoryId = toRef(categoryId)

  const results = ref<SearchResult[]>([])
  const isLoading = ref(false)

  watch([normalizedKeyword, normalizedCategoryId], async ([kw, catId]) => {
    isLoading.value = true
    results.value = await searchApi.query(kw, catId)
    isLoading.value = false
  }, { immediate: true })

  return { results, isLoading }
}
```

新增、編輯或移除副作用規則時，請同步更新此檔案，確保目錄保持正確。
