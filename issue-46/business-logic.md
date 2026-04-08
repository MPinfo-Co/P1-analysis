# 業務邏輯分析：知識庫模組

> Epic：MPinfo-Co/P1-project#69
> SA Issue：MPinfo-Co/P1-analysis#46
> Brainstorm 與決策理由全文：[`../../../P1-code/docs/superpowers/specs/2026-04-02-knowledge-base-design.md`](../../../P1-code/docs/superpowers/specs/2026-04-02-knowledge-base-design.md)（以下簡稱 **brainstorm spec**）
> SD 工作拆解與 TestPlan：[`SD-WBS.md`](./SD-WBS.md)

> 本文件聚焦**業務邏輯**。SD 層的實作細節（函式名、檔名、prompt 結構、token 估算、builder 內部演算法、Pydantic 驗證規則）一律略過，請到 brainstorm spec 或 SD-WBS 查閱。

---

## 1. 背景與問題

MP-Box AI 分析時不認識公司環境，無法區分「正常行為」與「異常行為」。例如 AD Server 的境外連線是正常的，但 AI 會報為異常。

**使用者實際痛點（2026-04-07 確認）：**

1. **AD Server 類事件天天出現但其實是誤報** — Haiku 不知道哪些 IP 是 AD Server、不知道 DC 對外存取 80/443 是 Windows Update 同步、不知道 DC 收到大量 4625 失敗登入是服務客戶端的正常副作用。
2. **同件事隔天同樣發生但被拆成兩筆事件** — 屬於跨日延續的既有 bug（`pro_task.py` 沒讀 Sonnet 輸出的 `continued_from_match_key`），**不在本 Epic 範圍**，由獨立 fix Issue 處理。

**解決方向：** 讓使用者在前端維護公司環境資料（資產 / 帳號 / 白名單 / 網段 / 分析規則），存入 DB，AI 分析時自動注入 prompt 提供脈絡。

---

## 2. Use Cases

### UC-1：管理員建立並維護知識庫

**Actor：** 具有「KB 管理」角色的使用者

**前置條件：** 已登入且擁有 KB 管理角色

**主要流程：**
1. 管理員進入「知識庫」頁面，點擊「新建」
2. 填入 KB 名稱、描述
3. 系統建立 `knowledge_bases` 一筆紀錄（`analysis_rules` 預設 NULL），記錄 `created_by` / `updated_by` = 當前使用者
4. 進入 KB 詳情頁，使用四個資料表 Tab 維護：
   - **資產表**（kb_assets）：IP / hostname / purpose / criticality / notes
   - **帳號清單**（kb_accounts）：username / account_type / notes
   - **安全 IP 白名單**（kb_whitelist）：ip_or_cidr / reason / notes
   - **網段規劃**（kb_networks）：cidr / zone_name / description / notes
5. 在 KB 詳情頁的「分析規則」多行文字框填入自由文字規則（選填）
6. 儲存時系統更新 `updated_by` / `updated_at`
7. **生效時點**：儲存後，下一次 Flash Task 自動使用。UI 必須顯示提示「變更將在最晚 {FLASH_INTERVAL_MINUTES} 分鐘後生效」

**驗收：** 建立的 KB 在列表頁可見；四張資料表的 CRUD 都可運作；分析規則可儲存與顯示；`updated_by` 正確記錄最後修改人；UI 有生效提示。

---

### UC-2：管理員設定 KB ↔ AI 夥伴綁定

**Actor：** 具有「KB 管理」角色的使用者

**主要流程：**
1. 管理員進入 KB 詳情頁的「綁定設定」Tab
2. 選擇要綁定的 AI 夥伴（MVP 只有 `security`）
3. 系統寫入 `kb_ai_partner_bindings`，`enabled` 預設 true
4. 管理員可切換 `enabled` 開關

**`enabled` 欄位的業務語義：**

`enabled` 與「刪除綁定」不同：
- **刪除綁定** — 永久移除，歷史紀錄消失
- **停用綁定（enabled=false）** — 暫停但保留綁定，用於「維護期間暫停 KB 注入、確認 AI 行為後再恢復」的情境

Flash Task 只載入 `enabled=true` 的綁定。停用的綁定在列表上仍可見、可一鍵恢復。

**驗收：** 多個 KB 可同時綁定到同一 AI 夥伴；綁定後下一次 Flash Task 自動拉取注入；停用的綁定不被載入但可恢復。

---

### UC-3：Flash Task 自動注入 KB context

**Actor：** Celery Beat（系統）

**觸發：** 每 `FLASH_INTERVAL_MINUTES`（預設 20 分鐘）

**抽象流程：**
1. Flash Task 開始時，載入所有綁定且 `enabled=true` 的 KB
2. 依據 KB 白名單對 raw log 做預標記（見 UC-4）
3. 將 KB 內容組成自然語言 context 字串
4. 呼叫 Haiku 分析時，將 context 字串注入 AI 的背景知識
5. Haiku 回傳事件，後續流程同現況

**降級行為（業務要求）：**
- KB 綁定為空 → 不注入 KB，分析流程正常執行
- DB 查詢失敗 / KB 組裝失敗 → 視為 KB 為空，分析流程不中斷（log warning）

> 實作層的流程圖（含函式名、檔名、block 陣列結構、token 估算、是否啟用 prompt caching）見 **brainstorm spec** §「Prompt 結構與快取決策」、§「KB context 壓縮格式」。

**驗收：** 知識庫為空 / DB timeout / context 組裝例外三種情境，Flash Task 都能完成；綁定的 KB 內容會出現在 Haiku 看到的背景知識中。

---

### UC-4：Flash Task 預彙總時標記白名單

**Actor：** 系統（Flash Task）

**業務規則：**
1. 載入 KB 後，取出所有 `kb_whitelist` 條目作為 CIDR 清單
2. 對 FortiGate raw log 檢查 `srcip` / `dstip` 是否落在任一白名單 CIDR，若是則標記為白名單命中
3. 預彙總時，每個 FortiGate 群組 summary 新增兩個欄位：
   - `whitelisted_count`：群組內被標記的 log 數
   - `whitelisted_ratio`：whitelisted_count / total_count
4. Haiku 收到含這兩個欄位的 summary，依照 prompt 規則處理：
   > 若摘要的 `whitelisted_ratio >= 0.8`，代表此群組大多來自 KB 白名單（已知良性來源），star_rank 降一階，但異常模式仍須回報

**範圍限制：** 僅 FortiGate 三條彙總線適用。Windows log 不套用 IP 白名單；Windows 的等效語義由 `kb_accounts.account_type` 與 `analysis_rules` 提供。

**不外洩保證：** 白名單標記是 raw log 的臨時欄位，事件組裝時不複製、不傳到前端、不寫入 DB。

> 實作層的標記函式位置、preaggregator 修改點、欄位命名細節見 **brainstorm spec** §「白名單標記點與彙總策略」。

**驗收：** 白名單 IP 命中時 summary 含 `whitelisted_count > 0`；白名單為空時 `whitelisted_count = 0`；Windows log 不會出現白名單欄位；Haiku 對高比例白名單群組產出較低 star_rank。

---

### UC-5：分析規則（analysis_rules）注入

**Actor：** 系統（Flash Task）

**前置：** 管理員已在 KB 上填寫 `analysis_rules` 自由文字（UC-1 步驟 5）

**業務規則：**
1. KB context 字串尾端追加【分析規則】段落
2. 多 KB 綁定時，每個 KB 的 `analysis_rules` 依綁定順序串接
3. `analysis_rules` 為 NULL 或空字串時，【分析規則】段落整段省略
4. Haiku 看到【分析規則】段落 + 對應 prompt 規則：
   > 若事件符合 KB 提供的【分析規則】所述情境，依規則調整 star_rank（規則寫「視為正常」就降至 1 或 2、寫「star_rank ≤ N」就上限為 N）。規則沒涵蓋的事件正常判讀。

**範例規則：**
```
- AD Server (10.1.0.10, 10.1.0.11) 的 4625 高量為一般用戶端登入失敗,視為正常 (star_rank ≤ 2)
- AD Server 對外存取 80/443 為 Windows Update 同步,視為正常
- 備份伺服器 (10.1.0.50) 每晚 02:00-04:00 的 NetBIOS 廣播為備份任務,視為正常
```

**與 `kb_whitelist` 的互補關係：**

| 機制 | 作用層 | 適用 | 確定性 |
|------|--------|------|--------|
| `kb_whitelist` | 程式層（預彙總統計 `whitelisted_ratio`） | 僅 FortiGate 三線 | 高（精確 IP/CIDR 比對） |
| `analysis_rules` | LLM 層（Haiku 語義判讀 prompt） | Windows + FortiGate 都適用 | 中（依 Haiku 對自然語言規則的理解） |

兩者**不重複、不衝突**，可以同時標記。

> 決策理由（為什麼用 TEXT 欄位而不是結構化 enum、為什麼放 KB 層級而不是 asset 層級）見 **brainstorm spec** §「分析規則欄位設計」。

**驗收：** 含 `analysis_rules` 的 KB 注入後，Haiku 對符合規則的事件輸出 star_rank ≤ 規則指定值；規則為 NULL 時 KB context 不含【分析規則】段落；端對端 R7 案例（AD Server 4625 高量場景）的 star_rank ≤ 2。

---

### UC-6：角色權限控制 KB 讀寫存取

**讀取（所有登入使用者）：**
- 使用者所屬角色出現在 `kb_access_roles` 時，可讀取該 KB
- 無權限時列表不顯示該 KB，直接 GET 回 403

**寫入（建立 / 修改 / 刪除 KB 與其子表）：**
- **限定為具有「KB 管理」角色的使用者**
- 「KB 管理」是一個可由系統 admin 授予的新角色（非寫死 admin）
- 任何具此角色的使用者皆可管理所有 KB（不侷限於自己建立的）

**建立者離職處理：**
- 若 KB 的 `created_by` 指向的使用者被停用，KB 仍可被其他「KB 管理」角色修改
- `updated_by` 正常更新為當前操作者
- 系統不需要主動轉移 `created_by`（保留歷史紀錄）

**驗收：** 無「KB 管理」角色的使用者無法寫入；停用使用者建立的 KB 仍可被其他管理員修改；列表頁僅顯示當前使用者可讀的 KB。

---

## 3. 資料模型

### 3.1 新增 6 張 table 的關係圖

```
┌──────────────────────┐
│   knowledge_bases    │
├──────────────────────┤
│ id              PK   │
│ name                 │
│ description          │
│ analysis_rules  TEXT │  ← Pain 2 解法
│ created_by      FK   │ ──► users.id
│ updated_by      FK   │ ──► users.id  ← 最後修改人
│ created_at           │
│ updated_at           │
└──────────┬───────────┘
           │ 1:N
   ┌───────┼─────────────┬─────────────┬──────────────┬───────────────────┬──────────────────────┐
   ▼       ▼             ▼             ▼              ▼                   ▼                      ▼
┌────────┐ ┌─────────┐ ┌────────────┐ ┌───────────┐ ┌──────────────┐ ┌─────────────────────────┐
│kb_assets│ │kb_accounts│ │kb_whitelist│ │kb_networks│ │kb_access_roles│ │kb_ai_partner_bindings  │
├────────┤ ├─────────┤ ├────────────┤ ├───────────┤ ├──────────────┤ ├─────────────────────────┤
│id    PK│ │id    PK │ │id       PK │ │id      PK │ │id         PK │ │id                  PK   │
│kb_id FK│ │kb_id FK │ │kb_id    FK │ │kb_id   FK │ │kb_id      FK │ │kb_id               FK   │
│ip      │ │username │ │ip_or_cidr  │ │cidr       │ │role          │ │ai_partner_type ENUM     │
│hostname│ │acct_type│ │reason      │ │zone_name  │ │created_at    │ │  ('security')           │
│purpose │ │  ENUM   │ │notes       │ │description│ └──────────────┘ │enabled            bool  │
│critical│ │notes    │ └────────────┘ │notes      │                  │created_at               │
│notes   │ └─────────┘                └───────────┘                  └─────────────────────────┘
└────────┘
```

### 3.2 與既有 table 的關聯

- `knowledge_bases.created_by` / `updated_by` → `users.id`
- `kb_access_roles.role` 對接既有 `roles` 表（存放方式待 SD 決定，見 §5.2）
- KB 模組與 `security_events` / `log_batches` / `flash_results` **不在 schema 層相連**，由 Flash Task 的程式邏輯組合

### 3.3 ENUM 值定義

| 表 | 欄位 | 值 |
|----|------|----|
| `kb_accounts` | `account_type` | `normal` / `privileged` / `service` |
| `kb_assets` | `criticality` | `low` / `medium` / `high`（SD 階段決定是否需要 `critical`） |
| `kb_ai_partner_bindings` | `ai_partner_type` | `security`（MVP 只定一值） |

> FK cascade、IP/CIDR 格式驗證、Pydantic schema 細節見 **SD-WBS** B1.1~B1.3。

### 3.4 租戶範圍

KB **全公司共用**（MP-Box 為單租戶部署）。所有 KB 對所有使用者可見（依角色過濾讀取權限），不做 per-department 或 per-user scope。

---

## 4. 關鍵業務流程

```
[Celery Beat]
     │
     ▼
[Flash Task]
     │
     ├─► 載入 enabled=true 的綁定 KB（含四張子表 + analysis_rules）
     │
     ├─► 以 KB 白名單對 raw log 做預標記（僅 FortiGate）
     │
     ├─► 組出 KB context 字串（若 KB 為空或組裝失敗 → 空字串，降級）
     │
     ├─► 預彙總（summary 新增 whitelisted_count / whitelisted_ratio）
     │
     ▼
[Haiku 分析]
     │
     ├─► 背景知識 = 系統指令 + KB context
     ├─► 輸入 = 預彙總 summary
     │
     ▼
[事件輸出] → 後續 group_key 合併、累計（同現況）
```

> 含函式名 / 檔名 / block 陣列結構的實作流程圖見 **brainstorm spec** §「Prompt 結構與快取決策」。

---

## 5. 容量假設與非功能性需求

### 5.1 MVP 容量預設值

本 Epic MVP 以「單一全公司 KB」為設計前提：

| 項目 | MVP 預設值 | 硬上限 | 超過硬上限時行為 |
|------|-----------|--------|------------------|
| 公司 KB 數量 | 1 | — | — |
| 資產 (`kb_assets`) | ~20 筆 | 50 | KB context 截斷，顯示「還有 N 筆未顯示」，UI 顯示警告提示使用者精簡 |
| 帳號 (`kb_accounts`) | ~30 筆 | 50 | 同上 |
| 白名單 (`kb_whitelist`) | ~15 筆 | 50 | 同上 |
| 網段 (`kb_networks`) | ~10 筆 | 50 | 同上 |
| 分析規則 (`analysis_rules` TEXT) | 10~20 條條列 | 無硬上限 | — |

**容量設計前提：** 總 KB context 約 ~1,200~1,400 tokens（佔 Haiku 單次 ~32K 輸入的 ~4%），不影響既有 prompt 預算。

> token 估算細節、builder 硬上限處理、排序與去重規則見 **brainstorm spec** §「KB context 壓縮格式」。

### 5.2 非功能性需求

| 項目 | 要求 |
|------|------|
| **KB 載入負載** | 預期輕微。每 20 分鐘 × 1 partner × DB 查詢（含 4 張子表 JOIN），不需額外記憶體快取 |
| **生效延遲** | KB 儲存後，下一次 Flash Task 即生效（最晚 `FLASH_INTERVAL_MINUTES` 分鐘）。UI 必須顯示此延遲提示 |
| **降級可用性** | DB 查詢失敗 / context 組裝失敗時，Flash Task 仍須完成（視為 KB 為空） |
| **Audit Log** | MVP 不做完整 audit log。但 schema 須有 `created_by` / `updated_by` / `created_at` / `updated_at` 支援「誰最後動過」的基本追溯 |

---

## 6. 角色權限設計

### 6.1 新增「KB 管理」角色

本 Epic 需要在既有 `roles` 表新增一個角色：**「KB 管理」**（role name 待 SD 命名，建議 `kb_manager`）。此角色由系統 admin 授予，具備 KB 建立 / 修改 / 刪除 / 綁定設定 / 存取設定的完整寫入權限。

### 6.2 `kb_access_roles.role` 存放方式（待 SD 決定）

| 選項 | 做法 | 優缺 |
|------|------|------|
| A | `role VARCHAR`，存 `roles.name` | 簡單；角色重新命名會孤兒化 |
| B | `role_id BIGINT FK → roles.id` | 嚴謹；需處理角色刪除時的 cascade |

**SA 推薦 B**，MVP 接受 A。

### 6.3 權限矩陣

| 操作 | 無角色使用者 | 一般使用者（所屬角色在 `kb_access_roles`） | KB 管理角色 |
|------|-------------|------------------------------------------|------------|
| GET KB 列表 | 空列表 | 僅顯示可讀 KB | 全部 KB |
| GET KB 詳情 | 403 | 依 `kb_access_roles` | 所有 KB |
| POST / PUT / DELETE KB | 403 | 403 | ✓ |
| 綁定設定 / 存取設定 | 403 | 403 | ✓ |

---

## 7. 設計決策（簡表）

所有決策的完整理由請見 **brainstorm spec**。

| 問題 | 決策 | 一句話理由 |
|------|------|----------|
| 白名單實作位置 | 預彙總前 in-place 標記 + 群組統計 `whitelisted_count/ratio`，不過濾 | 完整可見，不因 `top_src_ips` 截斷而漏算 |
| 白名單作用範圍 | 僅 FortiGate 三條彙總線 | Windows 等效語義由 `account_type` / `analysis_rules` 提供 |
| `ai_partner_type` | ENUM MVP 只定 `security` | 其他類型等需要再 migration |
| KB 刪除邏輯 | 硬刪除 + 二次確認 + FK cascade | 內部管理員使用，soft delete 不值得增加複雜度 |
| Prompt caching | **不啟用** | Haiku 最小門檻 2,048 tokens，現有靜態區塊 ~1,800 不夠 |
| KB 注入位置 | Haiku system message（block 陣列） | 語義對齊、避免與動態 user message 混淆 |
| KB context 格式 | 自然語言條列（非 JSON） | Token 效率高、Haiku 注意力分布最佳 |
| Pain 2（AD Server 誤報）解法 | `knowledge_bases.analysis_rules` TEXT 欄位 | 維護成本最低、表達彈性最高、跨 Windows/FortiGate 適用 |
| Pain 1（跨日拆兩筆）解法 | **獨立 fix Issue，跟本 Epic 解耦** | 修正既有死角而非新功能，改動局部無 schema 變動 |
| Audit Log 完整度 | MVP 只做 `created_by`/`updated_by`，不做 diff log | 內部使用、非合規場景、MVP 不值得 |
| 租戶範圍 | 全公司共用，不做 per-department/per-user | MP-Box 單租戶部署 |
| 寫入權限 | 新增「KB 管理」角色，非綁定到 admin | 便於授權，不把權限硬寫在 admin 上 |

---

## 8. 驗收條件

| # | 驗收條件 | 對應 Use Case |
|---|---------|--------------|
| 1 | 使用者可新建知識庫並維護四張資料表（資產/帳號/白名單/網段） | UC-1 |
| 2 | 知識庫可綁定 AI 夥伴（多對多），綁定後下次 Flash Task 自動注入 | UC-2 + UC-3 |
| 3 | 停用綁定（`enabled=false`）不被載入但可恢復 | UC-2 |
| 4 | 未綁定或空知識庫時，分析流程不受影響（降級跳過） | UC-3 降級行為 |
| 5 | 白名單 IP 命中時 summary 含 `whitelisted_count > 0`，且 Haiku 對高比例白名單群組降權 | UC-4 |
| 6 | `analysis_rules` 端對端驗收：填入「AD Server 4625 高量視為正常」規則，實際跑 Haiku 後對應事件 `star_rank ≤ 2` | UC-5 |
| 7 | 存取設定可指定角色，無權限角色無法讀取；無「KB 管理」角色無法寫入 | UC-6 |
| 8 | KB 修改後 UI 提示「變更將在最晚 {N} 分鐘後生效」 | UC-1 |
| 9 | `updated_by` 在每次修改時正確記錄 | UC-1 |
| 10 | pytest 數量 ≥ TestPlan 案例數，每個 test function 標注 TestPlan ID | — |

> TestPlan 細化案例（C1~C8 / W1~W6 / R1~R7 / CRUD / 降級）見 **SD-WBS**。

---

## 9. 範圍外（不在本 SA / Epic 內）

- **Pain 1 跨日延續修正**：`pro_task.py` 沒讀 Sonnet 輸出的 `continued_from_match_key`、`security_events.continued_from` FK 從未被填寫。獨立 fix Issue 在 P1-code repo 處理，與本 Epic 解耦。
- **按需查詢介面**：MVP 全量注入 KB context；未來若 KB 大到需要 scope-based 查詢，再做。
- **Sonnet (Pro Task) 階段注入 KB**：本階段僅 Flash Task 注入；Sonnet 是否注入待後續評估。
- **多 AI 夥伴類型**：`ai_partner_type` ENUM 只定 `security`，未來新增其他類型再 migration。
- **完整 Audit Log（含 diff）**：MVP 僅靠 `created_by` / `updated_by` 追溯「誰最後動過」。
- **多租戶 / per-department KB**：MP-Box 為單租戶部署，全公司共用 KB。
- **KB 匯入/匯出 / 範本庫**：未來考慮。
