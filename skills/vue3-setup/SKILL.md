---
name: vue3-setup
description: Vue 3 `<script setup>` 團隊開發規範。撰寫或修改 Vue 3 元件、定義 Props/Emits、使用 Pinia 或 Composable，以及詢問 Vue 3 寫法建議時使用。
---

# Vue 3 `<script setup>` 開發規範

此檔只收錄「與社群慣例不同或無法自行推斷」的團隊規範，標準 Vue 3 API 依官方慣例即可。進階 API（defineExpose、defineSlots、Template Refs、watch/watchEffect、非同步處理、Style scoped）見 `references/advanced-patterns.md`。

## 基礎規範

- 必須使用 `<script setup lang="ts">` 與 Composition API；響應式優先 `ref()`。
- 狀態管理優先 Pinia 或 Vue Query（TanStack Query）；避免以 `provide`/`inject` 隱式傳遞。
- 複雜邏輯抽離為 Composable，放在 **`hooks/` 目錄**（而非社群慣用的 `composables/`），檔名 `use*.ts`。
- 元件定義用 PascalCase（`EformListWay.vue`），**Template 中必須用 kebab-case 呼叫**（`<eform-list-way />`）；無 Slot 內容時使用自閉合標籤。
- 型別導入一律使用 `import type`，與 runtime import 分行。
- v-model 一律使用 `defineModel`（Vue 3.4+），不手寫 props + `update:` emit；`update:` 事件因此不需出現在 Emits 定義。

## Props 與 Emits

型別以 `interface` 定義並搭配編譯時泛型；Emits 使用 tuple 語法（而非 call signature `(e: 'xxx'): void`），與 Props 保持對稱的物件結構：

```vue
<script setup lang="ts">
interface Props {
  /** 表單標題 */
  title: string
  /** 資料列表 */
  items?: DataItem[]
}

interface Emits {
  /** 當表單送出時觸發 */
  submit: [payload: FormData]
  /** 當元件掛載完成時觸發，回傳元件高度 */
  mounted: [height: number]
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [], // 陣列/物件預設值必須用工廠函式，避免多個實例共享同一參考
})
const emit = defineEmits<Emits>()
</script>
```

- Template 中直接使用屬性名稱，不加 `props.` 前綴。
- Props 僅在 template 中使用時，可省略 `const props =`。

## Pinia Store

- **禁止使用 `storeToRefs`**：它會對 store 所有屬性建立響應式追蹤，即使只用到其中一兩個屬性；直接以 store 實例存取（如 `configStore.theme`）。
- Store 宣告位置遵循作用範圍最小化（Principle of Least Scope）：多處使用時放 setup 最外層，僅單一函式使用時放函式內部。

## `<script setup>` 區塊排列順序

1. 外部套件 imports → 2. 內部模組 imports → 3. 型別 imports → 4. Props / Emits / Model → 5. Store / Router / Composable → 6. 響應式狀態 → 7. Computed → 8. Methods → 9. Watch → 10. Lifecycle Hooks

## Composable 設計

- 參數使用 Options 物件（方便日後擴充而不破壞介面）。
- 回傳物件（非陣列）供使用端按需解構；回傳型別交由 TypeScript 推導，不手寫。
- 副作用（事件監聽、Timer）必須在 `onUnmounted` 中清理。
