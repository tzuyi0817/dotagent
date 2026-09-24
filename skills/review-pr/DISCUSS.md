# 本人的 PR：逐項討論並修正

步驟 8 已把 review body 與每則 inline comment 連同錨點與 `suggestion` 印在終端機上、這一輪的記錄也已寫入之後，才進入這裡。意見不留在 PR 上，所以討論就是回覆串，修正就是 Commit suggestion——兩件事都在這個 session 裡完成。

證據鏈在這裡不會中斷：使用者的反對等同作者回覆，**舉證責任在你**；使用者改寫過或你新寫的修法，還沒人反駁過，跟候選一樣要先過 Fix Verifier。

## 1. 準備修正用的工作目錄

修正要落在 PR 的 head 分支（步驟 1 的 `headRefName`），而且是使用者之後能直接 commit 的地方，不是步驟 6 那個用完即丟的 verify worktree。

```bash
git -C <repo> worktree list --porcelain
git -C <repo> rev-parse pr-<n>
```

依序判斷，第一個成立的就用：

- 已有 worktree（含主工作目錄）checkout 在 `headRefName`，且 `HEAD` 等於本輪記錄的 `head_sha`：直接在那裡改。有未 commit 的變更時先列出來，問使用者要不要在其上繼續。
- 其他情況（分支不在任何 worktree、本地分支落後或超前 `head_sha`、`<repo>` 是 scratchpad 裡的 clone）：**不要自己 switch、reset 或 `-B` 覆寫分支**，那會動到使用者的工作狀態或吃掉未推送的 commit。把現況講清楚，提出一個具體做法（例如在指定路徑 `git worktree add` 該分支）讓使用者選。scratchpad 會隨 session 消失，不能當成修正的落腳處。

`HEAD` 是 `head_sha` 的後代（審完後又推了新 commit）時仍可繼續，但每一項都要走下面的內容比對，對不上就停在那一項。

完成判準：修正用的目錄已確定且使用者知道是哪裡；其 `HEAD` 與 `head_sha` 的關係已確認；沒有任何分支或未 commit 的變更被覆寫。

## 2. 一次一項

順序：先 inline comment（依 payload 的 `comments` 順序），再 body 裡**可以動手**的非阻擋項目（結構建議、要求補的測試）。body 的純觀察、pre-existing 記錄與正向驗證結果不必逐項討論，最後一次問使用者要不要挑其中幾項處理即可。

每一項：

1. 報出這是第幾項／共幾項、錨點 `<path>:<start_line>-<line>`，與一句話摘要。全文剛印過，不要重貼；使用者要求時才重印。
2. 用 AskUserQuestion 問決定，選項固定為：
   - **套用 suggestion**（原樣）
   - **改寫後套用**：使用者想要不同的修法
   - **不修**：使用者認為不成立或不值得
   - **先跳過**：留到最後或留給下一輪
3. **等使用者回答之後才處理下一項。** 不要一次問完、也不要先把全部套用再回頭問。

使用者選 Other 或提出問題時，就地討論到有結論為止，再回到上面四種決定之一。

完成判準：每一項都恰有一個使用者明確給出的決定；沒有任何一項是你替使用者決定的。

## 3. 依決定處理

### 套用 suggestion

suggestion 取代的是 `git show pr-<n>:<path>` 的 `start_line..line`。同檔案先前套用過的修正會讓行號位移，因此**以內容定位，不以行號定位**：

1. 取原始範圍：`git show pr-<n>:<path> | sed -n '<start>,<end>p'`。
2. 確認這段內容在工作目錄的檔案中**恰好出現一次**，再用 Edit 把它整段換成 suggestion 內容。
3. 找不到或出現多次：停下來，把差異給使用者看，不要猜測對應位置。

步驟 6 已對全部 suggestion 一起跑過實跑，原樣套用不必再派 Fix Verifier。但若該意見要求補測試，補測試也是這一項的一部分：先寫會在未修正時轉紅的測試，再確認套用後轉綠（TDD），並跑一次該發現的突變確認有被釘住。

### 改寫後套用

使用者的版本或你依討論新寫的版本都是**未經反駁的修法**。套用前把它交給一個獨立子代理，照步驟 6 的 Fix Verifier 四問裁決，prompt 內容與步驟 6 相同（repo 路徑、`pr-<n>`、該發現的 `failure_scenario`、修法全文與範圍），並排除討論過程。

- **sound**：照上面「以內容定位」的方式套用。
- **unsound**：把反駁證據（`file:line`）給使用者看，回到第 2 節重新決定。使用者看過證據仍堅持時照做，但記錄為 `applied-modified` 並在 `note` 寫下未解的疑慮。

### 不修

使用者拒絕等同作者回覆，只有兩條路：

- **接受並撤回**：使用者的理由成立，或你拿不出新證據。記下使用者的理由。
- **以新證據反駁**：拿出先前沒呈現過的 `file:line` 或探針結果，說一次就好。使用者看過仍拒絕，就尊重決定並記錄。

不要換句話重述同一個論點，那不是新證據。

### 先跳過

不動檔案。全部項目走完後再問一次；仍要跳過就記為 `deferred`，下一輪當成未決的先前意見對帳。

完成判準：每個套用都以內容比對定位且只換了預期範圍；每個改寫過的修法都有 Fix Verifier 裁決；每個「不修」都已撤回或以新證據反駁過一次。

## 4. 收尾

全部項目處理完之後：

1. 專案有 test、typecheck、lint、format 指令時，在修正用的目錄對受影響的套件各跑一次。轉紅就指出是哪一項造成的，回到那一項重新決定，不要自行加碼修改其他地方。
2. 給使用者總表：每一項的錨點、決定、一句話結果；接著附 `git -C <修正目錄> diff --stat`。
3. **不自動 commit 或 push。** 問使用者要不要 commit；要的話以 Conventional Commits 撰寫 message（例如 `fix: <修正內容>`），push 同樣要使用者明確同意。
4. 回寫本輪記錄（步驟 8 的 `round-<NN>.json`），補上 `resolutions` 欄位，其餘欄位不動：

```json
{
  "resolutions": [
    {
      "path": "apps/foo/bar.vue",
      "start_line": 127,
      "line": 138,
      "decision": "applied | applied-modified | declined | deferred",
      "note": "使用者的理由、改寫的內容摘要，或未解的疑慮",
      "commit": "修正所在的 commit SHA，尚未 commit 為 null"
    }
  ]
}
```

每則 inline comment 都要有一筆；body 項目只有被動手或被明確拒絕的才記。使用者之後才 commit 的，commit 後補上 `commit`。

完成判準：專案指令在修正後全綠，或每個紅燈都已歸因到某一項並由使用者決定過；總表與 diff stat 已給出；commit 與 push 都只在使用者同意後才發生；`resolutions` 已寫回本輪記錄，每則 inline comment 都有對應的一筆。
