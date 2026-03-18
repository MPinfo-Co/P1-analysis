# Flash 中間 JSON Schema

> 定義 `flash_results.result_json` 的結構，以及最終寫入 `security_events` 的欄位對應

## Stage 1 Flash 輸出（每批次）

每次 Flash 呼叫回傳一個 JSON 陣列，存入 `flash_results.result_json`：

```json
[
  {
    "title": "暴力破解 — 行政伺服器遭持續密碼嘗試",
    "event_type": "暴力破解",
    "affectedSummary": "192.168.1.50 (WS-ADMIN)",
    "affected": "來源 IP 203.0.113.55，目標 192.168.1.50:445，服務 SMB",
    "starRank": 4,
    "desc": "【異常發現】\n10 分鐘內出現 312 次 4625 登入失敗...\n\n【摘要】\n...\n\n【發現】\n...\n\n【說明】\n...\n\n【修復】\n...",
    "suggests": [
      "立即封鎖來源 IP 203.0.113.55",
      "檢查 WS-ADMIN 帳號是否已遭鎖定"
    ],
    "mitre": [
      {"id": "T1110", "name": "Brute Force"},
      {"id": "T1110.001", "name": "Password Guessing"}
    ]
  }
]
```

## Stage 2 Pro 輸出（最終彙整）

Pro 在 Flash 輸出基礎上新增兩個欄位：

```json
[
  {
    "title": "暴力破解 — 行政伺服器遭持續密碼嘗試",
    "event_type": "暴力破解",
    "affectedSummary": "192.168.1.50 (WS-ADMIN)",
    "affected": "...",
    "starRank": 4,
    "desc": "...",
    "suggests": ["..."],
    "mitre": [{"id": "T1110", "name": "Brute Force"}],
    "sources": ["fw_chunk_003", "win_chunk_042"],
    "correlations": "防火牆與 Windows 日誌均發現 IP 203.0.113.55 的攻擊行為，時間重疊，判斷為同一攻擊"
  }
]
```

## Pro 輸出 → security_events 欄位對應

| Pro JSON 欄位 | security_events 欄位 | 備註 |
|--------------|---------------------|------|
| `title` | `title` | |
| `event_type` | `event_type` | |
| `affectedSummary` | `affected_summary` | |
| `affected` | `affected_detail` | |
| `starRank` | `star_rank` | |
| `desc` | `description` | |
| `suggests[]` | `suggests` (JSON array) | |
| `mitre[]` | `mitre_tags` (JSON array) | |
| `correlations` | 併入 `description` 末段 | |
| `sources[]` | `logs` (JSON array) | 存 chunk batch ID |
| 從 `title` 前綴 + affected 主要內網 IP | `match_key` | 格式：`event_type::primary_ip` |

## 欄位值規範

**`current_status` 允許值**：`未處理` / `處理中` / `擱置` / `已完成`

**`processing_status`（kb_documents）允許值**：`pending` / `processing` / `completed` / `failed`

**`triggered_by`（analysis_sessions）允許值**：`schedule` / `manual`

**`star_rank` 範圍**：1（資訊）~ 5（最高危）
