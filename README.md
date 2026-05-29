# Dragochi

Dragochi is an iOS app for logging game sessions as a lightweight game-life diary.

Current runtime includes:
- Session tracking (start, pause/resume, stop)
- Session setup (game, platform, teammates, notes)
- History timeline with filters
- Monthly stats (total, platform/game breakdown, MoM)
- Game catalog management (Firebase Remote Config + local fallback)
- Friend management with avatar selection
- Backup export surface (stub implementation)
- UI screenshot test/export workflow

## Product Status

This repository contains both:
- Runtime implementation (tracking-first workflow)
- Vision docs for a broader companion-style diary direction

See [doc/detail-function.md](doc/detail-function.md) and [doc/screen.md](doc/screen.md) for in-code vs planned wording/behavior mapping.

## App Structure

Root tabs (`AppRootView`):
- Home (`MainView` + `MainViewModel`)
- History (`HistoryView` + `HistoryViewModel`)
- Stats (`StatisticView` + `StatisticViewModel`)
- Settings (`SettingsView` + `SettingsViewModel`)

Modal flows:
- Add Session (`AddSessionView` + `AddSessionViewModel`)
- Game Settings (`GameSettingsView` + `GameSettingsViewModel`)
- Friend Settings (`FriendSettingsView` + `FriendSettingsViewModel`)

Architecture layers:
- `Features/*`: SwiftUI views + MVI-style stores
- `Domain/*`: repository/service protocols and core models
- `Data/*`: SwiftData repositories, models, and concrete services

Dependency wiring happens in `AppDependencies`.

## Data & Services

Persistence:
- SwiftData schema includes `GameRecord`, `EnabledGameSelectionRecord`, `FriendRecord`, `SessionRecord`, `SessionFriendRecord`.

Catalog sync:
- `GameCatalogSyncService` seeds from fallback and refreshes from remote.
- `FirebaseRemoteConfigGameCatalogService` fetches `game_catalog_json` and falls back safely when unavailable/invalid.
- Sample payload: `config/game_setting.json`.

Analytics:
- `SwiftDataAnalyticsService` builds `MonthlyReport` from ended sessions.

Backup:
- `StubBackupService` exports current local data payload.
- Import path is currently stubbed (no restore behavior yet).

## Tech Stack

- Swift 5
- SwiftUI
- SwiftData
- Swift Testing (`import Testing`) for logic/data tests
- XCTest UI tests (`ScreenshotUITests`)
- Firebase (Core, Remote Config, Crashlytics)
- Lottie (`lottie-ios`)

SPM dependencies are pinned in:
- `Dragochi.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

## Build Targets & IDs

Primary app target:
- Debug bundle ID: `com.ericho.dragochi.dev`
- Release bundle ID: `com.ericho.Dragochi`

Test targets:
- `DragochiTests`
- `ScreenshotUITests`

Project settings currently use:
- Deployment target: iOS 26.0 (app), iOS 26.2 (tests)

## Setup

1. Open `Dragochi.xcodeproj` in Xcode.
2. Ensure Firebase plist files exist:
   - `firebase/dev/GoogleService-Info.plist`
   - `firebase/prod/GoogleService-Info.plist`
3. Build and run the `Dragochi` scheme.

Notes:
- A build phase script copies the correct Firebase plist based on bundle identifier/configuration.
- Firebase init is skipped in test mode and when plist is unavailable.

## Build & Test (CLI)

Build:

```bash
xcodebuild build \
  -scheme Dragochi \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

Run all tests in scheme:

```bash
xcodebuild test \
  -scheme Dragochi \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -maximum-concurrent-test-simulator-destinations 1
```

Run logic/data tests only:

```bash
xcodebuild test \
  -scheme Dragochi \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:DragochiTests
```

## UI Screenshot Baseline Workflow

`ScreenshotUITests` captures named XCTest attachments:
- `home_idle_no_resume.png`
- `home_idle_resume.png`
- `home_running.png`
- `history.png`
- `stats.png`
- `settings.png`
- `add-session.png`
- `friend-settings-no-friend.png`
- `friend-settings-one-friend.png`
- `friend-settings-many-friends.png`

Generate screenshots:

```bash
xcodebuild test \
  -scheme Dragochi \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath build/ScreenshotUITests.xcresult

scripts/export_ui_screenshots.sh build/ScreenshotUITests.xcresult
```

More details: `screenshots/README.md`.

## Localization

Localizations are managed in `Dragochi/Localizable.xcstrings`.
Current locales include:
- `en`
- `zh-Hans`
- `zh-Hant`

The Settings screen includes a "Per-App Language" shortcut that opens iOS Settings.

## Documentation Map

- Functional spec: [doc/detail-function.md](doc/detail-function.md)
- Screen map and copy status: [doc/screen.md](doc/screen.md)
- Target audience: [doc/target-audience.md](doc/target-audience.md)
- UI system contract: [doc/dragonlet-ui-system.md](doc/dragonlet-ui-system.md)
- Remote Config runbook: [doc/get-remote-config.md](doc/get-remote-config.md)
- Screenshot baseline notes: [screenshots/README.md](screenshots/README.md)

## Known Gaps

Current code has a few intentional placeholders/stubs:
- iCloud sync toggle is local UI state only.
- Backup import path is stubbed and does not restore payload data.
- Some product copy in runtime still reflects the earlier tracking-first wording while docs define the diary-first target direction.
