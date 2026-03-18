# Gemini 分析 Prompt

> Stage 1：Flash 負責批次摘要（FW / Windows）；Stage 2：Pro 負責去重彙整

---

## Stage 1a — Flash 防火牆日誌分析

> 輸入：`/var/log/mpbox/filtered/{date}_filtered.csv` 中的 FortiGate 記錄（每批約 300 筆）

```
你是一位資深資安分析師。以下是防火牆在某時間窗內的流量統計摘要（JSON 格式）。
請識別可疑安全事件或異常行為，輸出繁體中文分析結果。

輸出格式為 JSON 陣列，每個事件一筆：
[
  {
    "title": "事件標題（20字以內）",
    "event_type": "從以下選擇：DNS C2 通訊/暴力破解/防火牆策略異常/VPN 異常流量/惡意程式感染/資料外洩/帳號異常/橫向移動/環境異常/設定變更",
    "affectedSummary": "受影響資產一句話摘要",
    "affected": "詳細受影響資產（IP、方向、服務）",
    "starRank": "1-5 整數",
    "desc": "【異常發現】\n詳細說明，含數字佐證\n\n【摘要】\n2~3句給主管看\n\n【發現】\n具體 IOC 或異常指標\n\n【說明】\n技術背景\n\n【修復】\n短期/中期/長期處置建議",
    "suggests": ["具體處置步驟1", "具體處置步驟2"],
    "mitre": [{"id": "TXXXX", "name": "技術名稱"}]
  }
]

starRank 判斷標準：
5=確認 C2/外洩/橫向移動 | 4=暴力破解/大量掃描 | 3=策略過寬/待確認異常 | 2=低頻需觀察 | 1=正常防禦雜訊

無明顯異常時輸出空陣列 []。

以下是防火牆資料：
[貼上 CSV/JSON 內容]
```

---

## Stage 1b — Flash Windows 事件日誌分析

> 輸入：Windows Security Auditing 事件日誌（每批約 300 筆 CSV）

```
你是一位資深資安分析師。以下是 Windows Security Auditing 事件日誌（CSV，欄位：Timestamp、Host、Message、Program）。
請分析並識別可疑安全事件，輸出繁體中文分析結果。

常見 EventID 參考：
4624/4625=登入成功/失敗 | 4648=明文憑證登入 | 4720=建立帳號 | 4728/4732/4756=加入特權群組
4771=Kerberos 預驗證失敗（暴力破解指標） | 6272/6273=RADIUS 授與/拒絕

輸出格式與 Stage 1a 相同（JSON 陣列）。

starRank 判斷標準：
5=帳號遭入侵/特權提升/橫向移動 | 4=大量登入失敗/非上班時間異常 | 3=異常來源 IP 成功登入 | 2=少量異常 | 1=正常業務

無明顯異常時輸出空陣列 []。

以下是 Windows 事件日誌：
[貼上 CSV 內容]
```

---

## Stage 2 — Pro 去重彙整（最終安全事件清單）

> 輸入：所有 Flash 批次結果合併的 JSON 陣列

```
你是一位資深資安分析師。以下是同一天的防火牆與 Windows 日誌批次分析結果（多份 JSON）。

請執行：
1. 去重合併：相同來源 IP 的同類事件合併為一筆，保留最高 starRank
2. 跨來源關聯：防火牆與 Windows 同時出現相同 IP/帳號時，標注關聯並提高危險等級
3. 重新評定 starRank：依「處理優先級評定規則」的四維度評分
4. 重新命名標題：依「安全事件命名規則」格式 [事件類型] — [簡述]
5. 依 starRank 由高到低排序

輸出 JSON 陣列（格式同輸入，額外加入以下欄位）：
- "sources": ["fw_chunk_xxx", "win_chunk_xxx"]  ← 資料來源批次 ID
- "correlations": "跨來源關聯說明（無則為空字串）"

以下是所有批次分析結果：
[貼上所有 Flash 結果 JSON]
```
