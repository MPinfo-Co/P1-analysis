# 業務邏輯分析：f-kb-04 知識庫存取權限

## 功能/問題描述（from Epic）
### 功能目的

控制哪些角色可讀取指定知識庫，並管理「KB 管理」寫入角色的授予。

### 使用者情境

- KB 管理員：設定哪些角色可讀取該知識庫（kb_access_roles）
- 系統 admin：授予 / 撤銷「KB 管理」角色

### 驗收條件

1. 可指定角色讀取知識庫
2. 無「KB 管理」角色無法寫入任何知識庫
3. 停用使用者建立的 KB 仍可被其他管理員修改
4. pytest 數量 ≥ TestPlan 案例數，每個 test function 標注 TestPlan ID

### 範圍

**包含：** 讀取權限設定（kb_access_roles）、KB 管理角色授予
**不包含：** 知識庫內容管理（→ f-kb-03）

### 參考資料

- [FunctionList.md f-kb-04](https://github.com/MPinfo-Co/P1-design/blob/main/FunctionList.md)
- SA 分析：MPinfo-Co/P1-analysis#46 UC-6、§6 角色權限設計
- 前端現有：`pages/KnowledgeBase/AccessTab.jsx`（mock data）

### 關聯 Issue
<!-- 由系統自動填入，勿手動編輯 -->
- SA Issue：P1-analysis #（待建立）
- SD Issue：P1-design #（待建立）
- PG Issue：P1-code #（待建立）

## Use Case

## 流程圖

## Class Diagram

## ER 示意
