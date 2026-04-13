# 業務邏輯分析：Issue Body 結構優化驗證

## 需求說明

驗證 Issue body 結構優化後的完整 workflow，確認以下所有改動正確生效：
- 區塊順序：工作文件 > 關聯 Issue > 相關連結
- 區塊命名：工作文件、相關連結
- 移除 Epic body 關聯 Issue 寫入
- SA body 無 PG Issue 欄位
- 同 repo Issue 連結無冗餘前綴

## 商業邏輯

本次為 workflow 結構優化驗證，無實際商業功能。

驗收標準：
1. SA Issue body：工作文件 > 關聯 Issue（無 PG 欄位，SA Issue 無前綴）> 相關連結
2. SD Issue body：工作文件 > 關聯 Issue（SD Issue 無前綴）> 相關連結
3. PG Issue body：工作文件 > 關聯 Issue > 相關連結
4. Epic body：不再有「關聯 Issue」區塊自動寫入

## 資料模型示意

無

## SD 注意事項

- 新增一個簡單 API Spec 觸發 SpecDiff
- TestReport 填入 mock 結果即可

## 畫面示意

無
