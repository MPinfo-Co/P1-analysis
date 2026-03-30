# SD WBS：安全事件清單 — SSB 串接完整實作

## 工作項目
| # | 類型 | 說明 |
|---|------|------|
| 1 | Schema | 設計 `flash_results` table（Flash 每 chunk 的暫存結果） |
| 2 | Schema | 設計 `log_batches` table（每次 SSB 拉取的批次元數據；來源欄位名稱與型別請對齊 entity-analysis.md） |
| 3 | Schema | 設計 `security_events` table（每日事件快照；欄位定義請對齊 entity-analysis.md，含 `affected_summary` / `affected_detail` / `assignee_user_id` 等） |
| 4 | Schema | 設計 `daily_analysis` table（Pro 彙整狀態追蹤；欄位定義請對齊 entity-analysis.md） |
| 5 | Schema | 撰寫 Alembic migration（以上 4 表） |
| 6 | API | 設計 SSB API Client 模組（認證流程、自動重登、分頁拉取策略、避免觸發暴力保護機制） |
| 7 | API | 設計 search_expression 過濾規則（從零設計，不沿用舊版 CSV 過濾邏輯；依實際 syslog 欄位結構定義 FortiGate + Windows 條件） |
| 8 | API | 設計 Celery Flash Task（觸發策略、chunk 切分邏輯、失敗處理） |
| 9 | API | 設計 Celery Pro Task（觸發時間、去重彙整策略、寫入邏輯） |
| 10 | API | 設計 Gemini Flash / Pro prompt 格式與輸出 JSON schema（須強制要求 `affected_summary` 20字以內 / `affected_detail` 【】標籤格式） |
| 11 | API | 設計 GET /api/events（query params、response schema、`current_status` 英文值 → 中文顯示轉換、預設照 star_rank 降冪排序、分頁策略） |
| 12 | 畫面 | 設計安全事件清單頁 layout 與元件結構（表格欄位：嚴重度星等、標題、影響範圍摘要、狀態、日期） |
| 13 | 畫面 | 設計影響範圍 Popover 元件（點擊 `affected_summary` badge 展開 `affected_detail` 完整說明） |
| 14 | 畫面 | 設計篩選列元件規格（狀態下拉、關鍵字搜尋、日期區間選擇器） |
| 15 | 其他 | 定義本 Epic 新增的 .env 設定項（SSB 連線、Gemini、排程參數） |

## 備註
- **Schema 設計請以 `P1-design/schema/entity-analysis.md` 為準**，本 WBS 僅列工作範圍，欄位細節以該文件為主
- Logspace 名稱待 PG 部署時由 `/search/logspace/list_logspaces` 確認
- SSB 帳號密碼僅寫入 `.env`，不進程式碼
- SSB 暴力保護：10 次錯誤登入 / 60 秒 → 封鎖 5 分鐘，Flash Task 重試邏輯需注意
- MVP 僅使用 REST API search_expression 過濾（單層），不啟用設備層過濾；設備層過濾待 MVP 後評估
- search_expression 規則須重新設計，舊版 `references/syslogng-filters.md` 僅供方向參考，欄位格式不同不可直接套用
- 事件詳情頁（Tab 設計、指派人、處置紀錄、相似案例）屬 Epic 2 範圍，不含於此