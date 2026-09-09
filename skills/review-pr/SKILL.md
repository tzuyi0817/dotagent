---
name: review-pr
description: "審查 GitHub PR 並發布有證據、可直接套用的審查意見（附 suggestion block）。當使用者要求審查某個 PR，或作者推送修正後要求再審一輪時使用。"
disable-model-invocation: true
---

# 審查 PR：發布有證據、可直接套用的意見

走一條**證據鏈**：Finder 找出候選，Verifier 獨立裁決候選是否成立，Fix Verifier 獨立裁決修法是否正確，存活下來的發現才寫回 PR。候選還不是意見，沒人試著反駁過的修法也不是。

除了必須重新產生的產物（lockfile、build 輸出），每則 inline comment 都要有**錨定的 new-file 行號範圍**、**精簡的說明**、以及可直接套用的 `suggestion` block。所有 inline comment 一次送出為單一 review。

**審查文字的語言**：跟隨該 repo 既有的語言與語系慣例（看既有 PR 意見與 commit message）；repo 無明確慣例時使用繁體中文（台灣）。程式碼、指令、`suggestion` block 內容不在此限。

使用者說「再審一次」「修好了再看」，或該 PR 上已經有你送出過的 review（`gh api /repos/<owner>/<repo>/pulls/<n>/reviews`）時，這是**追加審查**：證據鏈相同，但候選來源、body 結構與收尾條件不同。開始前先完整讀 [FOLLOW-UP.md](FOLLOW-UP.md) 並照做，它會指明覆寫了哪些步驟。

## 0. 判斷規模，選擇路徑

先量變更規模，再決定要跑到多重。用錯路徑的代價是雙向的：小 PR 跑完整流程是浪費，大 PR 抄捷徑會漏掉東西。

```bash
gh pr diff <n> --repo <owner>/<repo> --patch | diffstat -s
```

- **小型**（≤ 3 個檔案且 ≤ 100 行變更）：單一 Finder 套用全部 lens；步驟 6 只做 Fix Verifier 四問，略過實跑與突變。
- **中大型**：完整流程，每個 lens 各自派一個 Finder。
- **含以下任一者一律走完整流程**（無論行數）：認證/授權、金流、資料遷移、build 或 CI 設定、對外 API 契約、快取或並行控制。

完成判準：規模已量測，路徑已選定，且選擇的理由能一句話說清楚。

## 1. 取得 PR 與可定位行號的原始碼

先從使用者的輸入定位 PR，三種形式都要支援：

- **完整連結**（`https://github.com/<owner>/<repo>/pull/123`）：從 URL 解析 `<owner>/<repo>` 與編號，**不假設它就是目前所在的 repo**，跨 repo 審查是常態。
- **純編號**（`123`）：以目前工作目錄的 repo 為準，`gh repo view --json nameWithOwner -q .nameWithOwner`。
- **沒給**：取目前分支對應的 PR，`gh pr view --json number,url`。找不到就問使用者，不要猜。

目標 repo 不是本機這一份時，先取得可讀取原始碼的本機副本，否則之後的 `git show pr-<n>:<path>` 全都無從執行；本機已有 clone 就直接用，不重複下載：

```bash
gh repo clone <owner>/<repo> <scratchpad>/<repo> -- --filter=blob:none
```

以下所有指令中的 `<repo>` 一律指這份本機副本的絕對路徑。

```bash
gh pr view <n> --repo <owner>/<repo> --json number,title,body,baseRefName,headRefName,files,url
gh pr diff <n> --repo <owner>/<repo> > <scratchpad>/pr<n>.diff
git -C <repo> fetch origin pull/<n>/head:pr-<n> --force
```

用 `gh pr diff` 判斷什麼被改動、以及某個變更是否屬於這個 PR。**不要**用 `git diff <本地 base>...pr-<n>` 判斷歸屬：base 過期或發生過 rebase 都會把無關的變更捲進那份 diff。

new-file 行號與 suggestion 內容一律只從 `git show pr-<n>:<path>` 取得；從 diff 複製會把行號偏移或 `+`/`-` 前綴帶進結果。

完成判準：`<owner>`、`<repo>`、PR 編號、本機 repo 絕對路徑四者皆已確定；每個變更檔案都能透過 `git show pr-<n>:<path> | cat -n` 讀取；且每個 hunk 都對應到 new-file 行號。

## 2. Finder：平行搜尋候選

把每個 lens 指派給獨立的 Finder 子代理，並在同一則訊息中一次派出。走小型路徑時，一個 Finder 套用全部 lens。

- **逐行**：對每個 hunk 的每一行問，什麼輸入、狀態、時序或平台會讓它出錯。特別檢查條件反向、差一錯誤、falsy 的 0、漏掉的 `await`、複製貼上沒改到的變數名、被吞掉的錯誤。
- **被移除的行為**：找出每個被刪除或改寫的區塊原本維持了什麼不變量，再定位新程式碼在哪裡把它補回來。哪裡都沒有，就回報一個候選。
- **跨檔契約**：追變更函式的呼叫端與被呼叫端。檢查新的前置條件、回傳形狀、例外、時序是否讓任一邊壞掉。
- **宣稱 vs 實作**：把 PR 描述宣稱的每項變更在 diff 中定位，並回報每個描述沒宣稱的 diff 變更。PR body 連到的 issue 或規格檔，只要 `gh` 或 `git show` 抓得到就一併視為宣稱來源。
- **專案慣例**：套用適用於變更檔案的 `CLAUDE.md`、`AGENTS.md`、`rules/` 規則。只有在能逐字引用該規則時才回報慣例違規。
  - 變更含 `.vue` → 一併讀 [references/vue3-checklist.md](references/vue3-checklist.md)
  - 變更含 `.tsx`/`.jsx` 或 Next.js 路由檔 → 一併讀 [references/react-checklist.md](references/react-checklist.md)
  - 兩者皆有（monorepo 常見）→ 兩份都讀，各自只套用在對應副檔名的檔案上

Finder 看不到目前這段對話，因此每個 prompt 都必須自我完備，並包含：

- repo 絕對路徑、`pr-<n>` ref、diff 檔路徑、PR 標題與 body。明確要求所有變更後原始碼的讀取都走 `git show pr-<n>:<path>`。
- 該 Finder 那個 lens 的完整內文，以及必須向外追的範圍：完整的變更後檔案、被呼叫端實作、所有呼叫端，以及相關的語系檔、design token 與型別定義。
- Finder 只搜尋、不裁決。即使不確定也回報看似成立的候選；由獨立的 Verifier 決定它是否成立。
- 輸出形狀：`file`、以 new-file 編號的 `line`、一句話的 `summary`、以及描述**使用者可見後果**的 `failure_scenario`（錯誤輸出、崩潰、資料遺失，而非中間狀態）。最多回報六個候選，沒有就回空陣列。

完成判準：每個 Finder 都已回報，同行號且同失效機制的重複候選已收斂成 `failure_scenario` 最具體的那個，且逐行 lens 已檢查過每一個 hunk。

## 3. Verifier：逐一獨立裁決

把去重後的每個候選各指派給一個獨立的 Verifier 子代理，平行派出。

Verifier 的 prompt 必須自我完備，且**只**包含 repo 絕對路徑、`pr-<n>` ref、base 分支、候選的四個欄位，以及下列規則。刻意排除 Finder 的推理過程，避免錨定效應。

先試著**反駁**候選：找出並引用能推翻它的程式碼。技術事實不確定時——API 相容性、正規表達式行為、CSS 交互作用、套件語法——跑一個一次性的 Node 或 Python 探針，或查 caniuse 與套件原始碼。反駁失敗之後，才檢驗以下三關：

1. **有追過**：引用一個 Verifier 真的打開過的 `file:line` 作為證據。
2. **由這個 PR 引入**：在 base 分支跑同一項檢查。只有 base 正常而 PR 失效才算過關。
3. **具體的失效情境**：路徑可達，且後果對使用者可見。

裁決恰好三種，每種都要附 `file:line` 證據：三關全過為 **confirmed**；只有第二關沒過為 **pre-existing**；其餘為 **invalid**。

單一 Verifier 讀錯 ref 或讀錯分支，就會產出整個錯誤的裁決。當裁決引用的 `file:line` 對不上 `pr-<n>`，換一個 Verifier 重驗該候選。

完成判準：每個候選都恰有一個帶證據的裁決，且三關各有明確結果。

## 4. 依阻擋嚴重度分流

**阻擋**的意思是：這個問題會改變作者該不該合併、或該不該接受目前這個實作。只有 confirmed 且阻擋的候選才變成 inline comment。

confirmed 但不阻擋的結構性建議與後續工作、pre-existing 的觀察、有用的正向驗證結果，都放進 review body。Verifier 以強證據反駁掉某個候選時，body 可以記一筆「不需修改」的結論。其餘沒有資訊價值的 invalid 候選直接丟棄。

完成判準：每個裁決都被指派到 inline comment、review body、丟棄三者其一，且每則 inline comment 都同時是 confirmed 與阻擋。

## 5. 撰寫給人看的說明與可直接套用的 suggestion

GitHub 的 `suggestion` block 會**取代整個 `start_line..line` 範圍**。作者按下 Commit suggestion 後，block 的內容就成為該範圍的新狀態。

草擬完 review body 與每則 inline comment 說明的事實內容後，把它們刪到只剩重點，維持本 skill 開頭確立的語言與語系。只精簡給人看的散文，`suggestion` block、程式碼、指令與其他必須逐字保留的內容除外。刪的時候砍掉這些：

- 鋪陳與收尾的客套（「感謝你的貢獻」、「整體來說寫得不錯，但是」）
- 對 diff 內容的複述——作者看得到自己改了什麼
- 對嚴重度的閃避性修飾（「可能也許會有一點小問題」）

然後檢查**必須留下來的六件事**：技術事實、`file:line` 證據、不確定的程度、阻擋嚴重度、義務的強弱（「必須」和「可以考慮」不能互換）、責任歸屬。把刪掉的補回來，再刪一次。

- suggestion 必須包含被取代範圍的**完整**目標內容。每一行沒有要改的行，連同縮排，逐位元組保留。
- 範圍切在自我完備的邊界上：一整個函式、一條 CSS 規則、一個 HTML/template 元素。
- 每則 inline comment 說明控制在三到五句，順序為：**症狀 → 根因並附 `file:line` → 為什麼這個改動重要**。這是資訊順序，不是標題或固定句型。程式碼變更只放在 suggestion block 裡。
- 跨檔案的修法拆成各自獨立可套用的意見，並互相交叉引用。當某個 suggestion 會讓另一行失效時，在散文中指名那一行。
- lockfile、build 輸出等產生物，提供重新產生的指令，不提供 suggestion。

完成判準：review body 與每則說明都經過精簡，六件事零遺漏、零新增；每個 suggestion 都與 `git show pr-<n>:<path> | sed -n '<start>,<end>p'` 並排比對過；預期編輯範圍以外的每一行都逐位元組相符；套用後的檔案語法有效；每個跨檔案修法都有對應的交叉引用意見。

## 6. Fix Verifier：反駁修法

發現要靠撐過反駁才配得到一則意見，修法也一樣。這一步把同樣的反駁優先紀律轉向 suggestion 本身。

把每個 suggestion 各指派給一個獨立子代理，平行派出。prompt 必須自我完備，包含 repo 絕對路徑、`pr-<n>` ref、該發現的 `failure_scenario`、suggestion 的完整內容與行號範圍。排除作者的推理過程，避免錨定。

先試著反駁修法，四題都要用 `file:line` 回答：

1. 修法有沒有關掉該發現列舉的每一個失效窗口？
2. 有沒有開出新的？
3. 修法可證偽嗎？指出套用與不套用之間可觀察的差異：輸出、錯誤、時序或型別。說不出差異的修法就是風格偏好，撤掉它——下一輪反過來的意見正是從這種修法來的。
4. 套用後會不會弄壞其他呼叫端？

裁決恰好兩種：**sound**；或 **unsound**——撤掉該 suggestion，若存在正確修法就指出來，否則把該發現降級為 body 觀察。

### 本輪內的衝突

每個 Fix Verifier 只看得到自己那一個 suggestion。所有裁決回來後、實跑之前，把本輪存活的 suggestion 兩兩比對。三種衝突，各有各的解法：

- **範圍重疊**：同一檔案中兩個 `start_line..line` 範圍相交。GitHub 各自獨立套用，相交的兩者無論作者用什麼順序 commit 都會產生錯誤內容。合併成一個，或保留一個、把另一個改成純散文。
- **修法互斥**：兩個 suggestion 對同一個符號、契約或不變量得出互斥的結論。留下證據較強的那個，另一個撤掉或降級到 body。
- **修法相依**：套用 A 正是讓 B 的錨定行、前提或必要性失效的原因——例如 A 移除了 B 那行的最後一個使用者。把 B 的範圍對著「A 套用後的內容」重切，並在 B 的意見中指名 A；無法解耦時合併成一個。

存活的 suggestion 必須能一起套用，否則實跑證明不了任何事。

### 實跑

專案有定義 test、typecheck、lint、format 指令時，全部跑兩次：套用本輪 suggestion 前一次，套用後一次。第一次確立哪些紅燈本來就存在，有了它第二次才能歸因。

在 detached worktree 執行，不動使用者的工作目錄：

```bash
git -C <repo> worktree add --detach <scratchpad>/verify pr-<n>
```

pnpm monorepo 在該 worktree 內以 `pnpm install --frozen-lockfile --prefer-offline` 安裝（會重用本機 store，通常很快）；只需驗證受影響的套件時用 `pnpm -F <package> test` 縮小範圍。

任何讓執行結果轉紅的 suggestion，撤掉或修好，直到全綠。驗完後 `git -C <repo> worktree remove <scratchpad>/verify` 清掉。

### 突變

專案有測試時，把每個發現指向的那幾行刪掉或反向，然後跑測試：

- **仍然全綠**：作者的測試沒有**釘住**這個發現。這強化了該發現；在同一則意見中要求補上測試。新增的測試碼行數不是覆蓋率的證據，突變才是。
- **紅燈**：已被釘住。記在 body 裡。

套用 suggestion 之後再突變一次，回答本輪的修法有沒有被鎖住。

完成判準：每個 suggestion 都有一個帶 `file:line` 證據的 Fix Verifier 裁決；本輪存活的 suggestion 已兩兩比對，沒有相交範圍、互斥的已砍到剩一個、相依的已指名並對套用後內容重切；每個存在的指令都在前後各跑過一次，且套用後全綠；每個發現都有突變結果；每個被判 unsound 或讓執行轉紅的 suggestion 都已撤掉或修好。

## 7. 送出前對帳

兩項機械檢查，都在產生 payload 之前完成。

**自我一致性。** 把本輪每個 suggestion 與先前各輪送出過的 suggestion、以及對它們記錄過的推翻逐一比對（本輪內的衝突已在步驟 6 解決）。碰到同一個符號或同一個區塊時，只會是三者之一：

- **延伸**：正常送出。
- **推翻**（移動、反向或取代先前的修法）：只有在新進的 diff 動過那段程式碼、或你握有先前那輪沒有的證據時才成立。在意見中直說先前那則是錯的、附上新證據，並在 body 統計本輪的自我推翻次數。沒有新證據就不是推翻，而是**來回擺盪**。
- **來回擺盪**（回到某一輪已經放棄過的修法）：撤掉，不要重送。在同一個地方跨輪擺盪，證明的是沒有任何一輪的證據撐得起任一種形式。把那份不確定寫進 body 交給作者裁決，不附 suggestion。

分類依據是 Fix Verifier 的裁決與先前各輪的送出紀錄，不是自我評估。

**誠實性。** 逐項檢查：

- body 宣稱的發現數量，與 `comments` 陣列長度相符。
- body 非阻擋段落的每一句話，都有指名的 Verifier 或 Fix Verifier 證據支撐。只靠 Finder 一面之詞的敘述，刪掉或降級為未決。

完成判準：每個與歷史重疊的 suggestion 都標記為延伸、推翻或來回擺盪；每個推翻都帶著先前那輪沒有的證據，並同時寫在意見與 body 中；每個來回擺盪都已撤掉且其不確定性已記入 body；body 的數字與 `comments` 陣列相符；非阻擋段落的每一句都有指名證據。

## 8. 送出 review 並驗證錨點

建立一個 Python 檔來產生 payload JSON。讓 Python 去編碼反引號、反斜線與引號，shell heredoc 才傷不到 suggestion 內容。

```python
payload = {
    "body": "<review body：整體評估 + 非阻擋項目>",
    "event": "REQUEST_CHANGES",
    "comments": [
        {
            "path": "apps/foo/bar.vue",  # repo 相對路徑
            "start_line": 127,            # new-file 行號
            "line": 138,
            "side": "RIGHT",
            "start_side": "RIGHT",
            "body": "說明 + ```suggestion block",
        },
    ],
}
```

單行意見則省略 `start_line` 與 `start_side`。範圍必須落在 RIGHT 側的 diff hunk 內，否則 GitHub 會以 422 拒絕整個請求。

由存活的發現決定 `event`：有任何阻擋發現用 `REQUEST_CHANGES`；只有觀察與建議用 `COMMENT`；沒有問題殘留用 `APPROVE`。使用者要求 request changes 但證據撐不起任何阻擋發現時，用 `COMMENT` 並在 body 說明原因。

**送出前先確認。** review 一旦 POST 出去，PR 上的所有人都看得到，且無法乾淨地撤回。先把這四項給使用者過目，取得同意再送：目標 repo 與 PR 編號、`event`、每則 inline comment 的 `path:start_line-line` 與一句話摘要、body 的開頭段落。使用者已明確說過「直接送出、不用問」時才略過這一關。

```bash
gh api --method POST /repos/<owner>/<repo>/pulls/<n>/reviews \
  --input <scratchpad>/review.json --jq '{id, state, html_url}'
```

送出後驗證每個錨點：

```bash
gh api /repos/<owner>/<repo>/pulls/<n>/comments \
  --jq '.[] | "\(.path):\(.start_line)-\(.line)"'
```

`line` 為 `null` 代表該意見已過期、在 PR 上不再正確顯示。修正行號後重送那一則。

最後給使用者 review 連結、每個發現的一句話摘要，以及所有未在瀏覽器或執行環境中驗證過的部分。

完成判準：review 已用正確的 event 送出，每則預期的意見都出現在 PR 上且 `line` 非 null，且給使用者的回報包含 review 連結、所有發現與所有未驗證的部分。
