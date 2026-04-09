# 業務邏輯分析：Workflow 改造驗證測試

## 功能/問題描述（from Epic）
### 功能說明

此為 workflow 改造後的驗證測試 Epic，確認 SA / SD / PG issue body 與關聯項目連結的正確性。

### 驗收條件

1. SA issue 只有「關聯項目」section
2. business-logic.md 第一個 section 為「功能/問題描述（from Epic）」，包含本 body 內容
3. SA 關聯項目有 business-logic.md 和 SD-WBS.md 連結

## Use Case

**UC-01：驗證 Workflow 改造後各階段 Issue 結構**

| 欄位 | 說明 |
|------|------|
| 角色 | SA / SD / PG |
| 前置條件 | p-workflow / a-workflow / d-workflow 已更新並 push |
| 主要流程 | 建立 Epic → 觸發各階段 workflow → 確認 issue body 與關聯項目連結 |
| 後置條件 | 三個階段的 issue 結構符合設計規範 |

## 流程圖

```
Epic created (epic label)
  └─ p-workflow → SA issue + business-logic.md (含 Epic body) + SD-WBS.md + 連結
      └─ SA merge → a-workflow → SD issue (含 business-logic.md 內容) + 連結
          └─ SD merge → d-workflow → PG issue (含 Spec 連結) + 連結，無測試報告 scaffold
```

## Class Diagram

（本測試 issue 無實際 schema 異動）

## ER 示意

（本測試 issue 無實際 ER 異動）
