# MP-Box 資料庫 ER Diagram

> Schema 版本：v3 | 更新日期：2026-03-17
> 來源：`database/mpbox_postgresql_v3_drawsql.sql`

```mermaid
erDiagram
    %% === 使用者 / 角色 ===
    users {
        int id PK
        varchar name
        varchar email UK
        boolean is_active
    }
    roles {
        int id PK
        varchar name UK
        boolean can_access_ai
        boolean can_manage_accounts
        boolean can_manage_roles
        boolean can_edit_ai
    }
    user_roles {
        int user_id PK,FK
        int role_id PK,FK
    }

    %% === AI 夥伴 ===
    ai_partners {
        int id PK
        varchar name UK
        boolean is_builtin
        boolean is_enabled
        varchar model_name
        text system_prompt
    }
    role_ai_partners {
        int role_id PK,FK
        int partner_id PK,FK
    }

    %% === 知識庫 ===
    knowledge_bases {
        int id PK
        varchar name
        int created_by FK
    }
    role_kb_map {
        int role_id PK,FK
        int kb_id PK,FK
    }
    partner_kb_map {
        int partner_id PK,FK
        int kb_id PK,FK
    }
    kb_documents {
        int id PK
        int kb_id FK
        varchar file_name
        varchar file_type
        varchar processing_status
        int chunk_count
        int uploaded_by FK
    }
    kb_doc_chunks {
        int id PK
        int document_id FK
        int chunk_index
        text content
        vector embedding
        int token_count
    }
    kb_tables {
        int id PK
        int kb_id FK
        varchar table_name
        varchar source
        int created_by FK
    }
    kb_table_columns {
        int id PK
        int table_id FK
        varchar column_name
        varchar column_type
        int column_order
    }
    kb_table_rows {
        int id PK
        int table_id FK
        json row_data
    }

    %% === 分析 Pipeline ===
    log_batches {
        int id PK
        varchar source_file
        varchar device_name
        date batch_date
        int raw_log_count
        int filtered_count
    }
    analysis_sessions {
        int id PK
        int partner_id FK
        date analysis_date
        varchar triggered_by
        varchar status
        varchar flash_status
        varchar pro_status
        varchar merge_status
        int event_count
        int flash_token
        int pro_token
    }
    session_batch_map {
        int session_id PK,FK
        int batch_id PK,FK
    }
    flash_results {
        int id PK
        int session_id FK
        int batch_id FK
        int chunk_index
        int chunk_total
        json result_json
        int token_used
    }

    %% === 安全事件 ===
    security_events {
        int id PK
        int session_id FK
        varchar title
        varchar event_type
        smallint star_rank
        date date_start
        date date_end
        int detection_count
        varchar affected_summary
        varchar current_status
        json suggests
        json mitre_tags
        varchar match_key
    }
    event_history {
        int id PK
        int event_id FK
        int user_id FK
        text note
        varchar status_change
        timestamp deleted_at
    }

    %% === 關聯 ===
    users ||--o{ user_roles : ""
    roles ||--o{ user_roles : ""
    roles ||--o{ role_ai_partners : ""
    ai_partners ||--o{ role_ai_partners : ""
    users ||--o{ knowledge_bases : "created_by"
    roles ||--o{ role_kb_map : ""
    knowledge_bases ||--o{ role_kb_map : ""
    ai_partners ||--o{ partner_kb_map : ""
    knowledge_bases ||--o{ partner_kb_map : ""
    knowledge_bases ||--o{ kb_documents : ""
    users ||--o{ kb_documents : "uploaded_by"
    kb_documents ||--o{ kb_doc_chunks : ""
    knowledge_bases ||--o{ kb_tables : ""
    users ||--o{ kb_tables : "created_by"
    kb_tables ||--o{ kb_table_columns : ""
    kb_tables ||--o{ kb_table_rows : ""
    ai_partners ||--o{ analysis_sessions : ""
    analysis_sessions ||--o{ session_batch_map : ""
    log_batches ||--o{ session_batch_map : ""
    analysis_sessions ||--o{ flash_results : ""
    log_batches ||--o{ flash_results : ""
    analysis_sessions ||--o{ security_events : ""
    security_events ||--o{ event_history : ""
    users ||--o{ event_history : ""
```

## 領域說明

| 領域 | 資料表 | 說明 |
|------|-------|------|
| 使用者/角色 | users, roles, user_roles | 帳號管理與功能權限控制 |
| AI 夥伴 | ai_partners, role_ai_partners | 可自訂 system prompt 的 AI 角色；角色決定使用者可使用哪個 AI 夥伴 |
| 知識庫（非結構化） | knowledge_bases, kb_documents, kb_doc_chunks | PDF/Word/TXT → 分塊 → pgvector embedding，供 RAG 查詢 |
| 知識庫（結構化） | kb_tables, kb_table_columns, kb_table_rows | 人工維護的資料表（設備清單、IP 白名單等），供 AI 生成 SQL 查詢 |
| 知識庫存取控制 | role_kb_map, partner_kb_map | 哪些角色可讀取哪個知識庫；哪個 AI 夥伴綁定哪個知識庫 |
| 分析 Pipeline | log_batches, analysis_sessions, session_batch_map, flash_results | 每次分析工作的狀態追蹤與 Flash 中間結果 |
| 安全事件 | security_events, event_history | AI 產出的安全事件清單，附人工處置紀錄（軟刪除） |
```
