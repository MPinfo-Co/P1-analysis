# SD WBS：知識庫模組

> Epic：MPinfo-Co/P1-project#69
> SA Issue：MPinfo-Co/P1-analysis#46

## 工作項目

| # | 類型 | 說明 |
|---|------|------|
| **B1** | 後端 schema | 6 張新 table 的 SQLAlchemy model（`knowledge_bases` 含 `analysis_rules` TEXT 欄位、`created_by` / `updated_by` FK→users.id、`kb_assets` / `kb_accounts` / `kb_whitelist` / `kb_networks` / `kb_ai_partner_bindings` / `kb_access_roles`） |
| B1.1 | migration | Alembic migration script，含 ENUM 定義（`account_type`、`criticality`、`ai_partner_type`） |
| B1.2 | migration | FK cascade（KB 刪除連動子表） |
| B1.3 | 驗證 | Pydantic schema 對 `kb_assets.ip` / `kb_whitelist.ip_or_cidr` / `kb_networks.cidr` 的格式驗證（用 `ipaddress` 模組） |
| B1.4 | seed | 新增「KB 管理」角色（建議 `role.name = 'kb_manager'`）到 `roles` 表 seed 或 migration data |
| B1.5 | 欄位紀錄 | `knowledge_bases` 與四張子表的所有寫入操作須同步更新 `updated_by` = 當前使用者、`updated_at` = 當下時間（SQLAlchemy event listener 或 service 層統一處理） |
| **B2** | 後端服務層 | 新建 `backend/app/services/kb_repository.py`：`load_kbs_for_partner(partner_type)`（只載入 `enabled=true` 的綁定）、`load_kb_whitelist_cidrs(kbs)` |
| B2.1 | 後端服務層 | 新建 `backend/app/services/kb_context_builder.py`：`build_kb_context(kbs) -> str`，含樣板、排序、去重、硬上限 50、例外回傳 `""` |
| **B3** | Flash Task 整合 | 修改 `backend/app/tasks/flash_task.py::_process_batch`：載入綁定 KB → 呼叫 `_mark_whitelist` → 呼叫 `build_kb_context` → 把 `kb_context_text` 傳到 `_process_chunk` → `analyze_chunk` |
| B3.1 | Flash Task 整合 | 在 `flash_task.py` 或 `log_preaggregator.py` 新增 `_mark_whitelist(logs, cidrs)` 函式 |
| B3.2 | preaggregator 修改 | 修改 `_aggregate_deny_external` / `_aggregate_deny_internal` / `_aggregate_warning` 三函式：每個 summary 新增 `whitelisted_count` / `whitelisted_ratio` 欄位 |
| B3.3 | claude_flash 修改 | `SYSTEM_PROMPT` 拆成 `SYSTEM_PROMPT_BASE`；`analyze_chunk` 簽名加入 `kb_context_text=""`；`system` 改為 block 陣列；prompt 規則新增 `whitelisted_ratio >= 0.8` 與 `analysis_rules` 處理規則 |
| **B4** | REST API | 11 組 endpoint（CRUD × 4 表 + bindings + access）。詳細路徑見 `business-logic.md` 第 8 章與下方備註 |
| B4.1 | REST API | KB CRUD：`GET/POST /api/knowledge-bases`、`GET/PUT/DELETE /api/knowledge-bases/{id}`，PUT 包含 `analysis_rules` 欄位；回傳含 `created_by` / `updated_by` / `updated_at` |
| B4.2 | REST API | 子資源 CRUD：`/api/knowledge-bases/{id}/{assets|accounts|whitelist|networks}`；子資源寫入時同步更新父 KB 的 `updated_by` / `updated_at` |
| B4.3 | REST API | 綁定設定：`GET/POST/PUT/DELETE /api/knowledge-bases/{id}/bindings`；PUT 支援切換 `enabled`（與刪除綁定為不同語義） |
| B4.4 | REST API | 存取設定：`GET/POST/DELETE /api/knowledge-bases/{id}/access` |
| B4.5 | REST API | 角色權限 dependency：**讀取** → 檢查 `kb_access_roles`；**寫入（含綁定/存取設定）** → 限定 `kb_manager` 角色，非綁定到系統 admin |
| B4.6 | REST API | 提供 `GET /api/system/flash-interval` 回傳 `FLASH_INTERVAL_MINUTES`，供前端顯示生效時點提示（避免前端寫死分鐘數） |
| **B5** | 後端測試 | `kb_context_builder` 單元測試 C1~C8（見 TestPlan） |
| B5.1 | 後端測試 | `_mark_whitelist` + preaggregator whitelist 統計單元測試 W1~W6 |
| B5.2 | 後端測試 | Flash Task 整合測試（KB 注入路徑 + 三種降級情境 + `enabled=false` 綁定不被載入） |
| B5.3 | 後端測試 | API 整合測試（CRUD + 權限 + `updated_by` 正確記錄） |
| B5.4 | 後端測試 | **R1~R7 端對端測試（含 R7 AD Server 4625 高量場景）** |
| **F1** | 前端 | `KnowledgeBase/` 列表頁從 mock data 改串 `GET /api/knowledge-bases`；顯示 `updated_by` / `updated_at`（「最後由 X 於 Y 修改」） |
| F1.1 | 前端 | KB 詳情頁：三個 Tab（資料表 / 綁定設定 / 存取設定）+ 「分析規則」多行文字框；**頂部生效時點提示 banner**：「變更將在最晚 {N} 分鐘後生效」（N 讀自 `/api/system/flash-interval`） |
| F1.2 | 前端 | 資料表 Tab：四張資料表的 CRUD UI（表格 + 編輯 dialog）；**接近硬上限 50 時顯示黃色警告**，達上限時禁止新增並顯示紅色提示「請精簡後再新增」 |
| F1.3 | 前端 | 「KB 管理」角色之外的使用者：寫入按鈕（新建/編輯/刪除/綁定設定/存取設定）隱藏或停用 |
| F2 | 前端 | 綁定設定 Tab：AI 夥伴清單載入 + 多對多 binding UI + **enabled 開關（toggle 樣式，視覺上明確區分「停用」與「刪除」；停用狀態仍顯示於列表但 grayed out）** |
| F3 | 前端 | 存取設定 Tab：角色清單 + 勾選 |
| F4 | 前端 | KB 刪除二次確認彈窗（顯示影響範圍：N 筆資產、M 筆規則） |
| F5 | 前端 | `analysis_rules` 多行文字框（monospace 字型，輔助使用者撰寫條列） |
| **T1** | 測試 | TestPlan 案例（SD 階段細化） — 詳見下方分組 |
| **T2** | 測試 | PG 階段必跑：R7（AD Server 4625 → star_rank ≤ 2）、C5（KB 全空 → 管線不中斷） |

---

## TestPlan 案例分組（SD 階段細化編號 T1~Tn）

### KB context builder（C1~C8）

| ID | 案例 | 預期 |
|----|------|------|
| C1 | 單一 KB，四段都有資料 | 輸出含四段標題與條目 |
| C2 | 單一 KB，僅 assets 段有資料 | 輸出僅含 assets 段，其他段不出現空標題 |
| C3 | 兩個 KB 綁定，重複 IP | 後綁定的覆蓋前者，不重複出現 |
| C4 | assets 條目超過 50 | 截斷並追加「還有 N 筆未顯示」 |
| C5 | KB 全空 / 未綁定 | 回傳 `""`，`system_blocks` 只剩 base |
| C6 | builder 函式拋例外 | 回傳 `""`，Flash Task 仍成功 |
| C7 | 條目有 None / 空字串欄位 | 不出現 `（）` 空括號或 `None` 字樣 |
| C8 | 條目排序 | criticality 高→低、account_type privileged→service→normal |

### 白名單標記（W1~W6）

| ID | 案例 | 預期 |
|----|------|------|
| W1 | 白名單 IP 出現在 `deny_internal` 群組 | summary 含 `whitelisted_count > 0` |
| W2 | 白名單 CIDR `10.1.0.0/16` 命中 `10.1.5.5` | log 被標記 `_whitelisted=True` |
| W3 | 白名單為空（KB 未綁定或 whitelist 表空） | 所有 summary 的 `whitelisted_count = 0`，管線不中斷 |
| W4 | Windows log 通過 `_mark_whitelist` | 不新增 `_whitelisted` 欄位 |
| W5 | `whitelisted_ratio >= 0.8` 的群組 | Haiku 輸出 `star_rank` 較對照組低一階 |
| W6 | `_attach_raw_logs` 後的事件 | 不含 `_whitelisted` 欄位 |

### 分析規則注入（R1~R7）

| ID | 案例 | 預期 |
|----|------|------|
| R1 | KB 含 `analysis_rules`（10 條規則） | KB context 含【分析規則】段落、規則內容完整出現 |
| R2 | `analysis_rules` 為 NULL | KB context 不含【分析規則】段落 |
| R3 | 兩個 KB 綁定，都有 `analysis_rules` | 兩段以空行串接出現，依綁定順序 |
| R4 | 規則含「視為正常」+ Haiku 收到符合規則的 log | 輸出 `star_rank ≤ 2` |
| R5 | 規則含「star_rank ≤ 3」+ Haiku 收到符合規則的 log | 輸出 `star_rank ≤ 3` |
| R6 | 規則沒涵蓋的事件 | Haiku 正常判讀，不受影響 |
| **R7** | **AD Server EventID 4625 高量場景（Pain 2 端對端）** | **star_rank 降至 ≤ 2，不被誤報為高風險** |

### CRUD / 角色權限 / 降級

| ID | 類型 | 案例（SD 階段細化） |
|----|------|---------------------|
| K1~K7 | KB CRUD | 新建 / 列表 / 詳情 / 更新 / 刪除 / 二次確認 / **K7 `updated_by` 於每次更新正確記錄** |
| A1~A4 | assets/accounts/whitelist/networks 各別 CRUD | — |
| A5 | 容量上限 | 接近 50 筆時 API 回應含警告欄位；達 50 筆時 POST 回 409 Conflict |
| B1~B4 | bindings | 新增綁定 / **B2 切換 `enabled=false` 後 Flash Task 不載入該 KB** / **B3 切回 `enabled=true` 後下次 Flash Task 正常載入** / B4 刪除綁定 |
| AC1~AC3 | access | 設定角色 / 無權限讀取回 403 / 無「KB 管理」角色寫入回 403 |
| AC4 | 權限 | 建立者被停用後，其他「KB 管理」角色仍可修改其 KB，`updated_by` 更新為新操作者 |
| D1~D3 | 降級 | DB timeout / migration 失敗 / builder 例外 |
| U1 | 前端 | KB 詳情頁頂部顯示「變更將在最晚 N 分鐘後生效」，N 值來自 `/api/system/flash-interval` |
| U2 | 前端 | 無「KB 管理」角色的使用者：寫入按鈕隱藏/停用 |

---

## 備註

### 設計決策（從 brainstorm / SA 帶入，不應在 SD 重新討論）

1. **不啟用 prompt caching** — 理由：Haiku 最小門檻 2,048 tokens，現有靜態區塊 ~1,800 tokens 不夠；Flash 20 分鐘間隔與 5m TTL 不匹配
2. **KB 注入位置：Flash Task system message（block 陣列）** — 不放 user message
3. **KB context 格式：自然語言條列 + 程式固定 builder 樣板** — 不用 JSON
4. **白名單實作：彙總前 in-place 標記 + 彙總時統計群組級欄位** — 不過濾、不外洩
5. **Pain 2 解法：`knowledge_bases.analysis_rules` TEXT 欄位** — 不在 `kb_assets` 加 `behavior_notes`
6. **知識庫硬刪除 + FK cascade** — 不做 soft delete
7. **寫入權限 = 新角色 `kb_manager`** — 不綁定到系統 admin；非此角色無論是否為建立者皆無法寫入
8. **租戶範圍：全公司共用** — 不做 per-department / per-user scope
9. **MVP 容量假設：1 個 KB，assets ~20 / accounts ~30 / whitelist ~15 / networks ~10；builder 硬上限 50**
10. **Audit Log：MVP 只靠 `created_by` / `updated_by` / `updated_at`，不做 diff log**
11. **綁定 `enabled` 欄位語義：停用 ≠ 刪除**；停用保留綁定供「維護期間暫停，之後恢復」用
12. **KB 更新生效時點：下一次 Flash Task（最晚 `FLASH_INTERVAL_MINUTES` 分鐘）**，前端必須顯示提示
13. **建立者離職處理：`created_by` 保留歷史，其他 `kb_manager` 角色仍可修改，`updated_by` 更新為新操作者**

### SD 階段需要決議的設計點

1. **`kb_access_roles.role` 欄位型別** — VARCHAR 字串 vs FK to `roles.id`。SA 推薦 FK，但接受 VARCHAR
2. **`kb_assets.criticality` ENUM 值** — `low/medium/high` vs `low/medium/high/critical`
3. **`kb_manager` 角色的 role name 與在 `roles` 表的 seed 方式** — migration data 或 init script
4. **`updated_by` 同步機制** — SQLAlchemy event listener 還是 service 層顯式更新；子資源寫入時如何帶動父 KB 的 `updated_by`
5. **`analysis_rules` 編輯 UI** — 單一文字框 / 結構化條列輸入元件 / Markdown 預覽
6. **前端資料表 CRUD UI 元件選擇** — MUI DataGrid 或自製 Table
7. **KB 刪除二次確認彈窗的影響範圍提示文字格式**
8. **`/api/system/flash-interval` 的回傳格式與快取策略**（前端首次載入 or 每頁載入都呼叫）
9. **容量上限觸發時 API 回應格式** — 409 Conflict 還是 200 + warning field

### 相依關係

- **本 Epic 與 Pain 1 修正解耦**：`pro_task.py` 跨日延續 bug 是另一個獨立 fix Issue（在 P1-code repo），不在本 SD 範圍
- **本 Epic 不影響 Sonnet (Pro Task)**：Sonnet 是否注入 KB 為後續評估，本 SD 不處理
- **本 Epic 與既有 user/role 系統有對接**：`kb_access_roles` 需依賴 `users` / `roles` / `user_roles` 已存在（已存在）
- **本 Epic 需新增 `kb_manager` 角色**：B1.4 在 `roles` 表新增，並由系統 admin 授予使用者
- **本 Epic 需新增系統設定 endpoint**：B4.6 `/api/system/flash-interval`，供前端讀取生效時點

### 範圍外

- 按需查詢介面（MVP 全量注入）
- Sonnet 階段注入 KB
- 多 AI 夥伴類型（`ai_partner_type` 只定 `security`）
- Pain 1 跨日延續修正
