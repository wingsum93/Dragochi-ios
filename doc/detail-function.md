# Dragochi 詳細功能規格（MVP）

## 1. 目標與範圍

目標：先做到「可用」的遊戲時間追蹤，再逐步加強分析與同步穩定性。  
範圍：本文件定義 MVP 需求、資料模型、報表計算、同步策略與已知風險。

目前狀態說明：現有程式碼仍是模板結構（例如 `/Users/ericho/iosHub/Dragochi/Dragochi/ContentView.swift`），本文件為實作契約，非已上線功能清單。

## 2. 功能規格

### 2.1 Quick Track（最重要）

- 提供 Start / Stop 單一主按鈕（前瞻支援 Live Activity / Dynamic Island）。
- 啟動 session 後，自動記錄：
  - `startTime`
  - `endTime`
  - `duration`
  - `platform`（Mobile / PC，可擴展 Console）
  - `game`（可選，例如 Valorant / LoL / Genshin）
  - `friends`（可多選）
  - `note`（可選：rank、mode、心情）
- 使用者按 Stop 時彈出 sheet，可快速補齊：
  - game
  - platform
  - teammates
  - 可跳過（保持低摩擦）
- 支援 `Resume last setup`：
  - 一鍵套用上次設定（例如 Valorant + PC + 阿明阿強）後直接開始。

### 2.2 History（回看 + 修正）

- 以日曆或列表顯示，每次 session 一行。
- 可編輯欄位：
  - 時間（start/end）
  - teammates
  - game/platform/note
- 進階修正能力：
  - 合併 session
  - 拆分 session

### 2.3 Monthly Report（summary）

- 顯示本月總遊戲時間。
- 依 game / platform 做 breakdown（pie 或 bar 均可）。
- 月對月比較（本月 vs 上月，百分比變化）。
- 最近 6 個月趨勢（line chart）。
- teammates 維度：
  - Most frequent teammate(s)：依共同 session 次數或共同時長。
  - Rarely played with：最近 90 日只出現 1 次的人。

## 3. 報表指標定義（精確化）

- 本月總遊戲時間：`sum(durationSeconds)`（以 session 結束時間所在月份歸檔）。
- Breakdown 維度：
  - game
  - platform
- MoM 比較：
  - `((本月總時長 - 上月總時長) / 上月總時長) * 100%`
  - 上月為 0 時，顯示為 N/A 或以產品規則顯示「新增加」。
- 趨勢：最近 6 個月總時長折線圖。
- Teammates：
  - Most frequent：可切換「共同 session 次數」或「共同總時長」排序。
  - Rare teammates：最近 90 日只出現 1 次。
- 公平比較：
  - `This month so far` vs `Last month same days`。

## 4. Data Model（文件層級規格）

### 4.1 Session

- `id`
- `startAt`
- `endAt`
- `durationSeconds`（可由 `endAt - startAt` 計算，也可快取）
- `platform`（enum）
- `gameId`（optional）
- `note`（optional）

### 4.2 Friend

- `id`
- `name`
- `handle`（optional）

### 4.3 Game

- `id`
- `name`
- `icon`（optional）

### 4.4 SessionFriend

- 多對多關聯表（`Session` <-> `Friend`）。
- 可替代方案：在 `Session` 直接存 `friendIDs[]`。

### 4.5 Platform enum

- `mobile`
- `pc`
- `console`

## 5. iCloud 同步策略（務實版）

- OFF：只用 local store（SwiftData/Core Data local）。
- ON：啟用 CloudKit sync（SwiftData/Core Data + CloudKit）。

前提與限制：

- CloudKit debug 成本偏高。
- schema migration 要小心版本演進。
- sync edge cases（衝突、延遲、離線後補同步）需預留測試時間。

## 6. 已知坑與防呆策略

- 只靠 Start/Stop，容易忘記停止或切 app。
  - 策略：session 超過 X 小時觸發 confirm prompt。
- App 重開時若發現 running session：
  - 提供三選：繼續 / 結束 / 丟棄。
- 「least teammates」資訊價值偏低：
  - 改為「最近 30/90 日 rare teammates」更實用。
- 月報剛開始數據偏少：
  - 使用 `This month so far` 對比 `Last month same days`，避免失真。

## 7. Public APIs / Interfaces / Types 變更

- 本輪不修改任何 runtime code API（文件新增 only）。
- 新增文件規格契約（供後續實作遵循）：
  - Core entity types：`Session`、`Friend`、`Game`、`SessionFriend`
  - Enum contract：`Platform`
  - Metrics contract：`monthly total`、`MoM change`、`rare teammates (90-day)`
- `README.md` 作為 public-facing documentation entrypoint。

## 8. 驗收與測試情境（文件品質）

- 檔案存在：
  - `/Users/ericho/iosHub/Dragochi/README.md`
  - `/Users/ericho/iosHub/Dragochi/doc/detail-function.md`
- README 在 60 秒內可回答：
  - App 做什麼
  - MVP 有什麼
  - 去哪看詳細規格
- 詳細文件完整覆蓋：
  - Quick Track / History / Monthly Report / Data model / iCloud strategy / pitfalls
- 狀態標示清楚：
  - 明確註明目前仍屬規劃，避免誤認為已實作。
- README 連結可正確開啟詳細文件。

## 9. Implementation status

初始狀態全部標記為 `Planned`。

- Quick Track：`Planned`
- History：`Planned`
- Monthly Report：`Planned`
- Data Model（Session/Friend/Game/SessionFriend）：`Planned`
- iCloud Sync Toggle（OFF local / ON CloudKit）：`Planned`
- 防呆機制（長時間提醒、重開恢復流程）：`Planned`

