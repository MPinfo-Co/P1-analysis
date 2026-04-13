# 商業邏輯說明：端對端流程驗證

## Use Case

**UC-01：驗證 P0 自動化流程**

| 欄位   | 說明                              |
| ---- | ------------------------------- |
| 角色   | PM、SA、SD、PG                     |
| 前置條件 | 四條 GitHub Actions workflow 已部署  |
| 主要流程 | PM 開 Epic → 系統自動串接 SA → SD → PG |
| 後置條件 | 每個 Repo 各有對應 Issue 與 Branch     |

## 流程說明

```
PM 開 Epic Issue（P1-project）
  └─ 加 epic label → P-workflow 觸發
      └─ 建立 SA Issue + A-Branch（P1-analysis）
          └─ SA merge → A-workflow 觸發
              └─ 建立 SD Issue + D-Branch（P1-design）
                  └─ SD merge → D-workflow 觸發
                      └─ 建立 PG Issue + C-Branch（P1-code）
```

## 備註

此為流程驗證用測試 Issue，無實際業務邏輯。
