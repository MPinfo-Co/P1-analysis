# 業務邏輯分析：測試：使用者通知設定功能

## 需求說明
需求：使用者可自訂通知偏好設定，包含選擇接收哪些類型的系統通知（如資安事件、系統警告），以及設定通知方式（站內訊息、Email）。

## 商業邏輯（選填）

[以下由AI填寫，請務必逐行檢查..區塊一]

### 通知設定維度

| 維度 | 說明 | 初始值 |
|------|------|--------|
| 通知類型 | 資安事件、系統警告 | 全部啟用 |
| 通知渠道 | 站內訊息、Email | 站內訊息啟用；Email 預設關閉 |

每種**通知類型 × 通知渠道**的組合可獨立啟停，共 2×2 = 4 個開關。

### 流程規則

1. **設定儲存**：使用者調整開關後按「儲存」，後端覆寫該使用者全部設定並立即生效。
2. **新使用者預設**：建立帳號時自動寫入預設設定（站內訊息全開、Email 全關）。
3. **Email 渠道前置條件**：
   - 若 Email 功能尚未上線（Resend 未啟用），前端將 Email 欄位顯示為「即將推出」灰階狀態，不可操作。
   - 未來 Email 上線後，後端於寄送前仍須確認 `users.email` 已存在才執行傳送。
4. **通知觸發時機**：
   - **資安事件**：`security_events` 建立新紀錄 或 `current_status` 發生變更時。
   - **系統警告**：系統層級異常（如 Flash Task 連續失敗、SSB 連線中斷）時。
5. **觸發後判斷流程**：

```
事件觸發
  └→ 查詢 user_notification_settings（依通知類型）
       └→ 對每位有設定的使用者：
            ├→ is_enabled = TRUE, channel = 'in_app'  → 寫入站內通知佇列
            └→ is_enabled = TRUE, channel = 'email'   → 呼叫 Email 服務（需 Email 已上線）
```

[以上由AI填寫，請務必逐行檢查..區塊一]

## 資料模型示意（選填）

[以下由AI填寫，請務必逐行檢查..區塊二]

> schema.md 中目前無同名資料表，須新增 `user_notification_settings`。

### user_notification_settings（新增）

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | INTEGER, PK | 主鍵 |
| user_id | INTEGER, NOT NULL, FK → users | 所屬使用者 |
| notify_type | VARCHAR(50), NOT NULL | 通知類型：`security_event` / `system_warning` |
| channel | VARCHAR(50), NOT NULL | 渠道：`in_app` / `email` |
| is_enabled | BOOLEAN, NOT NULL, DEFAULT TRUE | 是否啟用 |
| updated_at | TIMESTAMP, NOT NULL, DEFAULT NOW() | |

```sql
-- 每位使用者對每種「類型 × 渠道」只能有一筆設定
UNIQUE (user_id, notify_type, channel)
```

### 實體關聯

```
users (1) ──< user_notification_settings (N)
```

[以上由AI填寫，請務必逐行檢查..區塊二]

## SD 注意事項（選填）

[以下由AI填寫，請務必逐行檢查..區塊三]

1. **Email 尚未上線**：TechStack.md 標記 Resend 為「規劃中」，前端在 Email 渠道啟用前需 disable 並加 tooltip 說明，後端 API 仍需接受 email 設定（避免未來需要 migration）但暫不觸發傳送。
2. **站內訊息實作待定**：目前 schema.md 無站內通知相關資料表，SD 需先確認站內通知的推送方式（WebSocket、Server-Sent Events 或輪詢），並決定是否需新增 `in_app_notifications` 資料表。
3. **預設設定寫入時機**：建議在使用者建立（`POST /users`）時即批次寫入預設通知設定，避免首次查詢時找不到設定需另做 fallback 判斷。
4. **通知觸發點整合**：資安事件通知需在 `security_events` 建立與狀態變更的後端邏輯中埋入通知觸發呼叫，避免遺漏。

[以上由AI填寫，請務必逐行檢查..區塊三]

## 畫面示意（選填）

[以下由AI填寫，請務必逐行檢查..區塊四]

### 使用者設定頁 — 通知設定區塊

```
┌─────────────────────────────────────────────────────────┐
│  通知設定                                                │
├───────────────┬──────────────────┬──────────────────────┤
│  通知類型     │  站內訊息        │  Email               │
├───────────────┼──────────────────┼──────────────────────┤
│  資安事件     │  [● 開啟]        │  [○ 關閉] 即將推出   │
│  系統警告     │  [● 開啟]        │  [○ 關閉] 即將推出   │
└───────────────┴──────────────────┴──────────────────────┘
                                        [ 儲存設定 ]
```

- 「即將推出」標籤於 Email 功能上線後移除，改為可操作的 Toggle。
- 儲存後顯示成功 Snackbar（符合 MUI 慣例）。
- 若儲存失敗（API 錯誤），顯示錯誤 Snackbar 並還原開關狀態。

[以上由AI填寫，請務必逐行檢查..區塊四]
