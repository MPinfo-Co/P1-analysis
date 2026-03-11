# [Product Name] — Product Requirements Document

> **Version:** 1.0
> **Last Updated:** YYYY-MM-DD
> **Author:** [Name]
> **Status:** [e.g., Planning / MVP In Progress / Beta / Launched]

---

## Executive Summary

<!-- 2-3 句話描述你的產品是什麼、為誰而做、核心價值。 -->
<!-- 寫法：[Product] 是專為 [target audience] 打造的 [product type]。透過 [mechanism]，幫助用戶 [benefit]。 -->

[Product Name] 是專為 _______ 打造的 **_______**。透過 _______，幫助用戶 _______。

**核心價值主張：** 「一句話總結你的產品為什麼值得存在。」

<!-- 例：Wordhenge 的核心價值主張是「只要寫，就自動記錄。」 -->

---

## Problem Statement

### 現有解決方案的痛點

<!-- 列出目標用戶目前怎麼解決這個問題，以及每個方案的不足之處。 -->
<!-- 這個表格幫助你論證「為什麼需要一個新產品」。 -->

| 現有方案 | 問題 |
|----------|------|
| [方案 A] | [痛點] |
| [方案 B] | [痛點] |
| [方案 C] | [痛點] |

### 用戶心聲

<!-- 引用真實的用戶反饋（Reddit、論壇、App Store 評論等）來佐證痛點。 -->
<!-- 這比你自己說「用戶需要 X」有說服力得多。 -->

> *"[引用一段真實用戶的評論或反饋]"*

---

## Target Audience

### Primary Persona: [人物名稱]

<!-- 為你的主要目標用戶建立一個具體的 persona，讓開發時所有決策都有依據。 -->

- **年齡：** ___
- **職業：** ___
- **工具：** ___（他們目前用什麼？）
- **痛點：**
  - ___
  - ___
- **目標：**
  - ___
  - ___

### Secondary Persona: [人物名稱]（可選）

- ___

---

## Core Features (MVP)

<!-- 用表格列出 MVP 的功能。每個功能給一個 Priority（P0 = 必須有，P1 = 應該有，P2 = 可以有）。 -->
<!-- 按產品的主要組件分組（例如 frontend、backend、mobile app）。 -->

### 1. [組件名稱] — [簡短描述]

| Feature | Description | Priority |
|---------|-------------|----------|
| **[功能名]** | [做什麼] | P0 |
| **[功能名]** | [做什麼] | P1 |

### 2. [組件名稱] — [簡短描述]

| Feature | Description | Priority |
|---------|-------------|----------|
| **[功能名]** | [做什麼] | P0 |
| **[功能名]** | [做什麼] | P1 |

### 3. Onboarding Flow

<!-- 描述新用戶從第一次接觸到開始使用的完整流程。 -->

| Step | Description |
|------|-------------|
| 1 | [第一步] |
| 2 | [第二步] |
| 3 | [第三步] |

---

## Privacy & Data Principles

<!-- 即使你的產品不像 Wordhenge 那樣涉及敏感資料，也值得在 PRD 中明確寫出你收集什麼、不收集什麼。 -->
<!-- 這能幫助你在開發時做出一致的決策，也方便日後撰寫 Privacy Policy。 -->

| 收集 | 不收集 |
|------|--------|
| ✅ [資料項目]（用途說明） | ❌ [資料項目] |
| ✅ [資料項目] | ❌ [資料項目] |

---

## Milestones

<!-- 用 Phase 劃分里程碑，每個 Phase 包含可勾選的任務清單。 -->
<!-- 標記進度：✅ 完成 / 🔄 進行中 / ⬜ 未開始 -->
<!-- 時間估算寫在標題，但不要太精確（用 Week 而非天）。 -->

### MVP Milestones

#### Phase 0: Setup（Week 1）⬜

- [ ] 建立 repo + 開發環境
- [ ] 設定第三方服務（DB、Auth、CI/CD）
- [ ] 初始部署管線

#### Phase 1: [核心功能]（Week 2-3）⬜

- [ ] [任務 1]
- [ ] [任務 2]
- [ ] [任務 3]

#### Phase 2: [次要功能]（Week 4-5）⬜

- [ ] [任務 1]
- [ ] [任務 2]

#### Phase 3: Polish & Beta（Week 6）⬜

- [ ] Error handling + edge cases
- [ ] Beta 版發布
- [ ] 邀請測試者

#### Phase 4: Public Launch（Week 8+）⬜

- [ ] 收集 Beta 反饋並修正
- [ ] 正式上架 / 發布

**驗證指標：** [怎樣算成功？例：有多少用戶使用了這個功能？]

<!--
  例（來自 Wordhenge）：
  Phase 5: Public Profile + Gamification
  目標：讓寫作成就可分享、可展示。
  驗證指標：有多少用戶主動分享 profile 連結？
-->

---

## Launch Plan（可選）

<!-- 描述產品從「做完了」到「用戶開始用」的完整計劃。 -->
<!-- B2B 和 B2C 的 launch 策略差異很大，以下涵蓋兩者常見的面向。 -->

### Launch 策略

| 項目 | 內容 |
|------|------|
| **Launch 類型** | [Big bang / Phased rollout / Soft launch / Beta → GA] |
| **目標日期** | [YYYY-MM-DD] |
| **目標用戶群** | [首批用戶是誰？] |

### Pre-Launch Checklist

<!-- 上線前必須完成的事項。依你的產品類型調整。 -->

- [ ] **品質門檻**：所有 P0 bug 已修復，核心流程 E2E 測試通過
- [ ] **監控與告警**：Error tracking（Sentry）、uptime monitoring 已設定
- [ ] **文件與支援**：用戶文件 / FAQ / Help center 就緒
- [ ] **法務合規**：Privacy Policy、Terms of Service 已上線
- [ ] **Analytics**：關鍵事件追蹤已埋點（sign-up、activation、核心功能使用）

<!--
  B2B 額外項目：
  - [ ] Sales enablement：pitch deck、demo script、battle cards 就緒
  - [ ] Pricing page 已上線
  - [ ] Onboarding flow 針對不同角色（admin vs. end user）已測試
  - [ ] SSO / SAML 整合已測試（如果有的話）
  - [ ] SLA / uptime 承諾已定義

  B2C / 獨立開發者額外項目：
  - [ ] App Store / Chrome Web Store 審查已提交
  - [ ] OG image / social preview 已設定
  - [ ] Landing page 已上線
-->

### Launch 後追蹤

| Metric | Day 1 目標 | Week 1 目標 | Month 1 目標 |
|--------|-----------|-------------|-------------|
| [例：註冊數] | [目標] | [目標] | [目標] |
| [例：Activation rate] | [目標] | [目標] | [目標] |
| [例：NPS / 滿意度] | — | [目標] | [目標] |

<!--
  例（Wordhenge）：
  | Metric | Day 1 | Week 1 | Month 1 |
  |--------|-------|--------|---------|
  | Extension 安裝數 | 20 | 50 | 100 |
  | Dashboard WAU | — | 30% | 30%+ |
  | Chrome Web Store 評分 | — | — | 4.5+ |
-->

---

## Future Feature Ideas

<!-- 把想到但還不會做的功能記在這裡，避免 scope creep。 -->

| Feature | Description | Priority |
|---------|-------------|----------|
| [功能] | [說明] | P2 |
| [功能] | [說明] | P3 |

---

## Success Metrics

### MVP 階段

| Metric | Target |
|--------|--------|
| [指標] | [目標值] |
| [指標] | [目標值] |

### 長期指標

| Metric | Target |
|--------|--------|
| [指標] | [目標值] |
| [指標] | [目標值] |

---

## Risks

### 技術風險

| Risk | Mitigation |
|------|------------|
| [風險] | [對策] |

### 產品風險

| Risk | Mitigation |
|------|------------|
| [風險] | [對策] |

---

## Open Questions

<!-- 把目前還沒有答案的問題記在這裡。定期回顧並更新狀態。 -->

| 問題 | 狀態 |
|------|------|
| [問題] | 需驗證 / 已解決 |

---

## Appendix: Competitive Analysis（可選）

<!-- 和競品的功能比較表。誠實列出優劣，幫助你找到差異化定位。 -->

| Product | Type | Price | [差異化特點 1] | [差異化特點 2] |
|---------|------|-------|----------------|----------------|
| [競品 A] | [類型] | [價格] | ❌ | ❌ |
| [你的產品] | [類型] | [價格] | ✅ | ✅ |

---

*End of PRD*
