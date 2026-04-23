# 業務邏輯分析：實作[使用者]維護功能

## 需求說明
### 功能說明

實作[使用者]維護功能

### 驗收條件

MB-Box可以正確 查詢、新增、刪除、修改使用者資料

## 商業邏輯（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

### 存取控制

所有操作均須具備 `can_manage_accounts` 權限，否則回傳 403。

### 新增使用者

```
收到 POST /api/users
  → 驗證 JWT
  → 檢查 can_manage_accounts 權限
  → 驗證欄位格式（名稱 ≤ 100字、Email 格式、密碼 ≥ 8字元、角色非空）
  → 確認 Email 在 tb_users 中不重複
  → bcrypt hash 密碼
  → 寫入 tb_users（is_active = true）
  → 逐筆寫入 tb_user_roles
  → 回傳 201
```

### 修改使用者

```
收到 PATCH /api/users/{email}
  → 驗證 JWT
  → 檢查 can_manage_accounts 權限
  → 確認 {email} 對應的使用者存在，否則 404
  → 僅驗證有傳入的欄位
  → 若傳入新 Email，確認不與其他帳號重複
  → 若傳入角色，確認陣列非空
  → 更新 tb_users
  → 若傳入角色：先 DELETE tb_user_roles（該使用者），再重新寫入
  → 回傳 200
```

> **密碼修改不在本 Epic 範圍內**，修改畫面不顯示密碼欄位。

### 刪除使用者

```
收到 DELETE /api/users/{email}
  → 驗證 JWT
  → 檢查 can_manage_accounts 權限
  → 確認 {email} 對應的使用者存在，否則 404
  → 確認操作者不刪除自己，否則 400
  → DELETE tb_user_roles（該使用者所有角色關聯）
  → DELETE tb_users（該筆紀錄）
  → 回傳 200
```

### 查詢使用者

```
收到 GET /api/users?role_id=&keyword=
  → 驗證 JWT
  → 檢查 can_manage_accounts 權限
  → tb_users LEFT JOIN tb_user_roles LEFT JOIN tb_roles
  → 若有 role_id → 過濾角色
  → 若有 keyword → 姓名 ILIKE 或 Email ILIKE
  → 依 tb_users.created_at ASC 排序
  → 回傳 200（名稱、Email、啟用狀態、角色[]）
```

**── AI 填寫結束 ──**

## 資料模型示意（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

```
tb_users                    tb_user_roles              tb_roles
─────────────────────       ──────────────────         ────────────────────────────
id (PK)                     user_id (PK, FK→users)     id (PK)
name                        role_id (PK, FK→roles)     name
email (UK)                                             can_manage_accounts
password_hash                                          can_access_ai
is_active                                              can_use_kb
created_at                                             can_manage_roles
updated_at                                             can_edit_ai
                                                       can_manage_kb
```

- `tb_users` ↔ `tb_roles` 為多對多關係，透過 `tb_user_roles` 中介。
- 刪除使用者時須先清除 `tb_user_roles`，再刪除 `tb_users`（維護參照完整性）。
- 修改角色採**先刪後寫**策略，無需逐筆比對差異。

**── AI 填寫結束 ──**

## SD 注意事項（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

1. **密碼 Hash**：新增時一律使用 bcrypt；修改使用者 API（PATCH）不含密碼欄位，密碼修改為獨立功能，不在本 Epic 實作。
2. **路由識別符為 Email**：Update / Delete endpoint 使用 `{email}` 作為 Path Parameter（非 id），SD 實作時需注意 URL encode（Email 含 `@`）。
3. **角色修改策略**：PATCH 傳入角色時，採先刪除再寫入，不做差集比對，邏輯較簡單且安全。
4. **自我刪除防護**：從 JWT token 解析當前操作者 email，與 Path Parameter 比對，相同則拒絕。
5. **前端技術**：依 techStack，使用 React 19 + MUI + Zustand；角色 checkbox group 選項來源為 `GET /api/roles`（已有 fn_role 相關 API）。

**── AI 填寫結束 ──**

## 畫面示意（選填）

**⚠️ ── AI 填寫開始，請逐行審查 ──**

> 雛形畫面：`p1-design/Prototype/fn_user.html`

### 查詢畫面（fn_user_01_list）

```
┌──────────────────────────────────────────────────────────┐
│ 帳號管理                              [＋ 新增帳號]        │
├──────────────────────────────────────────────────────────┤
│ 角色職位 [全部 ▼]  關鍵字 [____________]  [套用]          │
├──────────────────────────────────────────────────────────┤
│ 姓名        │ 電子信箱             │ 角色         │ 操作  │
├─────────────┼──────────────────────┼──────────────┼───────┤
│ 王小明      │ wang@example.com     │ [管理員]     │ 修改  刪除 │
│ 李大華      │ lee@example.com      │ [分析師][檢視]│ 修改  刪除 │
└──────────────────────────────────────────────────────────┘
```

- 角色以 MUI Chip（badge）呈現，可多個。
- [刪除] 點擊後顯示確認 Dialog：「確定要刪除此帳號嗎？無法復原。」

### 新增 / 修改畫面（fn_user_02_form，以 Modal 呈現）

```
┌─────────────────────────────────┐
│ 新增帳號（或：修改帳號）      ✕ │
├─────────────────────────────────┤
│ 名稱 *   [____________________] │
│ Email *  [____________________] │
│ 密碼 *   [____________________] │  ← 修改畫面不顯示此欄
│ 角色 *                          │
│   ☑ 管理員   ☐ 分析師           │
│   ☐ 檢視者   [全選]             │
├─────────────────────────────────┤
│               [取消]  [儲存]    │
└─────────────────────────────────┘
```

- 修改畫面預填現有資料（名稱、Email、已指派角色）。
- 儲存成功後關閉 Modal，重新整理查詢清單。

**── AI 填寫結束 ──**
