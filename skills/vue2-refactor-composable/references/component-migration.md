# 規則目錄 — 元件遷移

## 規則 10：元件必須使用 `<script setup>` 語法

IsUrgent: True
Category: Component Migration

### 說明

所有重構後的元件必須使用 `<script setup>` 語法糖，不使用 `defineComponent` + `setup()` 函數的寫法。

### 範例

```vue
<!-- ❌ 轉換前 -->
<script lang="ts">
import { defineComponent, ref } from 'vue'

export default defineComponent({
  props: {
    title: { type: String, required: true }
  },
  setup(props, { emit }) {
    const count = ref(0)
    return { count }
  }
})
</script>
```

```vue
<!-- ✅ 轉換後 -->
<script setup lang="ts">
import { ref } from 'vue'

interface Props {
  title: string;
}

interface Emits {
  update: [value: number];
}

const props = defineProps<Props>();
const emit = defineEmits<Emits>();

const count = ref(0);
</script>
```

---

## 規則 11：JSX 語法必須轉為 `<template>`

IsUrgent: True
Category: Component Migration

### 說明

所有使用 JSX/TSX 的 `render` 函數必須轉為 Vue 的 `<template>` 語法。

### 範例

```tsx
// ❌ 轉換前：JSX render
export default defineComponent({
  setup() {
    const visible = ref(true)
    return () => (
      <div>
        {visible.value && <span class="label">可見</span>}
        <ul>
          {items.value.map(item => (
            <li key={item.id} onClick={() => select(item)}>{item.name}</li>
          ))}
        </ul>
      </div>
    )
  }
})
```

```vue
<!-- ✅ 轉換後：template -->
<template>
  <div>
    <span v-if="visible" class="label">可見</span>
    <ul>
      <li
        v-for="item in items"
        :key="item.id"
        @click="select(item)"
      >
        {{ item.name }}
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const visible = ref(true);
const items = ref<Item[]>([]);

function select(item: Item) {
  // ...
}
</script>
```

新增、編輯或移除元件遷移規則時，請同步更新此檔案，確保目錄保持正確。
