# MP-Box 實體分析

> 版本：v1 | 日期：2026-03-20
> 對應 issue：[P3-1]

---

## 各領域實體

### 1. 使用者 / 角色

#### users

- **用途**：系統使用者帳號，所有人工操作的身份來源。
- **關鍵欄位**：`id`, `name`, `email`(UK), `password_hash`, `is_active`
- **主要關係**：透過 `user_roles` 關聯角色；作為 `knowledge_bases.created_by`、`kb_documents.uploaded_by`、`kb_tables.created_by`、`event_history.user_id`、`security_events.assignee_user_id`（新增）的 FK 來源。

#### roles

- **用途**：功能權限群組，控制使用者可使用的系統功能。
- **關鍵欄位**：`id`, `name`(UK), `can_access_ai`, `can_manage_accounts`, `can_manage_roles`, `can_edit_ai`, `can_manage_kb`（**新增**，BOOLEAN，控制知識庫管理權限）
- **主要關係**：透過 `user_roles` 關聯使用者；透過 `role_ai_partners` 控制可用 AI 夥伴；透過 `role_kb_map` 控制可存取知識庫。

#### user_roles

- **用途**：使用者與角色的多對多關聯表。
- **關鍵欄位**：`user_id`(PK,FK), `role_id`(PK,FK)
- **主要關係**：FK 分別指向 `users` 與 `roles`。

---

### 2. AI 夥伴

#### ai_partners

- **用途**：可自訂 system prompt 的 AI 角色，每個夥伴對應一種分析情境（如資安專家、合規顧問）。
- **關鍵欄位**：`id`, `name`(UK), `is_builtin`, `is_enabled`, `model_name`, `system_prompt`
- **主要關係**：透過 `role_ai_partners` 決定哪些角色可使用；透過 `partner_kb_map` 綁定知識庫；為 `analysis_sessions.partner_id` 的 FK 來源。

#### role_ai_partners

- **用途**：角色與 AI 夥伴的多對多關聯表，決定某角色可使用哪些 AI 夥伴。
- **關鍵欄位**：`role_id`(PK,FK), `partner_id`(PK,FK)
- **主要關係**：FK 分別指向 `roles` 與 `ai_partners`。

---

### 3. 知識庫

#### knowledge_bases

- **用途**：知識庫容器，區分不同主題或來源的知識集合。
- **關鍵欄位**：`id`, `name`, `description`, `created_by`(FK)
- **主要關係**：擁有多個 `kb_documents` 與 `kb_tables`；透過 `role_kb_map` 控制角色存取；透過 `partner_kb_map` 綁定 AI 夥伴。

#### kb_documents

- **用途**：上傳至知識庫的非結構化文件（PDF / Word / TXT），供 RAG 查詢使用。
- **關鍵欄位**：`id`, `kb_id`(FK), `file_name`, `file_type`, `processing_status`, `chunk_count`, `uploaded_by`(FK)
- **主要關係**：屬於某個 `knowledge_bases`；擁有多個 `kb_doc_chunks`。

#### kb_doc_chunks

- **用途**：文件分塊後的內容與 embedding 向量，供 pgvector 語意搜尋。
- **關鍵欄位**：`id`, `document_id`(FK), `chunk_index`, `content`, `embedding`(vector), `token_count`
- **主要關係**：屬於某個 `kb_documents`。

#### kb_tables

- **用途**：人工維護的結構化知識表（設備清單、IP 白名單等），供 AI 生成 SQL 查詢。
- **關鍵欄位**：`id`, `kb_id`(FK), `table_name`, `source`, `created_by`(FK)
- **主要關係**：屬於某個 `knowledge_bases`；擁有多個 `kb_table_columns` 與 `kb_table_rows`。

#### kb_table_columns

- **用途**：結構化知識表的欄位定義（名稱、型別、排序）。
- **關鍵欄位**：`id`, `table_id`(FK), `column_name`, `column_type`, `column_order`
- **主要關係**：屬於某個 `kb_tables`。

#### kb_table_rows

- **用途**：結構化知識表的資料列，以 JSON 儲存每列內容。
- **關鍵欄位**：`id`, `table_id`(FK), `row_data`(JSON)
- **主要關係**：屬於某個 `kb_tables`。

#### role_kb_map

- **用途**：角色與知識庫的多對多關聯表，控制哪些角色可存取哪個知識庫。
- **關鍵欄位**：`role_id`(PK,FK), `kb_id`(PK,FK)
- **主要關係**：FK 分別指向 `roles` 與 `knowledge_bases`。

#### partner_kb_map

- **用途**：AI 夥伴與知識庫的多對多關聯表，決定 AI 夥伴可引用哪些知識庫做 RAG。
- **關鍵欄位**：`partner_id`(PK,FK), `kb_id`(PK,FK)
- **主要關係**：FK 分別指向 `ai_partners` 與 `knowledge_bases`。

---

### 4. 分析 Pipeline

#### log_batches

- **用途**：原始日誌匯入批次，記錄來源檔案與日誌數量統計。
- **關鍵欄位**：`id`, `source_file`, `device_name`, `batch_date`, `raw_log_count`, `filtered_count`, `expires_at`
- **主要關係**：透過 `session_batch_map` 關聯分析工作階段；被 `flash_results` 引用。

#### analysis_sessions

- **用途**：一次完整的 AI 分析工作階段，追蹤 Flash / PRO / Merge 各階段狀態與 token 消耗。
- **關鍵欄位**：`id`, `partner_id`(FK), `analysis_date`, `triggered_by`, `status`, `flash_status`, `pro_status`, `merge_status`, `event_count`, `flash_token`, `pro_token`
- **主要關係**：屬於某個 `ai_partners`；透過 `session_batch_map` 關聯日誌批次；產出多筆 `flash_results` 與 `security_events`。

#### session_batch_map

- **用途**：分析工作階段與日誌批次的多對多關聯表。
- **關鍵欄位**：`session_id`(PK,FK), `batch_id`(PK,FK)
- **主要關係**：FK 分別指向 `analysis_sessions` 與 `log_batches`。

#### flash_results

- **用途**：Flash 模型的分塊分析中間結果，後續由 PRO 模型合併產出最終事件。
- **關鍵欄位**：`id`, `session_id`(FK), `batch_id`(FK), `chunk_index`, `chunk_total`, `result_json`(JSON), `token_used`
- **主要關係**：屬於某個 `analysis_sessions`；關聯某個 `log_batches`。

#### similar_events（新增）

- **用途**：相似歷史案例記錄，由 PRO 模型於每日分析時依語意相似度、MITRE 技術重疊度自動寫入，供使用者參考過往處置經驗。
- **關鍵欄位**：
  - `id` - PK
  - `event_id`(FK → security_events) - 此相似案例所屬的目標事件
  - `similar_event_id`(FK → security_events, NULLABLE) - 若相似案例也存在於系統內，指向該事件；若為外部/歷史資料則為 NULL
  - `title`(VARCHAR) - 相似案例標題
  - `date`(DATE) - 相似案例發生日期
  - `similarity_pct`(INT) - 相似度百分比（0-100）
  - `summary`(TEXT) - 案例摘要
  - `outcome`(VARCHAR) - 處置結果狀態（已完成 / 擱置 等）
  - `resolved_at`(TIMESTAMP) - 結案時間
  - `resolved_by`(VARCHAR) - 處置人員
  - `resolution`(TEXT) - 處置方式描述
  - `created_at`(TIMESTAMP) - 寫入時間
- **主要關係**：`event_id` FK 指向 `security_events`（必填，一個事件可有多筆相似案例）；`similar_event_id` FK 指向 `security_events`（可為 NULL，當相似案例為系統內既有事件時填入）。

---

### 5. 安全事件

#### security_events

- **用途**：AI 分析產出的安全事件，包含事件描述、嚴重等級、建議措施、MITRE 標籤等完整資訊。
- **關鍵欄位**：`id`, `session_id`(FK), `title`, `event_type`, `star_rank`, `date_start`, `date_end`, `detection_count`, `affected_summary`, `current_status`, `suggests`(JSON), `mitre_tags`(JSON), `match_key`, `assignee_user_id`（**新增**，FK → users，事件負責人）
- **suggests JSON 結構**（擴充）：由原本的字串陣列 `["建議1", "建議2"]` 改為物件陣列，每項包含：
  ```json
  [
    {
      "text": "建議措施的完整描述文字",
      "urgency": "最推薦",
      "refs": ["T1562.002", "T1078"]
    },
    {
      "text": "第二項建議措施",
      "urgency": "次推薦",
      "refs": ["T1021"]
    },
    {
      "text": "第三項建議措施",
      "urgency": "可選",
      "refs": []
    }
  ]
  ```
  - `text`：建議措施文字（含操作步驟、溯源說明）
  - `urgency`：優先級，值為 `最推薦` / `次推薦` / `可選`
  - `refs`：相關參考（MITRE ATT&CK 技術編號等）
- **主要關係**：屬於某個 `analysis_sessions`；擁有多筆 `event_history`（人工處置紀錄）；擁有多筆 `similar_events`（相似案例）；`assignee_user_id` FK 指向 `users`。

#### event_history

- **用途**：安全事件的人工處置紀錄（備註、狀態變更），支援軟刪除。
- **關鍵欄位**：`id`, `event_id`(FK), `user_id`(FK), `note`, `status_change`, `deleted_at`
- **主要關係**：屬於某個 `security_events`；`user_id` FK 指向操作的 `users`。

---

## 範圍外（刻意排除）

| 實體 | 排除原因 |
|------|---------|
| `notification_settings` | 通知偏好設定屬於 AI 主動通知功能，規劃於 AI phase 再實作。 |
| `chat_sessions` / `chat_messages` | AI 對話紀錄屬於互動式分析功能，規劃於 Phase 5 實作。 |

---

## 變更摘要（相對於現有 schema v3）

### 新增欄位

| 資料表 | 欄位 | 型別 | 說明 |
|--------|------|------|------|
| `roles` | `can_manage_kb` | BOOLEAN, DEFAULT FALSE | 控制角色是否可管理知識庫（新增/編輯/刪除） |
| `security_events` | `assignee_user_id` | INT, FK → users, NULLABLE | 事件指派負責人 |

### 新增實體

| 資料表 | 說明 |
|--------|------|
| `similar_events` | 相似歷史案例，由分析 pipeline 自動寫入。欄位：`id`, `event_id`(FK), `similar_event_id`(FK, nullable), `title`, `date`, `similarity_pct`, `summary`, `outcome`, `resolved_at`, `resolved_by`, `resolution`, `created_at` |

### JSON 結構擴充

| 資料表 | 欄位 | 變更內容 |
|--------|------|---------|
| `security_events` | `suggests` | 由字串陣列改為物件陣列，每項結構為 `{ text, urgency, refs }`，其中 `urgency` 值為「最推薦 / 次推薦 / 可選」 |
