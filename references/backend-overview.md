# 後端架構總覽

> FastAPI + Celery + Redis + PostgreSQL + pgvector | 更新：2026-03-17
> 架構圖見 `diagrams/system-architecture.md`；Pipeline 流程見 `diagrams/analysis-pipeline.md`

## 技術棧

| 元件 | 版本 | 說明 |
|------|------|------|
| Python | 3.12+ | |
| FastAPI + Uvicorn | 0.115+ / 0.30+ | ASGI API server |
| SQLAlchemy + Alembic | 2.0+ / 1.13+ | Async ORM + migration |
| Celery + Redis | 5.4+ / 7.x | 背景任務 + broker |
| PostgreSQL + pgvector | 16+ / 0.7+ | 主 DB + 向量搜尋 |
| google-generativeai | latest | Gemini API SDK |
| python-jose + passlib | 3.3+ / 1.7+ | JWT + 密碼 hash |

## 專案結構

```
mpbox-backend/
├── app/
│   ├── main.py                 # FastAPI entry
│   ├── config.py               # 環境變數
│   ├── database.py             # SQLAlchemy engine
│   ├── models/                 # ORM models（對應 DB schema）
│   ├── schemas/                # Pydantic request/response
│   ├── routers/                # API routes（events, chat, kb, users, auth...）
│   ├── services/               # 業務邏輯（pipeline, merge, chat, embedding）
│   └── tasks/                  # Celery tasks（analysis_tasks.py）
├── alembic/                    # DB migration
├── rules/                      # Prompt 規則（md 檔，載入至 system prompt）
├── sql/                        # Schema DDL
├── .env.example
├── docker-compose.yml
└── requirements.txt
```

## API 端點

### 安全事件
| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/events` | 事件清單（?status=&keyword=&date_start=&date_end=&page=&size=） |
| GET | `/api/events/{id}` | 單一事件詳情（含 suggests, logs, mitre_tags） |
| PATCH | `/api/events/{id}` | 更新事件（僅允許 current_status, resolution） |
| GET/POST | `/api/events/{id}/history` | 處置紀錄查詢/新增 |
| DELETE | `/api/events/{id}/history/{hid}` | 軟刪除紀錄 |

### 分析任務
| Method | Path | 說明 |
|--------|------|------|
| POST | `/api/analysis/trigger` | 手動觸發（或上傳 CSV） |
| GET | `/api/analysis/status` | 最近一次分析狀態 |
| GET | `/api/analysis/sessions` | 歷史分析工作階段 |

### AI 諮詢
| Method | Path | 說明 |
|--------|------|------|
| POST | `/api/chat` | body: `{event_id, message, history[]}` → Gemini Pro 回覆 |

### 知識庫
| Method | Path | 說明 |
|--------|------|------|
| GET/POST | `/api/kb` | 知識庫清單/新增 |
| PUT/DELETE | `/api/kb/{id}` | 更新/刪除知識庫 |
| POST | `/api/kb/{id}/documents` | 上傳文件（觸發 embedding pipeline） |
| DELETE | `/api/kb/{id}/documents/{did}` | 刪除文件 |
| GET/POST | `/api/kb/{id}/tables` | 結構化資料表管理 |
| GET/POST/PATCH/DELETE | `/api/kb/{id}/tables/{tid}/rows` | 資料列 CRUD |
| PUT | `/api/kb/{id}/access` | 更新存取角色 |

### 帳號/角色/AI 夥伴
| Method | Path | 說明 |
|--------|------|------|
| GET/POST/PUT/DELETE | `/api/users`, `/api/roles`, `/api/ai-partners` | 基本 CRUD |
| POST | `/api/auth/login` | 登入（回傳 JWT） |
| POST | `/api/auth/refresh` | 更新 token |

## 環境變數（.env.example）

```env
DATABASE_URL=postgresql+asyncpg://mpbox:password@localhost:5432/mpbox
REDIS_URL=redis://localhost:6379/0
GEMINI_API_KEY=your-api-key-here
OLLAMA_BASE_URL=http://localhost:11434
JWT_SECRET_KEY=your-jwt-secret
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=480
LOG_FILTERED_PATH=/var/log/mpbox/filtered
LOG_RAW_PATH=/var/log/mpbox/raw
FLASH_BATCH_SIZE=300
ANALYSIS_SCHEDULE_HOUR=2
```

## Docker Compose

```yaml
services:
  api:
    build: .
    ports: ["8000:8000"]
    depends_on: [db, redis, ollama]
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000

  worker:
    build: .
    depends_on: [db, redis]
    command: celery -A app.tasks.celery_app worker --loglevel=info

  beat:
    build: .
    depends_on: [redis]
    command: celery -A app.tasks.celery_app beat --loglevel=info

  db:
    image: pgvector/pgvector:pg16
    environment: { POSTGRES_DB: mpbox, POSTGRES_USER: mpbox, POSTGRES_PASSWORD: password }
    volumes: ["pgdata:/var/lib/postgresql/data"]

  redis:
    image: redis:7-alpine

  ollama:
    image: ollama/ollama
    volumes: ["ollama_models:/root/.ollama"]

volumes:
  pgdata:
  ollama_models:
```
