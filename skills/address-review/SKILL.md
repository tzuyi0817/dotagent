---
name: address-review
description: "依 PR reviewer 的意見修正使用者本人的 PR：抓取所有 review 與討論串，逐項先呈現 reviewer 的建議、再呈現自己查證後的評估並比對，一次一項以 AskUserQuestion 問使用者決定，依決定修正並草擬回覆。只在使用者以 /address-review 要求時執行。"
argument-hint: "[PR 編號或連結]"
disable-model-invocation: true
---

# 依 reviewer 意見修正 PR

Reviewer 的意見是**待驗證的宣稱**，不是指令。這個 skill 把每一則意見放回程式碼裡查證，再把「reviewer 說什麼」與「查證後我怎麼看」並排給使用者，由使用者決定怎麼修。它與 [review-pr](../review-pr/SKILL.md) 互補：那邊的意見由你產生，這邊的意見來自別人，你負責查證與消化；證據的標準兩邊相同。

節奏固定為**一次一項、先 reviewer 再自己、比對完才問、問完才動手**。說明寫在助理訊息裡，決定用 AskUserQuestion 問：一項得到決定並處理完，才進下一項。不要把多項交給子代理平行修改，不要先全部套用再回頭問，不要一次問「要挑哪幾項」，也不要用 multiSelect 把多項塞進同一次提問。

**回覆草稿的語言**跟隨該 repo 既有慣例（看既有 PR 意見與 commit message），無慣例時用繁體中文（台灣）；與使用者的討論一律繁體中文（台灣）。

## 0. 定位 PR 與取得可定位行號的原始碼

從指令後的參數定位 PR，三種形式都要支援：完整連結（解析 `<owner>/<repo>` 與編號，不假設是目前所在的 repo）、純編號（以目前工作目錄的 repo 為準）、沒給（取目前分支對應的 PR，找不到就問，不要猜）。

```bash
gh pr view <n> --repo <owner>/<repo> --json number,title,body,author,baseRefName,headRefName,headRefOid,files,url
gh pr diff <n> --repo <owner>/<repo> > <scratchpad>/pr<n>.diff
git -C <repo> fetch origin pull/<n>/head:pr-<n> --force
gh api /user --jq .login
```

比對 `author.login` 與 `gh api /user` 的 login。這個 skill 修的是**使用者本人的 PR**；不是本人的 PR 時先講明，說清楚修正會落在誰的分支上，等使用者回覆要不要繼續。目標 repo 不是本機這一份時，先取得本機副本（`gh repo clone <owner>/<repo> <scratchpad>/<repo> -- --filter=blob:none`），以下 `<repo>` 一律指本機副本的絕對路徑。

變更後原始碼一律從 `git show pr-<n>:<path> | cat -n` 讀，行號才對得上 reviewer 錨定的 new-file 行號；用 `gh pr diff` 判斷某個變更是否屬於這個 PR。

完成判準：`<owner>`、`<repo>`、PR 編號、本機 repo 絕對路徑、`headRefOid` 皆已確定；是否為本人的 PR 已判定並告知使用者；每個變更檔案都能透過 `git show pr-<n>:<path>` 讀取。

## 1. 抓取 reviewer 的意見

三個來源都要抓，少一個就會漏掉一種意見：

```bash
# review 本體（整體評估、摘要式的多點意見）
gh api --paginate /repos/<owner>/<repo>/pulls/<n>/reviews \
  --jq '.[] | select(.body != "") | {id, user: .user.login, state, submitted_at, body}'
# PR 層級的一般留言
gh api --paginate /repos/<owner>/<repo>/issues/<n>/comments \
  --jq '.[] | {id, user: .user.login, created_at, body}'
# inline 討論串：只有 GraphQL 給得出 isResolved / isOutdated 與串的歸屬
gh api graphql -F owner=<owner> -F repo=<repo> -F n=<n> -f query='
query($owner:String!,$repo:String!,$n:Int!){
  repository(owner:$owner,name:$repo){ pullRequest(number:$n){
    reviewThreads(first:100){ nodes{
      id isResolved isOutdated path line startLine
      comments(first:50){ nodes{ databaseId url createdAt author{login} body } }
    } }
  } }
}'
```

把抓到的內容整理成**項目清單**，一個項目對應一個可獨立決定的意見：

- 一個 inline 討論串是一個項目；串內 reviewer 的後續補充併入同一項，使用者自己先前的回覆記為「你已回覆：…」。
- review 本體或一般留言列了多點（編號、條列、多個段落各談一件事）時，**每一點各成一項**，並保留它在原文中的位置以便引用。
- 每個項目記下：來源（reviewer login，bot 要標明）、錨點（`path:line`，沒有就記 `body`）、原文、連結、類型（要求修改／提問／純觀察）、以及 **reviewer 自己標示的嚴重度**（阻擋、不擋、nit、提問），只能照原話記，不自行升降。
- 已 resolved 的串、純正向或 LGTM 的留言：列進總覽的「不逐項討論」區，不進入討論。`isOutdated` 的串仍是項目，查證時多問一件事：最新 commit 是否已經處理掉它。

完成判準：三個來源都抓過；每個未 resolved 的意見都恰在一個項目裡；每個項目都有來源、錨點、原文、連結、類型與 reviewer 標示的嚴重度。

## 2. 逐項查證：在討論開始前一次做完

Reviewer 的意見和 Finder 的候選一樣，沒有人試著反駁過之前都不算成立。先把每一項查完，討論時才拿得出並排的證據，而不是邊問邊查。

**派誰查**：含行為宣稱的項目（說某種輸入或操作會出錯、某個業務規則成立、某個修法會修好它）各派一個獨立子代理，在同一則訊息中一次派出。純風格、命名、typo、註解與文件類的項目，直接讀 `git show pr-<n>:<path>` 核對即可，不派子代理。

子代理的 prompt 必須自我完備，**只**包含：repo 絕對路徑、`pr-<n>` ref、base 分支、該項的錨點與 reviewer 原文、以及下列規則。其他項目、你自己的猜測都不放進去，避免錨定。

1. **先反駁**：找出並引用能推翻 reviewer 說法的程式碼。技術事實不確定時跑一次性探針或查套件原始碼。
2. **問題是否成立**：引用真的打開過的 `file:line`（PR head）。在 base 分支跑同一項檢查，區分「本 PR 引入」與「既有問題」。
3. **前提有出處**：reviewer 的立論若建立在業務規則或產品行為上（某筆資料能否被刪、表單何時顯示、某入口是否存在），必須找到證明該前提的來源：後端回應或型別檔說明、程式註解、規格或 issue、既有測試。**Reviewer 的話本身不算出處。**
4. **評估 reviewer 的修法**（有提出時）：有沒有關掉列舉的每個失效窗口、有沒有開出新的、可不可證偽（說不出套用與否的可觀察差異，就是風格偏好）、會不會弄壞其他呼叫端。
5. **有沒有更好的修法**：有就寫出來並說明與 reviewer 修法的可觀察差異；沒有就寫沒有。
6. **影響範圍**：要動的檔案；測試分成「改既有測試」與「新增測試檔」兩類分開列；是否超出 `gh pr diff` 的檔案。

每一項查完後定下**你的立場**，恰好一種：

- **照做**：問題成立，reviewer 的修法可行。
- **改法**：問題成立，但建議不同的修法或更小的範圍（例如只在既有測試補一條斷言，而不新增測試檔）。
- **不修**：問題不成立或不值得，附反駁證據。
- **待確認**：技術上說得通，但前提找不到出處，要先問使用者。
- **已處理**：最新 commit 已經涵蓋，附 `file:line`。

提問類的項目不定立場，改為備妥**回答草稿**與證據。

完成判準：每一項都有帶 `file:line` 的查證結果；每個行為宣稱都經過獨立子代理反駁；每一項恰有一個立場（或一份回答草稿）；每個「待確認」都寫出了引不到出處的那句前提原文。

## 3. 總覽

以助理訊息列出清單，每項一行：編號、錨點、reviewer 一句話、reviewer 標示的嚴重度、你的立場。接著列「不逐項討論」區（已 resolved、純正向），一行一個，說明為什麼不討論。

討論順序：reviewer 標示為阻擋的 → 其餘 inline 項目依 `path:line` → review 本體與一般留言的項目 → 提問類。使用者要改順序或跳過，照辦。

總覽之後**同一則訊息**直接進入第一項，不要為了總覽單獨停一次。

完成判準：每個項目都有編號且立場可見；不討論的項目各有一句理由。

## 4. 一次一項：先 reviewer、再自己、比對完才問

每一項固定兩段：先以助理訊息完整說明，再用 AskUserQuestion 問決定。

### 說明

說明固定三段，一段都不能少。即使總覽剛列過，每一項仍要重新完整說明，不能只給錨點與一句話。

```markdown
### 第 N 項／共 M 項 — <path>:<line>（<reviewer>，<reviewer 標示的嚴重度>）
<意見連結>

**Reviewer 的建議**
> 原文引用；過長時只引關鍵段落，不改字、不摘要

- 指出的問題：reviewer 認為會發生什麼、在哪一行
- 提出的修法：reviewer 建議怎麼改；沒提就寫「未提出」
- 標示的嚴重度：照原話

**我的評估**
- 問題是否成立：成立／不成立／既有問題／前提待確認，證據 `file:line`
- 前提與出處：reviewer 立論的前提是什麼、出處在哪；找不到就照原文列出那句前提
- Reviewer 修法的評估：可行／不可行，原因與 `file:line`
- 我的建議：改什麼、為什麼選這個做法
- 替代方案與取捨：考慮過但沒選的做法與代價；沒有就寫沒有
- 影響範圍：檔案；測試（改既有／新增檔案分開列）；是否超出 PR diff
- 不修的後果：留著會怎樣、嚴重度怎麼判、路徑現在就走得到還是要等之後的功能

**比對**
| 面向 | Reviewer | 我 |
|------|----------|----|
| 問題 | | |
| 嚴重度 | | |
| 修法 | | |
| 範圍 | | |

一句話結論：兩邊一致／分歧在哪、建議採哪一邊。
```

### 問決定

說明之後用 AskUserQuestion 問，一次只問這一項，不用 multiSelect。`header` 填「第 N 項」，`question` 重述一句話結論並問要採哪一邊。選項依你的立場固定，兩邊一致時不要列出假的分歧：

- **照做**：照做／不修（我草擬回覆理由）／先跳過
- **改法**：照我的建議／照 reviewer 的做法／不修／先跳過
- **不修**：同意不修（我草擬附證據的回覆）／仍照 reviewer 做／先跳過
- **待確認**：先只問前提本身，例如「關聯被表單引用時，後端會擋下刪除嗎？」，選項是成立／不成立／不確定。成立再用上面一組問修法；不成立就記為不修，並檢查 PR 內有沒有建立在同一前提上的既有修改，有就提出退回；不確定記為 `deferred`。
- **已處理**：確認（我草擬回覆指向對應 commit）／仍需調整
- **提問類**：先給回答草稿與證據，選項是回覆內容可以／要調整／順便改程式碼

兩條格式規則：

- **你的立場對應的選項放第一個，label 加「（建議）」**，讓使用者一眼看到你站哪邊；每個選項的 `description` 寫一句選了會發生什麼事。
- AskUserQuestion 最多四個選項，且工具自帶 Other 讓使用者打字，所以**不要列「改寫」「其他做法」這類本來就要描述的選項**；在 `question` 末尾提一句「想改寫就選 Other 描述做法」即可。

**等使用者回答之後才處理下一項。** 使用者選 Other 或提出新問題時，就地討論到有結論，再回到上面的決定之一；意思不明確就再問一次，不要替使用者決定。

完成判準：每一項都先有三段說明再問；每一項都恰有一個使用者明確給出的決定；沒有任何一項是你替使用者決定的。

## 5. 依決定處理

### 修正落在哪裡

修正要落在 PR 的 head 分支，且是使用者之後能直接 commit 的地方。確認目前工作目錄 `HEAD` 等於 `headRefOid` 或是它的後代（審完後又推了新 commit）；其他情況（分支不在任何 worktree、本地落後、`<repo>` 是 scratchpad 裡的 clone）**不要自己 switch、reset 或覆寫分支**，把現況講清楚並提出一個具體做法（例如在指定路徑 `git worktree add`），等使用者決定。

### 修改範圍

只動 `gh pr diff` 列出的檔案與為它們補的測試檔。要動到 diff 以外的檔案、另一個 app、或 shared 套件時，預設記為 `separate-pr`；只有使用者在該項明確說要在這支 PR 裡改才動手，並在記錄的 `note` 寫下超出範圍的檔案。

### 套用

- **Reviewer 給了 `suggestion` block**：它取代的是該意見錨定的 `start_line..line`。先前的修正會讓行號位移，因此**以內容定位**：取 `git show pr-<n>:<path> | sed -n '<start>,<end>p'`，確認這段內容在工作目錄的檔案中恰好出現一次，再用 Edit 整段換成 suggestion 內容。找不到或出現多次就停下來給使用者看差異，不要猜。
- **你新寫或改寫的修法**（立場為改法、使用者要求改寫、提問後順便改）：都是未經反駁的修法，套用前交給一個獨立子代理照第 2 節第 4 點的四問裁決，prompt 含 repo 路徑、`pr-<n>`、該項的失效情境、修法全文與範圍，排除討論過程。sound 才套用；unsound 把反駁證據給使用者看，回到第 4 節重新決定；使用者看過仍堅持時照做，記為 `applied-modified` 並在 `note` 寫下疑慮。
- **測試**：走 TDD，先寫在未修正時會轉紅的測試，再確認修正後轉綠。reviewer 標示「不擋」的補測試建議，使用者不一定要做：**改既有測試**可在該項決定後直接做，**新增測試檔**（含為了放測試而搬資料夾）要使用者在該項明確同意才做。
- **不修**：你的立場原本是照做或改法時，以先前沒呈現過的證據再說一次，說一次就好；使用者仍拒絕就尊重。接著草擬回覆：一句結論加 `file:line` 證據，語言跟隨 repo 慣例。只草擬，不 POST。
- **先跳過**：不動檔案，全部項目走完後再問一次；仍要跳過就記為 `deferred`。

一項做完、驗證完，下一則訊息的開頭用一兩行交代結果（動了哪些檔案、測試是否通過），接著給下一項的完整三段說明，再用 AskUserQuestion 問。

完成判準：每個套用都以內容比對定位且只換了預期範圍；每個新寫或改寫的修法都有獨立裁決；每個「不修」都有附證據的回覆草稿；沒有任何修改落在 PR 變更檔案以外，除非該項的 `note` 記著使用者的明確同意。

## 6. 收尾

全部項目處理完之後：

1. 專案有 test、typecheck、lint、format 指令時，對受影響的套件各跑一次。轉紅就指出是哪一項造成的，回到那一項重新決定，不要自行加碼修改其他地方。
2. 給使用者總表：每一項的錨點、reviewer 標示、你的立場、使用者的決定、一句話結果；接著附 `git diff --stat`。
3. **PR 描述**：逐句核對 PR body 的宣稱，列出因本輪修正而不再正確的句子與建議改法；使用者同意後才 `gh pr edit <n> --body-file`。
4. **回覆草稿**：每個討論過的串各一則，照原樣寫在助理訊息裡：已修的指向修正內容（commit 之後補上 SHA），不修的附證據，提問的給回答。**只在使用者明確要求時才 POST**，一旦送出 PR 上所有人都看得到：

   ```bash
   # inline 串：<comment_id> 為該串第一則意見的 databaseId
   gh api --method POST /repos/<owner>/<repo>/pulls/<n>/comments/<comment_id>/replies --field body=@<file>
   # 一般留言
   gh api --method POST /repos/<owner>/<repo>/issues/<n>/comments --field body=@<file>
   ```

   Resolve 討論串是 reviewer 的事，不替對方按；使用者明確要求時才用 GraphQL `resolveReviewThread`。
5. **不自動 commit 或 push。** 問使用者要不要 commit；要的話以 Conventional Commits 撰寫（例如 `fix: <修正內容>`），push 同樣要明確同意。
6. 寫入本輪記錄，下一輪（reviewer 再回覆之後）要靠它對帳。放在 git 目錄底下，天生不進版控：

   ```bash
   git -C <repo> rev-parse --path-format=absolute --git-common-dir
   ```

   寫到 `<git-common-dir>/dotagent-address/pr-<n>/round-<NN>.json`，`<NN>` 兩位數零補、接在既有最大號之後：

   ```json
   {
     "repo": "<owner>/<repo>",
     "pr": 123,
     "head_sha": "本輪開始時的 headRefOid",
     "addressed_at": "ISO 8601",
     "items": [
       {
         "id": 1,
         "source": "<reviewer login>",
         "comment_id": 123456,
         "thread_id": "PRRT_… 或 null",
         "path": "apps/foo/bar.vue",
         "line": 138,
         "reviewer_claim": "一句話",
         "reviewer_severity": "阻擋 | 不擋 | nit | 提問",
         "my_stance": "照做 | 改法 | 不修 | 待確認 | 已處理",
         "decision": "applied | applied-modified | declined | deferred | separate-pr | answered",
         "note": "使用者的理由、改寫摘要、前提的確認結果、超出範圍的檔案或未解的疑慮",
         "reply_posted": false,
         "commit": null
       }
     ]
   }
   ```

   使用者之後才 commit 或 POST 回覆的，事後補上 `commit` 與 `reply_posted`。

完成判準：專案指令在修正後全綠，或每個紅燈都已歸因並由使用者決定過；總表、diff stat、PR 描述核對結果、每個串的回覆草稿都已給出；commit、push、POST 都只在使用者明確同意後才發生；記錄已寫入，討論過的每一項都有一筆。

## 再一輪：reviewer 回覆之後

再次執行時先讀 `dotagent-address/pr-<n>/` 底下每一輪記錄。第 1 節抓到的意見中，`createdAt` 晚於上一輪 `addressed_at` 的是**新進意見**，排在總覽最前面；上一輪 `declined` 的項目 reviewer 若再堅持，只有兩條路：接受並改做，或以上一輪沒呈現過的新證據再回覆一次，不要換句話重述同一個論點。上一輪 `deferred` 的項目視為未決，照常進入討論。
