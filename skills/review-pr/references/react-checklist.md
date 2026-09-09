# React / Next.js 審查檢查點

給步驟 2「專案慣例」lens 用。這裡列的不是風格偏好，而是**違反後會造成使用者可見失效**的點——只有這種才配得到候選。

## 規範來源

回報慣例違規前，先逐字引用出處，順序為：專案的 `CLAUDE.md` / `AGENTS.md` → 專案 `rules/` → `coding-standards` skill → `frontend-patterns` skill（everything-claude-code plugin）。引不出原文就不回報。

`coding-standards` 已明列的規範（檔案命名、zod 驗證、API envelope、繁中測試名稱）不在此重複；違反時直接引用該 skill 原文。

## Hooks 的正確性

- **依賴陣列遺漏**：`useEffect`/`useCallback`/`useMemo` 讀了某個值卻沒列進依賴。後果是 stale closure——回呼永遠讀到第一次渲染的值，使用者看到的是舊資料或送出舊 payload。追每個在 body 中被讀取的識別字，逐一比對依賴陣列。
- **依賴陣列過度**：把每次渲染都是新參考的物件或函式列進依賴，讓 effect 每次都跑。搭配網路請求時會變成無窮迴圈。
- **條件式呼叫 hook**：hook 出現在 `if`、迴圈或 early return 之後。React 依呼叫順序配對 state，順序一變，state 會錯配到別的 hook 上。
- **缺清理函式**：effect 內訂閱、`setInterval`、`addEventListener`、`fetch` 沒有回傳清理。競態下較慢的舊請求會覆蓋較新的結果——這在切分頁時肉眼可見。用 `AbortController` 或 ignore flag。
- **`useState` 初始值每次渲染都重算**：`useState(expensiveCalc())` 每次渲染都呼叫（只是丟棄結果）。應寫成 `useState(() => expensiveCalc())`。

## State 與參考穩定性

- **直接 mutate state**：`state.items.push(...)` 之後 `setState(state.items)`。參考沒變，React 跳過重渲染，畫面停在舊資料。專案 rules `coding-style` 明訂 Immutability 優先，引用它。
- **以舊 state 計算新 state 而未用函式式更新**：連續多次 `setCount(count + 1)` 只會生效一次；改用 `setCount(c => c + 1)`。
- **Context 的 value 每次渲染都是新物件**：整棵消費該 context 的子樹每次都重渲染。用 `useMemo` 包住 value。
- **複雜 props（物件、陣列、Map、行內函式）未記憶化就傳給已 `memo` 的子元件**：`memo` 因此完全失效。
- `key` 用陣列 index，而該列表會排序、篩選或中間插入：元件狀態（輸入框內容、展開狀態）會錯位到別的資料上。

## Next.js 的伺服器/客戶端邊界

- **secret 洩漏到 client**：server component 或 API route 讀取的環境變數被當成 props 傳進 client component，或誤加了 `NEXT_PUBLIC_` 前綴。這一律列為阻擋。
- **在 client component 中使用只存在於 server 的 API**（`fs`、資料庫 client、server-only 套件），或反過來在 server component 中用 `useState`/`useEffect`/瀏覽器 API。
- **`'use client'` 的位置改變了邊界**：把它加在較高層會把整棵子樹拉進 client bundle。diff 若新增或移動了這個指示詞，追它影響的範圍。
- **快取語意**：`fetch` 的 `cache`/`next.revalidate` 選項、`export const dynamic`、`revalidatePath`/`revalidateTag` 的變更，都會改變使用者看到的是即時資料還是快取。變更後未同步的地方會顯示過期內容。
- **Server Action 缺少授權檢查或輸入驗證**：它是公開端點，不因為只從某個表單呼叫就安全。依 `coding-standards` 應以 zod 驗證。

## 安全

- `dangerouslySetInnerHTML` 綁定任何非硬編碼內容：XSS，一律阻擋。
- 使用者可控的值進到 `href`（`javascript:` 協議）、`window.open`、或 `eval`/`new Function`。
- API route 或 Server Action 直接把使用者輸入拼進 SQL、檔案路徑或外部 URL。

## 測試

- 新增或修改的分支沒有對應的 Vitest 測試。搭配步驟 6 的突變驗證：把該行刪掉或反向，測試若仍全綠，就在意見中要求補測試。
- 測試斷言內部實作（呼叫了哪個 hook、state 的形狀）而非使用者可見行為。專案測試工具鏈為 Vitest + Testing Library，斷言應走 `getByRole` 等可存取的查詢。
