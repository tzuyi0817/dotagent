# 規則目錄 — 程式碼品質

## 條件式 class 名稱使用工具函式

IsUrgent: True
Category: Code Quality

### 說明

確保條件式 CSS 透過共用的 `classNames` 工具函式處理，而非使用自訂三元運算子、字串拼接或模板字串。將 class 邏輯集中管理，能保持元件一致性並降低維護成本。

### 建議修復方式

```ts
import { cn } from '@/utils/classnames'
const classNames = cn(isActive ? 'text-primary-600' : 'text-gray-500')
```

## 優先使用 Tailwind 樣式

IsUrgent: True
Category: Code Quality

### 說明

優先使用 Tailwind CSS 工具類別，而非新增 `.module.css` 檔案，除非 Tailwind 的組合無法達成所需樣式。將樣式統一在 Tailwind 中可提升一致性並降低維護負擔。

新增、編輯或移除程式碼品質規則時，請同步更新此檔案，確保目錄保持正確。

## Classname 排序以利覆寫

### 說明

撰寫元件時，務必將傳入的 `className` prop 放在元件自身 class 值的**後面**，這樣下游使用者才能覆寫或擴充樣式。如此一來，元件保有自身的預設樣式，同時也允許外部呼叫者修改或移除特定樣式。

範例：

```tsx
import { cn } from '@/utils/classnames'

const Button = ({ className }) => {
  return <div className={cn('bg-primary-600', className)}></div>
}
```
