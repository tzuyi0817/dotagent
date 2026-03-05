# 規則目錄 — 業務邏輯

## Node 元件中禁止使用 workflowStore

IsUrgent: True

### 說明

Node 元件的檔案路徑規則：`web/app/components/workflow/nodes/[nodeName]/node.tsx`

Node 元件也會在從範本建立 RAG Pipe 時被使用，但在該情境下不存在 workflowStore Provider，導致畫面空白。[此 Issue](https://github.com/langgenius/dify/issues/29168) 正是由於這個原因所引發。

### 建議修復方式

使用 `import { useNodes } from 'reactflow'`，而非 `import useNodes from '@/app/components/workflow/store/workflow/use-nodes'`。
