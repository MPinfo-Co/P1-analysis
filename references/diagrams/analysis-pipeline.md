# 分析 Pipeline 流程

> 每日凌晨 02:00 由 Celery Beat 自動觸發，或由使用者手動上傳 CSV 觸發

```mermaid
sequenceDiagram
    participant Beat as Celery Beat
    participant Worker as Celery Worker
    participant FS as 檔案系統
    participant Flash as Gemini Flash
    participant Pro as Gemini Pro
    participant DB as PostgreSQL

    Beat->>Worker: 02:00 觸發 run_analysis_pipeline
    Note over Worker: Stage 0：準備
    Worker->>DB: 建立 analysis_session (status=running)
    Worker->>FS: 讀取 /var/log/mpbox/filtered/{today}.csv
    Worker->>DB: 建立 log_batches 紀錄

    Note over Worker: Stage 1：Flash 批次摘要
    Worker->>DB: flash_status = running
    loop 每批約 300 筆 log
        Worker->>Flash: 送出 log 批次 + 分析 prompt
        Flash-->>Worker: 回傳事件 JSON 陣列
        Worker->>DB: 寫入 flash_results.result_json
    end
    Worker->>DB: flash_status = completed

    Note over Worker: Stage 2：Pro 綜合分析
    Worker->>DB: pro_status = running
    Worker->>DB: 讀取所有 flash_results
    Worker->>Pro: 送出全部 JSON + system prompt（含命名規則 + 優先級規則）
    Pro-->>Worker: 回傳去重合併後的安全事件清單 JSON
    Worker->>DB: pro_status = completed

    Note over Worker: Stage 3：事件整合（Merge）
    Worker->>DB: merge_status = running
    Worker->>DB: 讀取昨日未完成的 security_events
    Worker->>Worker: 計算 match_key（event_type + 主要內網 IP）

    alt match_key 匹配（持續事件）
        Worker->>DB: UPDATE date_end, detection_count（保留 status、history）
    else match_key 不匹配（新事件）
        Worker->>DB: INSERT security_event (status=未處理)
    end

    Worker->>DB: session.status = completed
```

## 事件整合規則（match_key）

```python
match_key = f"{event_type.lower().replace(' ', '_')}::{primary_internal_ip}"
# 範例："dns_c2_通訊::192.168.10.20"
```

| 情境 | 今日有 | DB 有 | DB 狀態 | 動作 |
|------|-------|------|--------|------|
| 新事件 | ✓ | ✗ | — | INSERT，status=未處理 |
| 持續事件 | ✓ | ✓ | 未處理/處理中 | UPDATE date_end + detection_count |
| 持續但已擱置 | ✓ | ✓ | 擱置 | UPDATE date_end + detection_count，status 不動 |
| 復發事件 | ✓ | ✓ | 已完成 | INSERT 新事件（不影響舊紀錄） |
| 消失事件 | ✗ | ✓ | 任何 | 不動，保留原紀錄 |

**不可覆蓋欄位**：`current_status`、`event_history`、`resolution`、`id`
