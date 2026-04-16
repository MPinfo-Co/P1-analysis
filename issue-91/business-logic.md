# 業務邏輯分析：測試：系統公告管理功能

## 需求說明
需求：管理員可發布系統公告，使用者登入後可在首頁看到最新公告，並可標記為已讀。

## 商業邏輯（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

### 角色權限

| 角色 | 可執行操作 |
|------|-----------|
| 管理員（具 `can_manage_announcements` 權限） | 建立、編輯、刪除、發布／取消發布公告 |
| 一般使用者 | 查看已發布公告、標記已讀 |

### 公告發布流程

```
管理員建立公告（草稿）
  → 填寫標題、內容
  → 選擇是否立即發布
       ├─ 立即發布 → is_published = TRUE，前台立即可見
       └─ 存為草稿 → is_published = FALSE，前台不顯示
管理員可隨時切換發布狀態 / 刪除公告
```

### 使用者讀取流程

```
使用者登入 → 首頁
  → 呼叫 GET /announcements (僅回傳 is_published = TRUE)
  → 前端依 announcement_reads 判斷每則公告是否已讀
       ├─ 未讀 → 顯示醒目通知（如 banner 或 badge）
       └─ 已讀 → 仍可瀏覽，但不再醒目標示
使用者點擊「標記已讀」
  → 呼叫 POST /announcements/{id}/read
  → 寫入 announcement_reads (user_id, announcement_id, read_at)
  → 前端將該公告切換為已讀狀態
```

### 業務規則

1. 同一使用者對同一公告只能有一筆已讀紀錄（`announcement_reads` 以 `(user_id, announcement_id)` 為 UK）。
2. 刪除公告時，對應的 `announcement_reads` 紀錄一併刪除（CASCADE）。
3. 首頁公告清單依 `created_at DESC` 排序，最新公告在最前。
4. 未登入使用者不顯示公告（需 JWT 驗證）。

**── AI 填寫結束 ──**

## 資料模型示意（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

> 以下為新增 table，與 schema.md 現有 table 無名稱衝突。

### announcements（新增）

| 欄位 | 型別 | 說明 |
|------|------|------|
| id | BIGSERIAL, PK | |
| title | VARCHAR(200), NOT NULL | 公告標題 |
| content | TEXT, NOT NULL | 公告內容（支援 Markdown）|
| is_published | BOOLEAN, NOT NULL, DEFAULT FALSE | FALSE = 草稿；TRUE = 已發布 |
| created_by | INTEGER, NULLABLE, FK → users | 建立者 |
| created_at | TIMESTAMP, NOT NULL, DEFAULT NOW() | |
| updated_at | TIMESTAMP, NOT NULL, DEFAULT NOW() | |

### announcement_reads（新增）

| 欄位 | 型別 | 說明 |
|------|------|------|
| announcement_id | BIGINT, PK, FK → announcements | |
| user_id | INTEGER, PK, FK → users | |
| read_at | TIMESTAMP, NOT NULL, DEFAULT NOW() | |

### 實體關聯

```
users ──< announcement_reads >── announcements
users ──< announcements (created_by)
```

### roles 新增欄位（建議）

`roles` table 建議新增：

| 欄位 | 型別 | 說明 |
|------|------|------|
| can_manage_announcements | BOOLEAN, NOT NULL, DEFAULT FALSE | 可管理系統公告 |

**── AI 填寫結束 ──**

## SD 注意事項（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

1. **權限欄位**：`roles` table 目前無 `can_manage_announcements`，需在 Alembic migration 中新增此欄位（BOOLEAN, DEFAULT FALSE）。SD 需確認是否重用現有 `can_manage_accounts` 或新增獨立欄位。
2. **已讀判斷效能**：首頁一次載入多則公告時，建議後端一次回傳「當前使用者對各公告的已讀狀態」，避免前端發起多次請求。可在 `GET /announcements` 回應中附帶 `is_read: bool` 欄位（JOIN announcement_reads）。
3. **Alembic Migration 順序**：`announcement_reads` 依賴 `announcements` 與 `users`，migration 需確保順序正確。
4. **軟刪除 vs 硬刪除**：目前 schema 無軟刪除慣例，建議使用硬刪除並搭配 `ON DELETE CASCADE` 清除 `announcement_reads`。

**── AI 填寫結束 ──**

## 畫面示意（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

### 管理員：公告管理頁（新頁面）

```
┌─────────────────────────────────────────────┐
│ 系統公告管理               [+ 新增公告]      │
├──────────────────────┬──────┬───────┬───────┤
│ 標題                 │ 狀態 │ 建立時間│ 操作 │
├──────────────────────┼──────┼───────┼───────┤
│ 系統維護公告 2026/04 │ 已發布│ 04/15 │編輯 刪│
│ Q1 更新說明          │ 草稿 │ 04/10 │編輯 刪│
└──────────────────────┴──────┴───────┴───────┘
```

- 點擊「新增公告」→ 側邊抽屜或 Dialog 輸入標題、內容、是否立即發布
- 點擊「編輯」→ 同上，帶入現有資料
- 「已發布」可切換回「草稿」（toggle）

### 一般使用者：首頁公告區塊

```
┌─────────────────────────────────────────────┐
│ 📢 最新公告                                  │
│ ┌─────────────────────────────────────────┐ │
│ │ [NEW] 系統維護公告 2026/04        [已讀] │ │
│ │ 本系統將於 04/20 02:00–04:00 進行維護…  │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ Q1 更新說明                    ✓ 已讀   │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

- 未讀公告顯示 `[NEW]` badge，提供「標記已讀」按鈕
- 已讀公告以較低對比度顯示，無 badge

**── AI 填寫結束 ──**
