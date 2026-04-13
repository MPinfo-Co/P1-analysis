# 業務邏輯分析：Workflow Issue Body 精簡測試

## 需求說明

這是一個端對端測試 Epic，用於驗證 PM → SA → SD → PG 完整 workflow 運作正常，以及 SA/SD/PG Issue body 精簡後（僅保留關聯項目區塊）的效果。

驗收條件：
- SA Issue body 只含「關聯項目」
- SD Issue body 只含「關聯項目」
- PG Issue body 只含「關聯項目」
- 所有關聯連結（分支、Draft PR、文件）正確填入

## 商業邏輯

本次為 workflow 測試，無實際商業功能。核心驗證點：

1. **SA Issue 建立**：Epic 加上 `epic` label 後自動觸發，body 僅含關聯項目區塊
2. **SD Issue 建立**：SA PR merge 後自動觸發，body 僅含關聯項目區塊（移除功能說明與設計範圍）
3. **PG Issue 建立**：SD PR merge 後自動觸發，body 僅含關聯項目區塊（移除實作範圍與測試執行紀錄）

每個 Issue 都應包含正確的分支連結、Draft PR 連結與關聯文件連結。

## 資料模型示意

無（本次為流程測試，不涉及資料模型異動）

## SD 注意事項

- 本次工作範圍：新增一個簡單的測試 API Spec 即可（用於觸發 SpecDiff 產生）
- 不需要實際可運行的程式碼，TestReport 填入 mock 測試結果即可

## 畫面示意

無
