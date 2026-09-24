---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.vue"
---

# TypeScript Coding Style

- **型別導入**一律使用 `import type`，與 runtime import 分行。
- **禁用 `any`**：未知型別用 `unknown` 再以型別守衛收窄。
- **避免 `as` 斷言與非空斷言 `!`**：以型別守衛或 zod 解析取代；外部資料（API 回應、query string、storage）在邊界以 zod 驗證。
