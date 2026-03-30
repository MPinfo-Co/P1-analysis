# 業務邏輯：安全事件清單 — SSB 串接完整實作

> 對應 Epic：MPinfo-Co/P1-project#50
> 對應 SA Issue：MPinfo-Co/P1-analysis#26

---

## Use Case

**角色：** 資安專家

**情境：** 每天上班後開啟 MP-BOX，查看昨晚 AI 分析好的安全事件清單，依嚴重度決定處置優先順序。

**前提：**
- 後端 Celery Beat 排程持續運行
- SSB 裝置可正常連線（192.168.10.48）
- 當天凌晨 Pro 已完成每日彙整

**主流程：**
1. 資安專家登入系統
2. 點擊 AI 夥伴（資安專家）進入安全事件清單頁
3. 清單顯示今日 AI 分析產出的所有安全事件，預設照嚴重度（星等）降冪排列
4. 依狀態、關鍵字、日期篩選，縮小範圍
5. 點擊事件進入詳情頁（詳情頁屬 Epic 2 範圍）

---

## 資料流

```
FortiGate / Windows Server / AD Server
  │
  ▼ syslog 協定（UDP/TCP 514）
SSB (syslog-ng Store Box, 192.168.10.48)
  │  所有設備 log 存入 logspace（每日約 600 萬筆原始資料）
  ▼ REST API 定時拉取（每 10 分鐘，Celery Beat）
後端：呼叫 /search/logspace/filter（帶 search_expression 過濾）
  │  每次查詢僅涵蓋最近 10 分鐘（約 4.2 萬筆），search_expression 再次過濾
  ▼ 直接丟入 Flash（不另存 log_entries）
Gemini 2.5 Flash（每 10 分鐘，分 chunk 分析）
  │  每 chunk 產出一筆 flash_results（JSON）
  ▼
flash_results table（DB 暫存當天所有 Flash 結果）
  │
  ▼ 每日凌晨，Celery Beat 觸發
Gemini 2.5 Pro（讀取當天所有 flash_results + 前一天事件清單）
  │  去重彙整，判斷新事件 vs 延續事件
  ▼
security_events table（每日快照寫入）
  │
  ▼ REST API
GET /api/events → 前端安全事件清單頁
```

---

## SSB API 連線規格

| 項目 | 值 |
|---|---|
| Base URL | `https://192.168.10.48/api/5/`（版本待部署時確認） |
| 認證方式 | POST `/login`，body: `username=&password=`，回傳結構見下方 |
| 請求 header | `Cookie: AUTHENTICATION_TOKEN=<token>` |
| SSL | 自簽憑證，需 `verify=False` |
| Session 管理 | Token 有效至 session timeout 或主動 `/logout`；需實作自動重新登入 |
| 暴力攻擊保護 | 10 次錯誤登入 / 60 秒 → port 443 封鎖 5 分鐘；Celery Task 重試策略須避免觸發 |
| 主要 endpoint | `GET /search/logspace/filter/<logspace_name>` |
| Logspace 名稱 | **待確認**（PG 階段執行 `/search/logspace/list_logspaces` 取得） |
| 帳號密碼 | **待確認**（部署時設定於 `.env`，不寫入程式碼） |

**所有 API 回傳結構：**

```json
{
  "result": <實際資料>,
  "error": { "code": null, "message": null },
  "warnings": []
}
```

**拉取參數：**

| 參數 | 說明 |
|---|---|
| `from` | 上次拉取結束的 unix timestamp（記錄於 `log_batches`） |
| `to` | 當下 unix timestamp |
| `search_expression` | 過濾條件（見下方） |
| `offset` | 分頁起始，從 0 開始 |
| `limit` | 每次最多 1000（SSB 上限） |

---

## Log 過濾策略

### MVP 階段：僅使用 REST API search_expression 過濾

每次 Celery Flash Task 帶入 `from`/`to` 時間範圍，將查詢範圍縮限至最近 10 分鐘（約 4.2 萬筆），再由 `search_expression` 過濾出資安相關 log。

**search_expression 規則須重新設計**，不沿用舊版 CSV 分析結果（格式不同、欄位對應不適用）。SD 階段需根據實際 syslog 欄位結構定義具體過濾條件，方向參考：
- FortiGate：保留 warning 以上嚴重度、deny/block 動作
- Windows Server：保留資安相關 EventID（4624, 4625, 4648 等）

### 後續優化（MVP 後評估）：加入設備層過濾

每日 600 萬筆原始資料全數存入 logspace，長期會造成 SSB 儲存壓力。待 MVP 驗證過濾規則後，評估在設備層（syslog-ng）設定前置過濾，將存入 logspace 的資料量降至 6~12 萬筆/日（預估 1-2% 為資安相關）。此階段規則需重新設計，舊版 `references/syslogng-filters.md` 僅供方向參考。

---

## SSB 回傳欄位 → Flash 處理對應

SSB `/filter` 每筆 log 的結構：

```json
{
  "stamp": 1711123200,
  "recvd": 1711123201,
  "host": "192.168.1.50",
  "program": "syslog-ng",
  "pid": "4408",
  "facility": 5,
  "pri": 3,
  "message": "...",
  "tag": [],
  "msgid": "",
  "dynamic": {
    ".sdata.win@18372.4.event_id": "4625"
  }
}
```

| SSB 欄位 | 用途 | 說明 |
|---|---|---|
| `stamp` | Flash 分析輸入 | log 產生時間（unix → datetime） |
| `host` | `log_batches.hosts` | 來源主機，批次結束後寫入 unique 清單 |
| `program` | Flash 分析輸入 | 來源程式 |
| `pri` | Flash 分析輸入 | 嚴重度（0=emergency, 7=debug） |
| `facility` | Flash 分析輸入 | syslog facility 編號 |
| `message` | Flash 分析輸入 | 原始訊息內容（含 FortiGate logid、Windows EventID 等） |
| `dynamic` | Flash 分析輸入 | Windows 事件的額外欄位（EventID 等） |

> **個別 log 不存入 DB**，直接累積至 chunk 大小後送 Flash。
> 相關 log 摘錄最終由 Flash/Pro 寫入 `security_events.logs`（JSON）。

---

## Celery 排程設計

### Flash Task（每 10 分鐘，可設定）

```
1. 呼叫 SSB API，from = 上次拉取 to timestamp（從 log_batches 取）
2. 分頁拉取（每次 limit=1000）直到無更多資料
3. 累積所有 log 後，依 chunk 大小（建議每 chunk 約 1000 筆）切分
4. 每個 chunk 丟入 Gemini Flash 分析
5. Flash 結果寫入 flash_results（含 chunk_index、chunk_total）
6. 寫入 log_batches 記錄本次批次元數據（hosts、筆數、時間範圍）
```

> `log_batches` 的來源欄位名稱（`source_file` vs `source_info`）與型別（VARCHAR vs JSON）待 TDD 階段與 entity-analysis.md 對齊確認。

觸發方式：**時間觸發**（每 10 分鐘），觸發間隔可設定於 `.env`。

### Pro Task（每日一次，預設凌晨 02:00，可設定）

```
1. 讀取當天所有 flash_results
2. 讀取前一天的 security_events（用於判斷延續事件）
3. 丟入 Gemini Pro 彙整去重
4. Pro 輸出寫入 security_events（每日快照）
5. 更新 daily_analysis 狀態
```

---

## 安全事件清單顯示需求

**欄位：**

| 欄位 | 來源 | 說明 |
|---|---|---|
| 事件標題 | `security_events.title` | |
| 嚴重度 | `security_events.star_rank` | 1-5 星，顯示為星等圖示 |
| 狀態 | `security_events.current_status` | DB 值（英文）對應 UI 顯示（中文）見下方 |
| 影響範圍摘要 | `security_events.affected_summary` | 單行短摘要，直接顯示於列表 |
| 影響範圍完整說明 | `security_events.affected_detail` | 點擊摘要後 popover 展開顯示完整內容 |
| 發生時間 | `security_events.date_start` | |

**`current_status` 對應表：**

| DB 值（英文） | UI 顯示（中文） |
|---|---|
| `pending` | 未處理 |
| `investigating` | 處理中 |
| `dismissed` | 擱置 |
| `resolved` | 已完成 |

**排序：** 預設照 `star_rank` 降冪排列（最嚴重優先）

**篩選條件：**

| 篩選項目 | 對應欄位 |
|---|---|
| 狀態 | `current_status` |
| 關鍵字 | `title`、`affected_summary`（模糊搜尋） |
| 日期區間 | `date_start`（from / to） |

分頁：每頁預設 20 筆，可設定。

---

## AI 輸出欄位格式規範

Flash 與 Pro 的 prompt 設計必須強制要求以下輸出格式，以確保 DB 欄位能正確儲存並顯示。

### `affected_summary`（影響範圍摘要）

- **長度限制**：20 字以內
- **格式**：`{主要對象}（{最關鍵補充}）`
- **範例**：
  - `172.16.1.112 → Domain Controllers`
  - `防火牆邊界（13:30~16:30）`
  - `全域 AD 稽核政策（mpdc19-01/02/hq）`

### `affected_detail`（影響範圍完整說明）

採【】標籤分段的半結構化格式：

```
【受影響對象】{受影響的設備、帳號、IP 清單}
【攻擊來源】{攻擊來源 IP 或主機}（有明確來源才填，否則省略此段）
【攻擊行為】{具體攻擊行為、log 數量、EventID 等}
【時間範圍】{特定時間窗}（有特定時間窗才填，否則省略此段）
```

- **必填段落**：【受影響對象】、【攻擊行為】
- **選填段落**：【攻擊來源】（有明確來源才填）、【時間範圍】（有特定時間窗才填）
- **範例**：
  ```
  【受影響對象】mpdc19-01、mpdc19-02（Domain Controllers）
  【攻擊來源】172.16.1.112（內部主機）
  【攻擊行為】421 次登入失敗（EventID 4625）
  【時間範圍】全日
  ```

---

## 架構決策說明

| 決策 | 選擇 | 原因 |
|---|---|---|
| Log 來源 | SSB REST API | 不需要 backend 與 syslog-ng 在同一台機器 |
| 個別 log 是否存 DB | 否 | 量太大，直接流過 Flash，摘錄存於 `security_events.logs` |
| Flash 觸發機制 | 時間觸發（每 10 分鐘） | 行為可預測，資安產品要求及時性 |
| MVP 過濾策略 | 僅 REST API search_expression | 不動 SSB 設定，過濾規則在程式碼層調整；時間窗口已將查詢縮限至 ~4.2 萬筆 |
| 設備層過濾 | MVP 後評估 | 600 萬筆/日的 SSB 儲存壓力是長期問題；規則須重新設計，舊版 CSV 過濾邏輯不適用 |
| 影響範圍分兩欄 | `affected_summary` + `affected_detail` | 列表需要短摘要，點擊後才展開完整說明（popover） |
| `current_status` 儲存方式 | DB 存英文值，UI 顯示中文 | 英文值易於程式判斷與 API 傳輸，中文僅為顯示層轉換 |

> `references/backend-overview.md` 中的 `LOG_FILTERED_PATH` 設定廢棄，
> 改以 SSB 連線設定（`SSB_BASE_URL`、`SSB_USERNAME`、`SSB_PASSWORD`）取代。
