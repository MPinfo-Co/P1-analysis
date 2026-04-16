# 業務邏輯分析：[SA] 登入功能

## 需求說明

使用者以帳號密碼登入系統，登入後能使用需要驗證身分的功能

### 驗收條件

- 使用者可輸入帳號密碼並成功登入
- 登入失敗顯示對應錯誤訊息
- 登入成功後取得 Token，後續 API 可驗證身分
- 可登出並清除登入狀態

---

## 商業邏輯

### 登入流程

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

### 登出流程

```
使用者點擊頁面頂部右側「登出」按鈕
        ↓
後端將目前 Token 標記為失效
        ↓
前端清除已儲存的 Token
        ↓
導向登入頁
```

### 錯誤訊息對應

| 情境 | HTTP 狀態碼 | 回傳訊息 |
|------|------------|---------|
| 帳號不存在 / 密碼錯誤 / 帳號停用 | 401 | 帳號或密碼錯誤 |
| Token 已失效或過期 | 401 | 請重新登入 |

---

## 畫面示意

詳見 P1-design：[Spec/auth/auth_01_login.md](https://github.com/MPinfo-Co/P1-design/blob/main/Spec/auth/auth_01_login.md)

---

## 資料模型

涉及 `users`、`token_blacklist` 兩張表，詳見 P1-design：[schema/schema.md](https://github.com/MPinfo-Co/P1-design/blob/main/schema/schema.md)

## SD 注意事項

1. **密碼雜湊**：一律使用 bcrypt，驗證透過 `core/security.py` 的 `verify_password`
2. **JWT 自建**：不使用第三方 OAuth，Token 簽發 / 解析 / 時效設定皆在 `core/security.py`
3. **Token 黑名單**：登出須將 Token 寫入 `token_blacklist`；需考慮定期清理已過期紀錄
4. **前端狀態管理**：使用 Zustand 的 authStore 管理登入狀態，Token 持久化至 localStorage，頁面重新整理後自動還原登入狀態
5. **錯誤訊息一致性**：登入失敗統一回 401 + 相同訊息，不區分 email 不存在 / 密碼錯 / 帳號停用
6. **API 身分驗證 guard**：透過 `core/deps.py` 的 `get_current_user` 執行——從 Authorization header 取得 Bearer Token → 查 token_blacklist → 解析 JWT → 查 users 是否存在且啟用 → 注入 current_user

## SD-WBS

| # | 類型 | 說明 |
|---|------|------|
| 1 | Schema | users 表、token_blacklist 表（確認 schema.md 定義） |
| 2 | API | POST /api/auth/login（登入） |
| 3 | API | POST /api/auth/logout（登出） |
| 4 | API | get_current_user guard（身分驗證 dependency） |
| 5 | 畫面 | 登入頁（Login Page） |
| 6 | 畫面 | Header 登出按鈕 |
