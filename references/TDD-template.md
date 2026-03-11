# [Product Name] — Technical Design Document

> **Version:** 1.0
> **Last Updated:** YYYY-MM-DD
> **Prerequisite:** Read `docs/PRD.md` for product context and feature requirements.

<!-- TDD 的目標：讓 AI coding agent（或未來加入的工程師）能快速理解「系統怎麼運作」。 -->
<!-- PRD 回答 "做什麼 & 為什麼"，TDD 回答 "怎麼做"。 -->

---

## Tech Stack

<!-- 列出你選擇的每一層技術。這讓 AI agent 知道該用什麼語言/框架來寫 code。 -->

| Layer | Technology |
|-------|------------|
| Frontend | [e.g., Next.js 14, React, TailwindCSS, shadcn/ui] |
| Backend | [e.g., Supabase, Firebase, Express + Postgres] |
| Auth | [e.g., Supabase Auth, NextAuth, Clerk] |
| Deployment | [e.g., Vercel, AWS, Fly.io] |
| Monorepo | [e.g., pnpm workspaces, turborepo, nx] |
| [其他層] | [技術] |

---

## Architecture Overview

<!-- 用 ASCII diagram 畫出系統的主要組件和資料流。 -->
<!-- 不需要很精美，重點是讓人一眼看懂「哪些東西在跟哪些東西溝通」。 -->

<!--
  範例（來自 Wordhenge）：

  ```
  ┌─────────────────────────────────────────────┐
  │              User's Browser                  │
  │  ┌────────────┐    ┌───────────────────┐     │
  │  │  Extension  │◄──│  Content Script   │     │
  │  │  (SW)       │    │  (Debounce)       │     │
  │  └──────┬──────┘    └───────────────────┘     │
  └─────────┼─────────────────────────────────────┘
            │
            ▼
  ┌──────────────────┐     ┌──────────────────┐
  │  External API    │     │  Database         │
  └──────────────────┘     │  (Supabase)       │
                           └────────▲─────────┘
                                    │
                           ┌────────┴─────────┐
                           │  Web Dashboard    │
                           │  (Next.js)        │
                           └──────────────────┘
  ```
-->

```
[在這裡畫你的架構圖]

提示：可以用 ┌ ─ ┐ │ └ ┘ ▲ ▼ ◄ ► 來畫框和箭頭。
標注資料流的方向和步驟編號（1. Fetch data → 2. Process → 3. Store）。
```

---

## Authentication

<!-- 描述你的 auth 流程。包含：用了什麼機制、token 怎麼管理、refresh 策略。 -->
<!-- 如果有多個 token（如 Wordhenge 的 Supabase session + Google API token），要說明為什麼分開。 -->

### 機制

| 用途 | 機制 | Refresh 策略 |
|------|------|-------------|
| [用途 1] | [機制] | [如何 refresh] |
| [用途 2] | [機制] | [如何 refresh] |

### Flow

```
使用者點「登入」
  │
  ▼
[Auth Provider] (e.g., Supabase OAuth, NextAuth)
  │
  ├─► [Token A] → 用途：___
  │
  └─► [Token B] → 用途：___（如果有的話）
```

### Key Files

<!-- 列出 auth 相關的關鍵檔案路徑，方便 AI agent 直接找到。 -->

- `[path/to/auth-logic]` — [描述]
- `[path/to/auth-config]` — [描述]

---

## Core Technical Patterns

<!-- 描述你的系統中最重要的技術模式。 -->
<!-- 這一節的目標是讓 AI agent 理解你的 codebase 的「套路」，避免它寫出風格不一致的 code。 -->

<!--
  範例（來自 Wordhenge）：

  ### MV3 Event-Driven Architecture
  - Content Script（跟著分頁走）負責 debounce
  - Service Worker（事件驅動）負責 API 調用
  - 關鍵：chrome.runtime.sendMessage() 會自動喚醒已終止的 SW

  ### Word Count Delta Handling
  - daily_word_counts 記錄「該日的最新總字數」（絕對值）
  - Dashboard 計算 delta = today - yesterday
  - 字數變動 > 10 字才寫入
-->

### [模式名稱 1]

<!-- 用幾行文字或 pseudo code 解釋這個模式。 -->

```typescript
// 如果有關鍵的 code pattern，貼一個簡化版本在這裡。
// AI agent 看到這個就知道要怎麼寫類似的 code。
```

### [模式名稱 2]

[描述]

---

## Database Schema

<!-- 列出每張 table 的 CREATE TABLE statement。 -->
<!-- 包含 index、RLS policy、重要的 constraint。 -->
<!-- 如果某些 table 是實驗性的（還沒實作），標注清楚。 -->

### Table: `[table_name]`

```sql
CREATE TABLE [table_name] (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  -- [其他欄位]
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_[table]_[column] ON [table]([column]);

-- RLS
ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access their own data"
  ON [table_name] FOR ALL
  USING (auth.uid() = user_id);
```

### Table: `[table_name_2]`

```sql
-- ...
```

---

## API / External Services

<!-- 列出你的系統會呼叫的外部 API 或服務，以及權限需求。 -->

<!--
  範例（來自 Wordhenge）：

  ### Manifest Permissions (Chrome Extension)
  ```json
  {
    "permissions": ["storage", "identity", "activeTab"],
    "host_permissions": ["https://docs.google.com/*", "https://*.supabase.co/*"],
    "oauth2": {
      "scopes": ["https://www.googleapis.com/auth/documents.readonly"]
    }
  }
  ```
-->

| Service | Purpose | Auth | Rate Limits |
|---------|---------|------|-------------|
| [Service A] | [用途] | [API key / OAuth] | [限制] |
| [Service B] | [用途] | [API key / OAuth] | [限制] |

---

## Environment Variables

<!-- 列出每個 app 需要的 env vars。不要放實際值，只列出 key 名。 -->

```bash
# [app 路徑] (e.g., apps/web/.env.local)
DATABASE_URL=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# [app 路徑] (e.g., apps/extension/.env)
VITE_SUPABASE_URL=
VITE_API_KEY=
```

---

## Cost Estimates（可選）

<!-- 如果你的系統有按量計費的服務（AI API、雲端函數等），估算單次成本。 -->

| 項目 | 單次成本 |
|------|----------|
| [服務] | ~$X.XX |
| **Total** | **~$X.XX** |

---

*End of TDD*
