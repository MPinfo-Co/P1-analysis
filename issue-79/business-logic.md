# 業務邏輯分析：Issue Body 最終格式驗證

## 需求說明

驗證 Issue body 最終格式：
- 區塊命名：SA/SD/PG 工作文件、相關連結
- 相關連結只含分支與 Draft PR（無階段欄位）

## 商業邏輯

最終格式驗證，無實際商業功能。

## SD 注意事項

新增一個簡單 API Spec 觸發 SpecDiff 即可。
