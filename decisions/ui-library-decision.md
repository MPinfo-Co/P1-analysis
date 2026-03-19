# UI 元件庫決策文件

**日期：** 2026-03-19
**決策人：** Robert Huang
**Issue：** P2-1

---

## 決策結果

**選擇：shadcn/ui**

---

## 評估選項

### 選項 A：Tailwind CSS only（純手刻）

- 完全自由，無任何元件限制
- 缺點：每個 Button、Dialog、Table 都要從頭寫，各頁面容易風格不一致，維護成本高
- 不選原因：MP-Box 有大量 UI 元件需求（Table、Tabs、Badge、Dialog、Dropdown...），純手刻費時且難以維持一致性

### 選項 B：shadcn/ui ✅ 選擇

- 元件 source code 複製進專案（非黑盒），可直接修改
- 基於 Radix UI（無障礙、鍵盤支援完整）
- 完全用 Tailwind CSS 撰寫，與現有技術棧相容
- 支援 Tailwind v4
- 提供 Button、Table、Tabs、Dialog、Badge、Dropdown 等完整元件，開箱即用
- 新人接手容易，每個元件有文件與範例

### 選項 C：Headless UI

- 只提供行為邏輯（無樣式），樣式全部自己加 Tailwind
- 介於 A 和 B 之間，但元件數量比 shadcn/ui 少
- 不選原因：相較 shadcn/ui 省下的時間不多，但失去現成樣式的便利性

---

## 選擇 shadcn/ui 的理由

1. **產品化優先**：預設樣式夠專業，不需要大量設計決策就能有一致的 UI
2. **開發速度**：Phase 1 有 10 個頁面要完成，現成元件直接加速
3. **可維護性**：元件在 `src/components/ui/` 下，改動透明，無外部 API 依賴
4. **技術棧一致**：shadcn/ui 底層是 Tailwind + Radix UI，與現有 React 19 + Vite + Tailwind v4 完全相容

---

## 安裝紀錄

```bash
npx shadcn@latest init --defaults
```

- 版本：shadcn 4.0.8
- style：base-nova
- Tailwind CSS v4 驗證通過
- 路徑別名 `@/` 設定完成（vite.config.js + jsconfig.json）
- 初始元件：`src/components/ui/button.jsx`、`src/lib/utils.js`
