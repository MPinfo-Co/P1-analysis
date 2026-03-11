# LOG 處理流程圖與 JSON Schema

## 圖 1：系統架構與資料流（Flowchart）

```mermaid
flowchart TD
    A["🖧 SYSLOGNG<br/>每日 09:00–19:00<br/>~180萬筆 / 3.5 GB"] --> B

    B["🔍 Filter 篩選引擎<br/>規則型事件過濾"]

    B -->|每 10 分鐘約 31,000 筆原始| C

    C["📦 批次切割<br/>每 10 分鐘一批<br/>（共 60 批 / 天）"]

    C --> D["⚡ Gemini Flash 分析<br/>每批次產出 JSON<br/>（60 個 Flash JSON / 天）"]

    D --> E["🧠 Gemini Pro 彙整<br/>整合 60 個 Flash JSON<br/>產出異常問題清單"]

    E --> F["📋 SecurityIssue 清單<br/>含 MITRE ATT&CK 標籤<br/>嚴重度排序 + 處理建議"]

    F --> G["🖥️ 資安監控平台<br/>Dashboard 呈現"]

    subgraph 輸入端
        A
    end

    subgraph 處理層
        B
        C
        D
    end

    subgraph AI分析層
        E
        F
    end

    subgraph 呈現層
        G
    end
```

---

## 圖 2：Use Case Diagram

```mermaid
graph LR
    SysAdmin(["👤 系統管理員"])
    SecAnalyst(["👤 資安分析師"])
    Syslogng(["⚙️ SYSLOGNG"])
    Flash(["🤖 Gemini Flash"])
    Pro(["🧠 Gemini Pro"])

    subgraph MPBox["🖥️ MP-Box 平台"]
        UC1["匯入日誌"]
        UC2["篩選規則管理"]
        UC3["批次 LOG 分析"]
        UC4["異常問題產出"]
        UC5["查詢 Issue 清單"]
        UC6["更新 Issue 狀態"]
        UC7["查看 MITRE ATT&CK 標籤"]
        UC8["查看處理建議步驟"]
    end

    Syslogng --> UC1
    SysAdmin --> UC1
    SysAdmin --> UC2
    Flash --> UC3
    Pro --> UC4
    SecAnalyst --> UC5
    SecAnalyst --> UC6
    SecAnalyst --> UC7
    SecAnalyst --> UC8
```

---

## 圖 3：Class Diagram（JSON Schema）

```mermaid
classDiagram
    class SecurityIssue {
        +String id
        +String title
        +Integer starRank
        +String date
        +String affectedSummary
        +String[] affected
        +String currentStatus
        +IssueDesc desc
        +SuggestStep[] suggests
        +LogEntry[] logs
        +MitreTag[] mitre
        +Reference[] refs
    }

    class IssueDesc {
        +String detectionLogic
        +String suspiciousAnalysis
        +String integratedAnalysis
    }

    class SuggestStep {
        +Integer stepNo
        +String action
        +String suggestUrgency
    }

    class LogEntry {
        +String timestamp
        +String sourceIp
        +String destIp
        +String event
        +String rawMessage
    }

    class MitreTag {
        +String id
        +String name
        +String url
    }

    class Reference {
        +String title
        +String url
    }

    SecurityIssue "1" --> "1" IssueDesc : desc
    SecurityIssue "1" --> "0..*" SuggestStep : suggests
    SecurityIssue "1" --> "0..*" LogEntry : logs
    SecurityIssue "1" --> "0..*" MitreTag : mitre
    SecurityIssue "1" --> "0..*" Reference : refs
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
