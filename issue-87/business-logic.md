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

詳見 [P1-design/Prototype/MP-Box_資安專家_v73_claude.html](https://github.com/MPinfo-Co/P1-design/tree/main/Prototype/MP-Box_資安專家_v73_claude.html)

---

## 資料模型

涉及 `users`、`token_blacklist` 兩張表，詳見 [P1-design/schema/schema.md](https://github.com/MPinfo-Co/P1-design/blob/main/schema/schema.md)

## SD 注意事項

1. 密碼儲存使用 bcrypt 單向雜湊
2. Token 採自建 JWT，不使用第三方 OAuth
3. 登出須有 Token 黑名單機制，需考慮定期清理
4. 前端 Token 需持久化，頁面重新整理後維持登入狀態
5. 登入失敗統一回 401 + 相同訊息，避免洩漏帳號是否存在
6. 需設計 API 身分驗證機制，供後續需要登入的 API 共用

## SD-WBS

| #   | 類型        | 說明             |
| --- | --------- | -------------- |
| 1   | Schema    | 使用者表、token黑名單表 |
| 2   | API       | 登入             |
| 3   | API       | 登出             |
| 4   | API       | 身分驗證機制 (共用)    |
| 5   | Prototype | 登入頁            |
| 6   | Prototype | 頁面頂部右側的登出按鈕    |
