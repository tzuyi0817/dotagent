# 規則目錄 — 效能

> 新增、編輯或移除效能規則時，請同步更新此檔案，確保目錄保持正確。

## React Flow 資料使用方式

IsUrgent: True
Category: Performance

### 說明

渲染 React Flow 時，UI 消費端優先使用 `useNodes`/`useEdges`；在需要異動或讀取節點/邊狀態的回呼函式中，則依賴 `useStoreApi`。避免在這些 hooks 以外的地方手動取用 Flow 資料。

## 複雜 prop 的記憶化

IsUrgent: True
Category: Performance

### 說明

將複雜的 prop 值（物件、陣列、Map）在傳入子元件前以 `useMemo` 包裹，以確保參考穩定性，防止不必要的重新渲染。

錯誤寫法：

```tsx
<HeavyComp
    config={{
        provider: ...,
        detail: ...
    }}
/>
```

正確寫法：

```tsx
const config = useMemo(() => ({
    provider: ...,
    detail: ...
}), [provider, detail]);

<HeavyComp
    config={config}
/>
```
