---
name: coding-standards
description: 適用於 TypeScript、JavaScript、React 與 Node.js 開發的團隊程式碼規範。僅收錄與社群慣例不同或需團隊統一的決策。
---

# 程式碼規範

此檔只收錄「與社群慣例不同或需團隊統一」的決策；通用最佳實踐（命名、錯誤處理、型別安全、React patterns、效能優化等）依社群慣例與周圍程式碼風格判斷即可，不在此列舉。

## 檔案命名

```
components/Button.tsx     # 元件：PascalCase
hooks/use-auth.ts         # Hook：kebab-case，'use' 前綴
lib/format-date.ts        # 工具函式：kebab-case
types/user.types.ts       # 型別定義：kebab-case，'.types' 後綴
```

## API 設計

- 輸入驗證統一使用 **zod** schema，驗證失敗回傳 400 並附上 `error.errors` 細節。
- 回應採統一 envelope 結構：

```typescript
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  meta?: { total: number; page: number; limit: number }
}
```

## 測試

- 測試名稱使用繁體中文的行為描述（例如「當沒有結果時，回傳空陣列」）。

## 相關規範

Immutability、檔案大小原則見 rules `coding-style`；TDD 與覆蓋率見 rules `testing`，不在此重複。
