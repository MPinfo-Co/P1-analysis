# 業務邏輯分析：Workflow 完整流程驗證（TDD 改名後）

## 功能/問題描述（from Epic）
## 功能描述

驗證 TestPlan → TDD 改名後，SA → SD → PG 完整自動化流程正常運作。

### 驗收條件
- SA issue body 呈現三段式（工作狀態 / 關聯Issue / 關聯檔案）
- SA branch merge 後自動建立 SD issue，關聯檔案含 `TDD/issue-{N}.md` 路徑
- SD issue body 三段式，繼承 business-logic.md、SD-WBS.md
- SD branch merge 後自動建立 PG issue，SpecDiff 正確，TDD 連結可開啟
- PG issue body 三段式，含 SpecDiff、TDD、TestReport 連結
- TestReport scaffold 在 P1-code C-Branch 自動建立（來源為 `TDD/issue-{N}.md`）
- Draft PR body 只有 Closes #N

## 關聯 Issue
<!-- 由系統自動填入，勿手動編輯 -->

## Use Case

**角色：** 開發者、AI 代理

**主流程：**
1. PM 在 P1-project 開 Epic issue
2. GitHub Actions 自動在 P1-analysis 建立 SA issue + branch + Draft PR
3. SA 填寫 business-logic.md 與 SD-WBS.md 並 merge
4. GitHub Actions 自動在 P1-design 建立 SD issue + branch + Draft PR
5. SD 填寫 TDD/issue-{N}.md、Prototype、Spec 並 merge
6. GitHub Actions 自動在 P1-code 建立 PG issue + branch + Draft PR + TestReport scaffold

## 流程圖

```
Epic(P1-project) → [a-workflow] → SA Issue(P1-analysis)
SA merge         → [a-workflow] → SD Issue(P1-design)
SD merge         → [d-workflow] → PG Issue(P1-code) + TestReport scaffold
```

## Class Diagram

無（純流程驗證，無新增資料模型）

## ER 示意

無（純流程驗證，無 schema 異動）
