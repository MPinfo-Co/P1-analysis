# 業務邏輯分析：f-kb-01 知識庫列表

## 功能/問題描述（from Epic）
### 功能目的

使用者進入知識庫頁面後，可瀏覽自己有讀取權限的知識庫清單；KB 管理員可在此觸發新建知識庫。

### 使用者情境

- 一般使用者：看到自己有讀取權限的知識庫列表
- KB 管理員：看到全部知識庫，可觸發「新建知識庫」
- 無權限使用者：看到空列表

### 驗收條件

1. 列表依角色過濾（依 kb_access_roles）
2. KB 管理員可觸發「新建知識庫」
3. 點擊知識庫進入詳情頁
4. pytest 數量 ≥ TestPlan 案例數，每個 test function 標注 TestPlan ID

### 範圍

**包含：** 知識庫列表顯示、依角色過濾、新建入口
**不包含：** 知識庫詳情內容（→ f-kb-03）、存取設定管理（→ f-kb-04）

### 參考資料

- [FunctionList.md f-kb-01](https://github.com/MPinfo-Co/P1-design/blob/main/FunctionList.md)
- 前端現有：`pages/KnowledgeBase/KnowledgeBase.jsx`（mock data）
- 存取控制邏輯：MPinfo-Co/P1-analysis#46 UC-6

### 關聯 Issue
<!-- 由系統自動填入，勿手動編輯 -->
- SA Issue：P1-analysis #（待建立）
- SD Issue：P1-design #（待建立）
- PG Issue：P1-code #（待建立）

## Use Case

## 流程圖

## Class Diagram

## ER 示意
