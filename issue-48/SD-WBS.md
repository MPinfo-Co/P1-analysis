# SD WBS：Production 首次登入，遭遇密碼錯誤

## 工作項目

| # | 類型 | 說明 |
|---|------|------|
| 1 | 其他 | 新增 Alembic data migration：插入預設角色（admin / user）與 admin 帳號（password_hash = bcrypt("admin123")） |

## 備註

- migration 採冪等設計：先查詢是否存在，不存在才插入，避免重複執行報錯
- 此 migration 依賴 `5db1ff7f746b`（users / roles / user_roles 建表），須設定正確的 `down_revision`
- 密碼為預設值 `admin123`，部署後應立即更改
- `seed.py` 保留不刪除（可作為本機開發用途），但部署流程改為依賴 migration
