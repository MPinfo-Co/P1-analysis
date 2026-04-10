# 業務邏輯分析：f-kb-02 文件上傳與管理

## 功能/問題描述（from Epic）
### 功能目的

使用者可在知識庫內上傳文件，系統保存並提供列表、刪除、預覽。

### 使用者情境

- KB 管理員：上傳文件至指定知識庫、刪除文件
- 一般使用者（有讀取權限）：瀏覽文件列表、預覽文件內容

### 驗收條件

1. 可上傳文件並顯示於列表
2. 可刪除文件（含二次確認）
3. 可預覽文件內容
4. 寫入限 KB 管理員
5. pytest 數量 ≥ TestPlan 案例數，每個 test function 標注 TestPlan ID

### 範圍

**包含：** 文件上傳、列表、刪除、預覽
**不包含：** 結構化資料表（→ f-kb-03）、文件向量化 / RAG（SA 階段評估是否在本 issue 範圍）

### 待 SA 釐清

- 文件上傳後是否需整合 AI 分析？若需要，整合方式為何（全文注入 prompt？RAG？）
- 支援哪些檔案格式？
- 上傳檔案的病毒掃描機制（ClamAV）是否在本 issue 範圍？

### 參考資料

- [FunctionList.md f-kb-02](https://github.com/MPinfo-Co/P1-design/blob/main/FunctionList.md)
- [TechStack.md — 檔案儲存（Cloudflare R2）、安全（ClamAV）](https://github.com/MPinfo-Co/P1-design/blob/main/TechStack.md)
- 前端現有：`pages/KnowledgeBase/DocTab.jsx`（mock data）

### 關聯 Issue
<!-- 由系統自動填入，勿手動編輯 -->
- SA Issue：P1-analysis #（待建立）
- SD Issue：P1-design #（待建立）
- PG Issue：P1-code #（待建立）

## Use Case

## 流程圖

## Class Diagram

## ER 示意
