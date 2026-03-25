# MP-BOX 技術棧

## 階段一：MVP

**目標：產品上線，核心功能可用**
**時間點：現在（2 人團隊）**

---

### 一、程式語言
- **Python 3.12+**（後端語言，生態成熟，AI 函式庫豐富）
- **JavaScript**（前端語言，React 生態主流選擇）

### 二、前端
- **Vite**（建置工具，熱更新極速）
- **React 18**（主流 UI 框架，元件化開發，社群龐大）
- **React Router v6**（前端路由）
- **Tailwind CSS v3**（Utility-first CSS，快速刻版）
- **shadcn/ui**（UI 元件庫，基於 Radix UI，可自訂性高）
- **Zustand**（Client State 管理，輕量，學習曲線低）
- **TanStack Query**（Server State 管理，自動處理 loading/error/cache）
- **Axios**（HTTP 請求）

### 三、後端框架
- **FastAPI**（高效能 Python Web 框架，自動生成 Swagger 文件）
- **Pydantic**（資料驗證，確保 API 輸入輸出格式正確）
- **SQLAlchemy**（ORM，成熟穩定，社群資源豐富，DB model 與 API schema 分開易於維護）
- **Alembic**（Migration 工具，管理 Schema 版本變更與回滾）

### 四、資料庫
- **PostgreSQL**（穩定可靠的關聯式資料庫）

### 五、認證
- **自建 JWT**（登入 / 登出 / permission guard，以 bcrypt 做密碼 hash）

### 六、檔案儲存
- **Cloudflare R2**（物件儲存，無流出費用，與 S3 API 相容）

### 七、AI 整合
- **OpenAI API**（初期 AI Provider，透過抽象層呼叫，保留切換彈性）

### 八、Email
- **Resend**（交易型 Email 服務，免費方案每月 3,000 封）

### 九、客戶支援
- **Crisp**（網站內嵌聊天視窗）

### 十、安全
- **ClamAV**（開源檔案掃描，打包進 Docker）

### 十一、部署
- **Docker**（容器化，落地版核心交付格式）
- **Gunicorn + uvicorn**（生產環境伺服器）
- **Vercel**（前端靜態網站託管）
- **Railway**（後端 + 資料庫託管，按用量計費）

### 十二、CI/CD
- **GitHub Actions**（push 後自動執行測試與部署）

### 十三、監控
- **Sentry**（錯誤監控，前後端都裝）
- **UptimeRobot**（可用性監控，提供對外狀態頁面）

### 十四、程式碼品質
- **Ruff**（Python Linter，整合進 CI）
- **ESLint + Prettier**（前端程式碼品質與格式統一）
- **pytest**（Python 測試框架）
- **pre-commit**（Git Hooks，commit 前自動執行 Linter）

---

## 待討論

以下項目尚未確認，保留為候選：

- **TypeScript**（是否取代 JavaScript 作為前端語言）
- **MUI**（是否取代 shadcn/ui 作為 UI 元件庫）
- **Clerk**（是否取代自建 JWT 作為認證服務）
