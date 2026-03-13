# LOG 處理流程圖與 JSON Schema

## 圖 1：系統流程與角色關係

```mermaid
%%{init: {'flowchart': {'rankSpacing': 22, 'nodeSpacing': 12}}}%%
flowchart LR
    subgraph ext[" "]
        direction TB
        extLabel["**外部系統**"]:::zoneLabel
        Syslogng(["**⚙️ SYSLOGNG**"])
    end

    costNote["💰 **每日成本估算**<br/>無篩選　～$5,000<br/>篩選 10%　～$500<br/>篩選 1%　～$50"]:::noteStyle

    subgraph MPBox["🖥️ MP-Box"]
        direction TB
        A["📥 匯入日誌"]
        C["📦 每 10 分鐘批次處理<br/>共 60 批/天"]
        D["**⚡ Gemini Flash**<br/>每批產出 JSON（60 個/天）"]
        E["**🧠 Gemini Pro**<br/>整合 60 個 JSON<br/>產出異常問題清單"]
        F["**🤖 資安專家**<br/>異常問題清單 ／ 建議處理方法<br/>處置日誌 ／ 權限指派"]
        F2["🔮 **資安專家 v2**（規劃中）<br/>儀表板 ／ 一鍵產報告 ／ 知識庫"]:::v2Style
        M["⚙️ 系統管理<br/>帳號 ／ 角色 ／ AI 夥伴"]

        A -->|~31,000 筆 / 10 分| C
        C --> D --> E --> F
        F -.->|規劃中| F2
    end

    subgraph ppl[" "]
        direction TB
        pplLabel["**公司人員**"]:::zoneLabel
        SysAdmin(["👤 系統管理員"])
        SecDept(["👤 資安部門人員"])
    end

    Syslogng -->|篩選後自動推送（每 10 分）| A
    Syslogng -.- costNote
    costNote -.- A
    SysAdmin -->|CSV 上傳（預處理篩選後匯入）| A
    SysAdmin -->|設定管理| M
    SecDept -->|查詢 ／ 更新狀態 ／ 諮詢| F

    style ext fill:transparent,stroke:transparent
    style ppl fill:transparent,stroke:transparent
    classDef zoneLabel fill:none,stroke:none,font-weight:bold,font-size:15px
    classDef noteStyle fill:#fffbe6,stroke:#f59e0b,stroke-width:1.5px,color:#92400e
    classDef v2Style fill:#f0fdf4,stroke:#22c55e,stroke-width:1.5px,color:#166534
```

---

### SuggestUrgency 值域

| 值 | 說明 |
|---|---|
| `立即` | 需立刻處理，風險極高 |
| `今日` | 今天內完成處理 |
| `24小時內` | 24 小時內完成 |
| `本週` | 本週內完成即可 |

### CurrentStatus 值域

| 值 | 說明 |
|---|---|
| `待處理` | 尚未開始處理 |
| `處理中` | 已指派，正在處理 |

---

### JSON 範例（單筆 SecurityIssue）

```json
{
  "id": "issue-001",
  "title": "多次失敗登入嘗試（Brute Force）",
  "starRank": 4,
  "date": "2025-11-05",
  "affectedSummary": "內部主機 192.168.1.105",
  "affected": ["192.168.1.105"],
  "currentStatus": "待處理",
  "desc": {
    "detectionLogic": "偵測到來自同一 IP 在 5 分鐘內失敗登入次數超過 20 次",
    "suspiciousAnalysis": "來源 IP 103.45.67.89 非企業已知地址，嘗試帳號包含常見弱密碼清單",
    "integratedAnalysis": "結合時間序列與帳號分佈，判斷為自動化暴力破解攻擊"
  },
  "suggests": [
    {
      "stepNo": 1,
      "action": "封鎖來源 IP 103.45.67.89 於防火牆",
      "suggestUrgency": "立即"
    },
    {
      "stepNo": 2,
      "action": "重設受影響帳號密碼並啟用 MFA",
      "suggestUrgency": "今日"
    }
  ],
  "logs": [
    {
      "timestamp": "2025-11-05T10:32:15Z",
      "sourceIp": "103.45.67.89",
      "destIp": "192.168.1.105",
      "event": "AUTH_FAILURE",
      "rawMessage": "Failed password for admin from 103.45.67.89 port 54321 ssh2"
    }
  ],
  "mitre": [
    {
      "id": "T1110",
      "name": "Brute Force",
      "url": "https://attack.mitre.org/techniques/T1110/"
    }
  ],
  "refs": [
    {
      "title": "NIST 密碼政策指南",
      "url": "https://pages.nist.gov/800-63-3/"
    }
  ]
}
```
