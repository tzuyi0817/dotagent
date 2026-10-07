# Skill 機制

[`writing-for-agents`](SKILL.md) 的 skill 專屬分支：文件是 skill 時有哪些不同（frontmatter、觸發方式的選擇、路由 skill）。其餘的寫法都在 `SKILL.md` 的通用參考裡。

## 觸發方式

兩種選擇，在兩種負載之間取捨：

- **模型觸發**（model-invoked）的 skill 保留 `description`，agent 可以自行觸發它，其他 skill 也能呼叫它。你仍然可以直接輸入它的名字：模型觸發永遠**包含**使用者觸發；description 只會增加 agent 的可發現性，從不拿走人的入口。description 是這個 skill 的頂層脈絡指標，被迫隨時載入：用永久的脈絡負載換可發現性。內容全是參考的模型觸發 skill，也是共用參考的一個家：別的 skill 可以呼叫它，多個 skill 都需要的參考就能只放一處。做法：不設 `disable-model-invocation`，寫一段面向模型、帶觸發分支的 description（`SKILL.md` 的指標寫法規則全部適用）。
- **使用者觸發**（user-invoked）的 skill 把 description 從 agent 的視野移除：只有人輸入它的名字才能觸發，其他 skill 都不能。脈絡負載為零，但花認知負載：你就是那份必須記得它存在的索引。做法：設 `disable-model-invocation: true`；`description` 改為面向人：一行摘要，拿掉觸發條件清單。

只有在 agent 必須自行找到這個 skill、或另一個 skill 必須呼叫它時，才選模型觸發。如果它只會由人手動觸發，就做成使用者觸發，不付脈絡負載。

兩個使用者觸發的 skill 都需要的共用參考，哪一邊都放不得：兩者都沒有 description，誰也觸發不了誰。把它推到 skill 系統之外的一般檔案：任何 skill 都能指向的外部參考。

## 依觸發方式拆分

拆分的「觸發方式」這一刀（「順序」那一刀在 `SKILL.md`）：當你有一個獨立的引導詞該自己觸發它（一個你真的會在 prompt 裡用的觸發詞），或另一個 skill 必須呼叫它時，才拆出一個模型觸發的 skill。新增的常駐 description 要付脈絡負載，所以那份獨立的入口得值這個價。

## 路由 skill

當使用者觸發的 skill 多到記不住，堆起來的認知負載用一個**路由 skill**來解：一個使用者觸發的 skill，列出其他 skill 以及各自何時該用，人只需要記住一個 skill 而非一堆。它只能提示，不能觸發它們：使用者觸發的 skill 沒有 description，除了人以外誰也碰不到。
