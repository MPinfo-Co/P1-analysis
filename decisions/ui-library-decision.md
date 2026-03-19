# UI 元件庫決策文件

**日期：** 2026-03-19
**決策人：** Robert Huang
**Issue：** P2-1

---

## 決策結果

**選擇：shadcn/ui**

---

## 評估選項

### 主流選項比較

| | shadcn/ui | Mantine | Ant Design | Material UI | Tailwind only |
|--|--|--|--|--|--|
| 起源 | 美國 | 波蘭 | 中國 | 美國（Google） | — |
| 符合 v73 風格 | ✅ | ✅ | ❌ 偏藍白企業風 | ❌ 偏 Google 風 | ✅ |
| 開發速度 | 中 | ✅ 快 | ✅ 快 | 中 | ❌ 慢 |
| 客製化彈性 | ✅ 高 | 中 | ❌ 難改 | 中 | ✅ 最高 |
| 長期維護風險 | ✅ 低 | 中 | ❌ | 中 | ✅ 低 |

**排除 Ant Design**：外觀偏中國企業風，且元件封裝深、樣式難改。
**排除 Material UI**：外觀過於 Google 風，需要大量覆寫才能客製化。
**排除 Tailwind only**：MP-Box 有大量元件需求，純手刻費時且難維持一致性。

---

### shadcn/ui vs Mantine 詳細比較

#### 核心差異：元件的存在方式

**shadcn/ui：元件是你的 code**
```
npx shadcn add table
→ 把 table.jsx 複製進 src/components/ui/table.jsx
→ 可以直接修改 source
```

**Mantine：元件是套件**
```
npm install @mantine/core
→ 元件在 node_modules 裡
→ 只能靠 props 或 CSS override 調整
```

#### 功能比較

| | shadcn/ui | Mantine |
|--|--|--|
| 基本元件 | Button、Input、Table、Dialog... | 同左 |
| 進階元件 | 較少，需自行組合 | DatePicker、RichTextEditor、Carousel、Charts |
| 內建 Hooks | 無 | useForm、useDisclosure、useMediaQuery... |
| 樣式系統 | Tailwind CSS（原生） | 自己的 CSS Modules，與 Tailwind 並行 |
| 深色模式 | 手動設定 | 內建 ColorSchemeProvider |
| 升級影響 | 幾乎無（code 在 repo 裡） | 版本升級可能有 breaking change |

#### 結論

MP-Box 主要元件需求為 Table、Tabs、Badge、Dialog、篩選器，shadcn/ui 都能覆蓋。
選 shadcn/ui 的關鍵理由：**元件 source 在自己手上，長期維護成本最低**。

---

### 同生態其他選項（已排除）

- **Radix UI**：shadcn/ui 底層即是 Radix UI，選 shadcn 就已包含
- **Park UI**：概念同 shadcn 但元件少、社群小，不需考慮
- **DaisyUI**：風格偏休閒，不適合資安後台
- **Flowbite**：社群比 shadcn 小很多
- **React Aria**（Adobe）：純無障礙行為邏輯，無樣式，過於底層

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
