# Security

- **前端環境變數皆為公開**：`VITE_*`、`NEXT_PUBLIC_*` 會打包進 bundle，只放可公開的設定，secret 一律留在後端。
- **不渲染未消毒的 HTML**：`v-html` / `dangerouslySetInnerHTML` 只接受可信來源，或先經 DOMPurify 消毒；URL 綁定（`href`、`src`）需排除 `javascript:` scheme。
- **Token 不存 `localStorage` / `sessionStorage`**：優先 httpOnly cookie；既有專案以現況為準，但不新增此類寫法。
- **導向目標需驗證**：來自 query string 的 redirect URL 必須白名單比對或限制為站內相對路徑，避免 open redirect。
- **錯誤與日誌不外洩**：`console.log` 不輸出 token、個資；錯誤訊息不直接顯示後端 stack trace。
- 發現安全問題時先停下修正 CRITICAL 項目，必要時使用 `security-reviewer` agent 全面檢查；已外洩的 secret 必須輪替。
