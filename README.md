# Dragochi

Dragochi 是一個遊戲時間追蹤 App，目標是先把 MVP 做到可用，再逐步增強體驗與分析能力。

## Current status: planning stage

目前程式碼仍以 SwiftUI 模板為主（例如 `/Users/ericho/iosHub/Dragochi/Dragochi/ContentView.swift`、`/Users/ericho/iosHub/Dragochi/Dragochi/DragochiApp.swift`）。  
以下功能屬於規劃中，尚未完整落地為可用產品流程。

詳細規格請看：[doc/detail-function.md](doc/detail-function.md)

## MVP 功能一覽（Brief）

- Quick Track：一鍵 Start/Stop、可快速套用上次設定（Resume last setup）。
- History：回看每次 session，並可修正時間、teammates，支援合併/拆分 session。
- Monthly Report：本月總時長、game/platform breakdown、月對月比較、6 個月趨勢、teammate 觀察。

## iCloud Sync（Optional）

- OFF：純 local store（SwiftData/Core Data local）。
- ON：CloudKit sync（SwiftData/Core Data + CloudKit）。

## 風險與 UX 保護（重點）

- 忘記 Stop 或中途離開 App：加入長時間 session 提醒與重開 App 恢復流程。
- teammate 統計避免垃圾資訊：以「30/90 日 Rare teammates」取代單純 least teammates。
- 月報比較公平化：加入 This month so far vs Last month same days。

## 文件導覽

- 詳細功能規格：`/Users/ericho/iosHub/Dragochi/doc/detail-function.md`

## UI Screenshot Export Workflow

`DragochiUITests` keeps screenshot artifacts as XCTest attachments (`home.png`, `history.png`, `stats.png`, `settings.png`, `add-session.png`).

Run UI tests with a deterministic simulator destination and keep the result bundle:

```bash
xcodebuild test \
  -scheme Dragochi \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -resultBundlePath build/DragochiUITests.xcresult
```

Export attachment PNG files into the tracked baseline folder:

```bash
scripts/export_ui_screenshots.sh build/DragochiUITests.xcresult screenshots
```

You can also provide a custom output path as the second argument.
