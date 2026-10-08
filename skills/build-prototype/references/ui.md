# UI 分支：同一頁面上的多個版本

在**既有 route** 上產生多個結構截然不同的 UI 版本，用 `?variant=` 切換，底部一條浮動切換列。使用者在瀏覽器裡翻看、挑一個（或各拿一部分），其餘丟掉。問題若是邏輯而非外觀，走 [logic.md](logic.md)。

## 放在既有頁面裡，不要另開空白 route

版面要靠著真實的 header、側欄、真實資料與密度才判斷得出好壞；孤立的 route 裡每個版本看起來都不錯。預設把版本掛在既有頁面上：資料抓取、route 參數、權限全部沿用，只換渲染的子樹。要 prototype 的東西還沒有頁面、但天生會住在某個頁面裡（dashboard 的新區塊、設定頁的新卡片、既有流程的新步驟），一樣掛進那個宿主頁面。

真的沒有任何既有頁面可以容納（全新的頂層入口）才新開 route：照專案既有的 routing 慣例，路徑或檔名含 `prototype`，同樣用 `?variant=`。開之前再問一次：真的沒有頁面可以放嗎？

## 步驟

1. **寫下問題與數量**。預設 3 個版本，最多 5 個，再多就不是截然不同而是雜訊。一行寫在 prototype 目錄或檔案頂端：「設定頁的三個版本，`/settings` 既有 route，以 `?variant=` 切換」。
2. **產生截然不同的版本**。每個版本守住頁面的目的、拿得到的資料、專案的元件庫與樣式系統，檔名明確如 `VariantA.vue`、`VariantB.vue`。版本之間要在**結構**上不同：不同版面、不同資訊階層、不同主要操作，不是換顏色。兩個草稿太像就重做一個，明講「不准用卡片格線」之類的限制。
3. **接起來**。宿主頁面讀 `useRoute().query.variant`（預設 `A`），依值渲染對應版本，既有的資料抓取留在切換之上：

   ```vue
   <script setup lang="ts">
   // 示意，依專案慣例調整
   const route = useRoute()
   const variant = computed(() => String(route.query.variant ?? 'A'))
   const variants = { A: VariantA, B: VariantB, C: VariantC }
   </script>

   <template>
     <component :is="variants[variant] ?? VariantA" v-bind="data" />
     <PrototypeSwitcher :variants="Object.keys(variants)" :current="variant" />
   </template>
   ```

4. **浮動切換列**。固定在畫面底部中央：左箭頭、目前版本（鍵與版本名，如 `B（側欄版面）`）、右箭頭，循環切換。點箭頭以 `router.replace({ query: { ...route.query, variant } })` 更新網址，可分享、重整不丟；`←` `→` 鍵也能切，但 `input`、`textarea`、`contenteditable` 有焦點時不攔截。外觀要明顯不屬於被評估的頁面（高對比藥丸、淡陰影）。以 `import.meta.env.PROD` 隱藏，誤合併也不會出現在使用者面前。做成一個共用元件，放在專案共用 UI 的位置。
5. **交出去**。給網址與 `?variant=` 的鍵。最有價值的回饋通常是「我要 B 的 header 配 C 的側欄」，那才是真正想要的設計。
6. **收尾**。勝出的版本依 SKILL.md 的共通規則併進真實頁面，用正式碼的標準重寫，不直接提升 prototype 碼；落選版本與切換列從 main 移除，整組留在 `prototype/<name>` 分支。

完成判準：所有版本在同一網址上可切換、可用鍵盤循環、production 不顯示；每個版本都能說出與其他版本在結構上的差異；問題與版本數寫在頂端。

## 反模式

- 只差顏色或文案的版本，那是微調不是 prototype。
- 版本之間共用太多：共用 `<Header>` 可以，共用 `<Layout>` 就失去意義，每個版本要能自由丟掉版面。
- 接上真實的 mutation。唯讀即可，需要寫入就指向 stub；問題是「該長怎樣」，不是「後端能不能動」。
- 把 prototype 直接升級成正式碼。它是在沒測試、最少錯誤處理的約束下寫的，併入時要重寫。
