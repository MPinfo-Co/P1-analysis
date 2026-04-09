# CLAUDE.md

## 角色說明

P1-analysis 是需求分析（SA）階段的 Repo。
SA Issue 由 P1-project 的 p-workflow 自動建立，**不可手動建立**。

## 工作內容

收到 SA Issue 後，在 `issue-{N}/` 資料夾填寫兩份文件：

1. **business-logic.md** — 商業邏輯說明（Use Case、流程圖、Class Diagram、ER 示意，格式自由）
2. **SD-WBS.md** — SD 工作清單（須符合最低格式要求）

## SD-WBS.md 格式要求

```markdown
# SD WBS：{功能名稱}

## 工作項目
| # | 類型 | 說明 |
|---|------|------|
| 1 | Schema | 說明 |
| 2 | API | 說明 |
| 3 | 畫面 | 說明 |

## 備註
<!-- 特殊限制、相依關係、需 SD 決策的設計點 -->
```

類型限定：`Schema`、`API`、`畫面`、`其他`

## references/ 目錄

存放與特定 Issue 無關的通用參考文件（架構圖、命名規則等）。

## Commit 格式

```
{type}: 工作說明
```

範例：`docs: 完成請假申請 SA 分析`

## 完整流程

請參考 [quick-start.md](https://github.com/MPinfo-Co/P1-project/blob/main/docs/workflow/quick-start.md)
