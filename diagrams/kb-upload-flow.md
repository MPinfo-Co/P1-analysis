# 知識庫上傳流程

> 涵蓋兩種知識庫類型：非結構化文件（PDF/Word/TXT）和結構化資料表

## 非結構化文件上傳（RAG 路徑）

```mermaid
flowchart TD
    subgraph User["使用者"]
        UP["POST /api/kb/{id}/documents\n上傳 PDF / Word / TXT"]
    end

    subgraph API["FastAPI"]
        SAVE["存入 storage_path\n建立 kb_documents\n(status=pending)"]
        DISPATCH["dispatch Celery task\nprocess_kb_document(doc_id)"]
    end

    subgraph Worker["Celery Worker"]
        EXTRACT["文字擷取\nPDF → pdfplumber\nWord → python-docx\nTXT → 直接讀取"]
        CHUNK["分塊\n~500 tokens / 塊\n50 token overlap"]
        EMBED["對每個 chunk\n呼叫 Ollama nomic-embed-text\n取得 1536 維向量"]
        STORE["寫入 kb_doc_chunks\n(content + embedding)"]
        DONE["更新 kb_documents\nstatus=completed\nchunk_count=N"]
    end

    subgraph DB["PostgreSQL + pgvector"]
        KB_DOC[("kb_documents")]
        KB_CHUNKS[("kb_doc_chunks\n含 pgvector 欄位")]
    end

    UP --> SAVE
    SAVE --> KB_DOC
    SAVE --> DISPATCH
    DISPATCH --> EXTRACT
    EXTRACT --> CHUNK
    CHUNK --> EMBED
    EMBED --> STORE
    STORE --> KB_CHUNKS
    STORE --> DONE
    DONE --> KB_DOC
```

## 結構化資料表（SQL 查詢路徑）

```mermaid
flowchart LR
    subgraph User["使用者"]
        CREATE["POST /api/kb/{id}/tables\n建立資料表（定義欄位）"]
        ADD_ROW["POST /api/kb/{id}/tables/{tid}/rows\n逐筆新增資料"]
    end

    subgraph DB["PostgreSQL"]
        KT[("kb_tables\nkb_table_columns\nkb_table_rows")]
    end

    CREATE --> KT
    ADD_ROW --> KT
```

## AI 諮詢時的知識庫查詢順序

```mermaid
flowchart TD
    Q["使用者提問"] --> CTX
    CTX["1. 當前安全事件 context\n（一定有，直接注入）"] --> STRUCT
    STRUCT{"有對應的\n結構化資料？"}
    STRUCT -- 是 --> SQL["2. AI 生成 SQL\n查詢 kb_table_rows"]
    STRUCT -- 否 --> RAG["3. RAG 查詢\nembedding 相似搜尋\nkb_doc_chunks"]
    SQL --> REPLY["組合 context → 呼叫 Gemini Pro → 回覆"]
    RAG --> REPLY
```

| 查詢類型 | 來源 | 用途範例 |
|---------|------|---------|
| 當前事件 context | security_events（直接注入） | 事件標題、建議處置、處置紀錄 |
| 結構化查詢 | kb_table_rows（AI 生成 SQL） | 查詢受影響設備的型號、確認 IP 是否在白名單 |
| 非結構化 RAG | kb_doc_chunks（pgvector 相似搜尋） | 找到對應的 SOP、處置指南、歷史案例 |
