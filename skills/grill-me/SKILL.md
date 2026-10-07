---
name: grill-me
description: 一場毫不留情的訪談，把計畫或設計磨利。
disable-model-invocation: true
metadata:
  source:
    repo: https://github.com/mattpocock/skills
    path:
      - skills/productivity/grilling
      - skills/productivity/grill-me
    commit: 5da500e727a5878bcd4d3278dfec741e01917652
    version: 1.3.1
  license: "MIT, Copyright (c) 2026 Matt Pocock"
  translation: "繁體中文（台灣）翻譯。合併上游 grilling（原語）與 grill-me（入口）為單一 user-invoked skill：dotagent 沒有其他 skill 需要呼叫原語，拆開沒有收益；description 依作者對 user-invoked skill 的規則只留一行摘要。本文段落與回合格式模板與上游 grilling 一一對應；依作者設計以純文字逐回合提問，不改用 AskUserQuestion（理由見上游 .out-of-scope/native-question-tool.md）；未複製上游的 agents/openai.yaml（Codex metadata）"
---

毫不留情地訪談使用者，直到雙方達成共同理解。把這件事畫成一棵**設計樹**（design tree）：每個決定都往下分岔出掛在它底下的決定。

以**回合**（round）推進這棵樹。**前沿**（frontier）是所有前提都已確定的決定：那些你**現在**就能問、不必猜測還沒聽到的答案的問題。一回合把整個前沿問完：每題編號，並附上你建議的答案。然後等使用者回答，再進下一回合。

一回合的格式如下：

```
❓ **Q1** - **<問題標題>**：<問題內容，可以是多段，包含選項>

➡️ <你建議的答案>

---

❓ **Q2** - **<問題標題>**：<問題內容，可以是多段，包含選項>

➡️ <你建議的答案>
```

使用者每回答一回合，樹就重新成形：定下來的決定把前沿往外推，解開原本依賴它們的問題。重新計算前沿，問下一回合。答案取決於本回合另一個尚未回答的問題的題目，屬於**之後**的回合，不是這一回合。

找出**事實**是你的工作，永遠不是使用者的。前沿的問題需要環境裡的事實（檔案系統、工具等）時，派一個子代理去找；你自己查得到的事，不要問使用者。不要卡在這裡等：進行中的探索是一個未確定的前提，所以只有它下游的問題要等子代理回報，前沿的其餘問題現在就問。**決定**則是使用者的：每一個都交給他們，然後等。

前沿空了，這一輪就結束：設計樹的每個分支都走過，沒有任何事被默默假設。在使用者確認雙方已達成共同理解之前，不要據此動手。
