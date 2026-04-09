# 業務邏輯分析：Production 首次登入，遭遇密碼錯誤

## 功能/問題描述（from Epic）

Production 首次部署後，使用 admin@mpinfo.com.tw / admin123 登入，API 回傳密碼錯誤。

## 根本原因

Railway start command 設定為：
```
alembic upgrade head && uvicorn app.main:app ...
```

`alembic upgrade head` 只執行 schema migration（建表），**不執行資料初始化**。
`seed.py` 是獨立腳本，需手動執行，從未在 Production 環境執行過。
因此 Production DB 中不存在 admin 帳號，登入 API 回傳通用錯誤「密碼錯誤」。

`seed.py` 本身邏輯正確（有冪等保護、使用 bcrypt hash），問題出在部署流程未觸發它。

## Use Case

**Actor**：系統管理員（首次部署後）

| # | Use Case | 現況 | 預期 |
|---|---------|------|------|
| UC1 | 以 admin 帳號登入 Production | 失敗（帳號不存在） | 成功 |
| UC2 | 重複部署時不重複建立 admin | N/A | 冪等，略過已存在資料 |

## 流程圖

### 現況流程（有問題）

```
Railway deploy
  └─ alembic upgrade head  → 建表（roles / users / user_roles）
  └─ uvicorn 啟動
  
使用者嘗試登入
  └─ POST /auth/login { email, password }
  └─ DB 查詢 → 找不到 admin 帳號
  └─ 回傳 401 密碼錯誤（通用訊息，不揭露帳號是否存在）
```

### 修正後流程

```
Railway deploy
  └─ alembic upgrade head  → 建表 + 執行 data migration
       └─ data migration: 插入預設 roles（admin / user）
       └─ data migration: 插入 admin 帳號（password_hash = bcrypt("admin123")）
  └─ uvicorn 啟動

使用者登入
  └─ POST /auth/login { email, password }
  └─ DB 查詢 → 找到 admin，bcrypt.checkpw 驗證通過
  └─ 回傳 200 + JWT token
```

## Class Diagram

```
User
  - id: int
  - name: str
  - email: str (unique)
  - password_hash: str   ← bcrypt hash，非明文
  - is_active: bool

Role
  - id: int
  - name: str (unique)   ← 'admin' | 'user'
  - can_access_ai: bool
  - can_use_kb: bool
  - can_manage_accounts: bool
  - can_manage_roles: bool
  - can_edit_ai: bool
  - can_manage_kb: bool

UserRole
  - user_id: FK → User
  - role_id: FK → Role
```

## ER 示意

```
users ──< user_roles >── roles
```

## 決策：data migration vs 修改 start command

| 方案 | 說明 | 優 | 劣 |
|------|------|----|----|
| A. Alembic data migration | 新增一個 migration 檔，插入初始資料 | 一次性執行、有版本控制、與 schema migration 同流程 | migration 檔含初始密碼（可接受，因為是預設密碼，應部署後立即更改） |
| B. 修改 start command 串接 seed.py | `alembic upgrade head && python seed.py && uvicorn ...` | 簡單 | 每次啟動都執行（雖有冪等保護），不符合 migration 語義 |

**採用方案 A**：data migration，維持部署流程單純。
