# 業務邏輯分析：[SA] 登入功能

## 需求說明

使用者以帳號密碼登入系統，登入後能使用需要驗證身分的功能

### 驗收條件

- 使用者可輸入帳號密碼並成功登入
- 登入失敗顯示對應錯誤訊息
- 登入成功後取得 Token，後續 API 可驗證身分
- 可登出並清除登入狀態

---

## 登入流程

```
使用者輸入 email + password → 點擊「登入」
        ↓
後端驗證帳號密碼
        ↓
  驗證失敗（帳號不存在 / 密碼錯誤 / 帳號已停用）
        → 統一回傳 401「帳號或密碼錯誤」
        ↓ 驗證通過
  簽發 Token（內容：使用者 ID，時效 8 小時）
        ↓
  回傳 Token → 前端儲存 Token
        ↓
  導向首頁
```

## 登出流程

```
使用者點擊 Header 右側「登出」按鈕
        ↓
後端將目前 Token 標記為失效
        ↓
前端清除已儲存的 Token
        ↓
導向登入頁
```

## 後續 API 身分驗證（get_current_user guard）

每支需要身分識別的 API，透過 `core/deps.py` 執行：

1. 從 Authorization header 取得 Bearer Token
2. 查詢 token_blacklist → 已在黑名單則拒絕（401）
3. 解析 JWT → 無效或過期則拒絕（401）
4. 查詢 users → 不存在或 is_active = FALSE 則拒絕（401）
5. 驗證通過 → 注入 current_user 供下游使用

## 錯誤訊息對應

| 情境 | HTTP 狀態碼 | 回傳訊息 |
|------|------------|---------|
| email 不存在 / 密碼錯誤 / 帳號停用 | 401 | 帳號或密碼錯誤 |
| Token 已登出（在黑名單） | 401 | 請重新登入 |
| Token 無效或過期 | 401 | 請重新登入 |
| 使用者不存在或已停用（guard） | 401 | 請重新登入 |

---

## 資料模型

```
users
├── id (PK)
├── name           ← 顯示名稱
├── email (UNIQUE) ← 登入帳號
├── password_hash  ← bcrypt 雜湊
├── is_active      ← FALSE 時禁止登入
├── created_at
└── updated_at

token_blacklist（登出黑名單）
├── id (PK)
├── token (UNIQUE) ← 被登出的 JWT 字串
├── expired_at     ← Token 原始到期時間，可用於定期清理
└── created_at
```

> 兩張表在 P1-code 已有 model 實作，schema.md 需確認是否已收錄。
> roles / user_roles 不在本次範圍。

---

## 畫面示意

### 登入頁（Login Page）

```
┌─────────────────────────────────────────┐
│              MP-BOX                     │
│                                         │
│   Email                                 │
│   ┌─────────────────────────────────┐   │
│   │ user@example.com                │   │
│   └─────────────────────────────────┘   │
│                                         │
│   密碼                                  │
│   ┌─────────────────────────────────┐   │
│   │ ••••••••                  [👁]  │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │           登入                  │   │ ← 點擊後顯示 Loading
│   └─────────────────────────────────┘   │
│                                         │
│   ⚠ 帳號或密碼錯誤（登入失敗時顯示）    │
│                                         │
└─────────────────────────────────────────┘
```

### 登出

Header 右側紅色「登出」文字按鈕。

### 操作流程

| 步驟 | 使用者動作 | 系統回應 |
|------|-----------|---------|
| 1 | 輸入 email + 密碼，點擊「登入」 | Button 轉為 Loading 狀態 |
| 2a | （成功） | 儲存 Token，導向首頁 |
| 2b | （失敗） | 表單下方顯示錯誤訊息，欄位不清空 |
| 3 | 於任意頁面點擊 Header「登出」 | 清除 Token，導向登入頁 |

---

## SD 注意事項

1. **密碼雜湊**：一律使用 bcrypt，驗證透過 `core/security.py` 的 `verify_password`
2. **JWT 自建**：不使用第三方 OAuth，Token 簽發 / 解析 / 時效設定皆在 `core/security.py`
3. **Token 黑名單**：登出須將 Token 寫入 `token_blacklist`；需考慮定期清理已過期紀錄
4. **前端狀態管理**：使用 Zustand 的 authStore 管理登入狀態，Token 持久化至 localStorage，頁面重新整理後自動還原登入狀態
5. **錯誤訊息一致性**：登入失敗統一回 401 + 相同訊息，不區分 email 不存在 / 密碼錯 / 帳號停用

---

## SD-WBS

| # | 類型 | 說明 |
|---|------|------|
| 1 | Schema | users 表、token_blacklist 表（確認 schema.md 定義） |
| 2 | API | POST /api/auth/login（登入） |
| 3 | API | POST /api/auth/logout（登出） |
| 4 | API | get_current_user guard（身分驗證 dependency） |
| 5 | 畫面 | 登入頁（Login Page） |
| 6 | 畫面 | Header 登出按鈕 |
