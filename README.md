# P1-analysis — 需求分析（SA）

> [← 回到 P1 總導覽](https://github.com/MPinfo-Co/P1-project#readme)

P1 產品的系統分析文件庫。每個功能需求對應一個 Issue 資料夾。

## 在四 Repo 流程中的角色

```
P1-project（PM）
    └─ P-workflow 自動建立 SA Issue + A-Branch + Draft PR
        └─ P1-analysis（SA）  ← 你在這裡
            └─ SA merge → A-workflow 自動建立 SD Issue
                └─ P1-design（SD）→ P1-code（PG／AI
```

## 目錄結構

```
P1-analysis/
├── issue-{N}/                    # 每個 SA Issue 對應一個資料夾（N = Issue 編號）
│   ├── business-logic.md         # 業務邏輯分析（Use Case、流程圖、Class Diagram、ER 示意）
│   └── SD-WBS.md                 # SD 工作清單（SA 填寫，系統自動複製至 SD Issue）
└── references/                   # 參考資料
```

## SA 工作起點

收到 SA Issue 後：

1. Pull 分支（Issue body 中有分支連結）
2. 在 `issue-{N}/` 填寫 `business-logic.md` 與 `SD-WBS.md`
3. Push → Draft PR 已自動建立，確認內容後轉 **Ready for Review**
4. Merge 後系統自動建立 SD Issue，SA Issue 自動關閉

**Branch 命名：** `issue-{N}-{slug}`（由系統建立，不手動建立）

## 各資料夾說明

| 資料夾 | 內容 |
|--------|------|
| `issue-{N}/business-logic.md` | Use Case、流程圖、Class Diagram、ER 示意等商業邏輯說明 |
| `issue-{N}/SD-WBS.md` | SD 需完成的工作項目表，格式需含 `\| # \| 類型 \| 說明 \|` 表頭 |
| `references/` | 與特定 Issue 無關的通用參考資料 |

## 完整工作流程規範

請參考 [P1-project/docs/workflow/quick-start.md](https://github.com/MPinfo-Co/P1-project/blob/main/docs/workflow/quick-start.md)
