# SD WBS：安全事件清單 — SSB 串接完整實作

## 工作項目
| # | 類型 | 說明 |
|---|------|------|
| 1 | Schema | 設計 `flash_results` table（Flash 每 chunk 的暫存結果） |
| 2 | Schema | 設計 `log_batches` table（每次 SSB 拉取的批次元數據，source_info 改為 JSON 欄位） |
| 3 | Schema | 設計 `security_events` table（每日事件快照） |
| 4 | Schema | 設計 `daily_analysis` table（Pro 彙整狀態追蹤） |
| 5 | Schema | 撰寫 Alembic migration（以上 4 表） |
| 6 | API | 設計 SSB API Client 模組（認證流程、自動重登、分頁拉取策略） |
| 7 | API | 設計 search_expression 過濾規則（FortiGate + Windows，依 syslogng-filters.md 轉換） |
| 8 | API | 設計 Celery Flash Task（觸發策略、chunk 切分邏輯、失敗處理） |
| 9 | API | 設計 Celery Pro Task（觸發時間、去重彙整策略、寫入邏輯） |
| 10 | API | 設計 Gemini Flash / Pro prompt 格式與輸出 JSON schema |
| 11 | API | 設計 GET /api/events（query params、response schema、分頁策略） |
| 12 | 畫面 | 設計安全事件清單頁 layout 與元件結構 |
| 13 | 畫面 | 設計篩選列元件規格（嚴重度多選、狀態、關鍵字、日期區間） |
| 14 | 其他 | 定義本 Epic 新增的 .env 設定項（SSB 連線、Gemini、排程參數） |

## 備註
- Logspace 名稱待 PG 部署時由 `/search/logspace/list_logspaces` 確認
- SSB 帳號密碼僅寫入 `.env`，不進程式碼
- 事件詳情頁屬 Epic 2 範圍，不含於此
