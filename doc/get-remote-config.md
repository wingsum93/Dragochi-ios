# Remote Config Fetch Flow (`get-remote-config.md`)

## 1. Summary

This document explains how Dragochi fetches game catalog data from Firebase Remote Config. In the new product framing, this catalog powers **diary session context** (which game was part of a moment), not only tracking metrics.

It also documents where to safely change the Remote Config parameter key (`game_catalog_json`).

## 2. Implementation Details

### 2.1 Purpose and Scope

- Scope: game catalog Remote Config flow only.
- Audience: new engineers joining this project.
- Product context: catalog options used by Game Life Diary capture flows.
- Out of scope: non-catalog Firebase features, analytics redesign, and reflection feature logic.

### 2.2 Quick Architecture (Request Path)

1. `DragochiApp` initializes Firebase when possible.
2. `AppDIContainer` wires `GameCatalogService` and `GameCatalogSyncService`.
3. Feature stores trigger seed/refresh operations.
4. `GameCatalogSyncService` asks `FirebaseRemoteConfigGameCatalogService` for latest catalog.
5. Decoded catalog is validated and synced into local repositories.

High-level path:

`DragochiApp` -> `AppDIContainer` -> (`MainViewModel` / `AddSessionViewModel` / `GameSettingsViewModel`) -> `GameCatalogSyncService` -> `FirebaseRemoteConfigGameCatalogService` -> local repositories

### 2.3 Class/Method Map

| Class | Method | Responsibility | Source |
|---|---|---|---|
| `DragochiApp` | `configureFirebaseIfPossible()` | Configure Firebase app when not testing and plist exists. | `/Users/ericho/iosHub/Dragochi/Dragochi/DragochiApp.swift:39` |
| `AppDIContainer` | `init(modelContainer:auditLogger:)` | Own the SwiftData context and wire repositories + catalog service + sync service. | `/Users/ericho/iosHub/Dragochi/Dragochi/AppDIContainer.swift:35` |
| `FirebaseRemoteConfigGameCatalogService` | `init(catalogKey:fallback:)` | Define Remote Config parameter key and fallback catalog. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/FirebaseRemoteConfigGameCatalogService.swift:31` |
| `FirebaseRemoteConfigGameCatalogService` | `fetchLatestCatalog()` | Fetch and decode Remote Config JSON; fallback if unavailable/invalid. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/FirebaseRemoteConfigGameCatalogService.swift:43` |
| `FirebaseRemoteConfigGameCatalogService` | `fetchAndActivate(remoteConfig:)` | Execute `fetchAndActivate` async bridge. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/FirebaseRemoteConfigGameCatalogService.swift:71` |
| `FirebaseRemoteConfigGameCatalogService` | `decodeCatalog(from:)` | Decode and sanitize JSON into `[CatalogGame]`. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/FirebaseRemoteConfigGameCatalogService.swift:89` |
| `GameCatalogSyncService` | `seedFromFallbackIfNeeded()` | Seed initial catalog from fallback and default selections. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/GameCatalogSyncService.swift:30` |
| `GameCatalogSyncService` | `refreshFromRemote()` | Fetch latest catalog from remote and apply retention rules. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/GameCatalogSyncService.swift:36` |
| `GameCatalogSyncService` | `apply(catalog:persistDefaultSelectionIfNeeded:)` | Upsert/cleanup game selection and metadata safely. | `/Users/ericho/iosHub/Dragochi/Dragochi/Data/Services/GameCatalogSyncService.swift:57` |
| `MainViewModel` | `loadInitialData()` and `refreshCatalogFromRemote()` | Seed catalog on load, then refresh from remote. | `/Users/ericho/iosHub/Dragochi/Dragochi/Features/Main/MainViewModel.swift:107`, `/Users/ericho/iosHub/Dragochi/Dragochi/Features/Main/MainViewModel.swift:277` |
| `AddSessionViewModel` | `loadData()` and `refreshFromRemote()` | Seed/refresh catalog to populate Add Session game cards. | `/Users/ericho/iosHub/Dragochi/Dragochi/Features/AddSession/AddSessionViewModel.swift:128`, `/Users/ericho/iosHub/Dragochi/Dragochi/Features/AddSession/AddSessionViewModel.swift:150` |
| `GameSettingsViewModel` | `load()` and `refreshFromRemote()` | Seed/refresh catalog for settings list + enabled toggles. | `/Users/ericho/iosHub/Dragochi/Dragochi/Features/GameSettings/GameSettingsViewModel.swift:68`, `/Users/ericho/iosHub/Dragochi/Dragochi/Features/GameSettings/GameSettingsViewModel.swift:87` |

### 2.4 Runtime Behavior Notes

- Firebase init is skipped during tests and when `GoogleService-Info.plist` is missing.
- `fetchLatestCatalog()` returns fallback when Firebase app is not configured.
- Catalog JSON is sanitized: `id` and `name` are trimmed and must be non-empty.
- Sync keeps session safety rules:
  - No session record deletion during catalog refresh.
  - Session-referenced game records are preserved.

### 2.5 How to Change Remote Config Key (New Joiner Runbook)

1. In Firebase Remote Config, choose a new parameter key (example: `game_catalog_v2`).
2. Update service construction in `/Users/ericho/iosHub/Dragochi/Dragochi/AppDIContainer.swift` to pass the new key:

```swift
lazy var gameCatalogService: GameCatalogService = FirebaseRemoteConfigGameCatalogService(catalogKey: "game_catalog_v2")
```

3. Publish the same JSON payload format under the new Firebase key.
4. Keep schema unchanged (`id`, `name`, `imageAssetName`) unless code changes are planned.
5. Verify locally by launching app and confirming catalog-driven lists update.
6. Rollback: switch `catalogKey` back to previous value and republish if needed.

JSON example payload (from `/Users/ericho/iosHub/Dragochi/config/game_setting.json`):

```json
[
  { "id": "apex_legends", "name": "Apex Legends", "imageAssetName": "apex" },
  { "id": "lol", "name": "LOL", "imageAssetName": "lol" },
  { "id": "world_war_z", "name": "World War Z", "imageAssetName": "wwz" },
  { "id": "clash_royale", "name": "Clash Royale", "imageAssetName": "clash_royale" },
  { "id": "valorant", "name": "Valorant", "imageAssetName": "volarant" }
]
```

### 2.6 Troubleshooting

#### Always fallback catalog

- Check Firebase is configured in app runtime (`GoogleService-Info.plist` present in app bundle).
- Check key name in code matches Firebase parameter exactly.
- Check parameter is published (not only draft) in Firebase console.
- Check app environment is not test mode.

#### Missing Firebase plist behavior

- Expected behavior: app skips Firebase configure and uses fallback catalog.
- Fix: add valid `GoogleService-Info.plist` to target bundle for the correct environment.

#### Invalid JSON decode fallback behavior

- If JSON cannot decode to `[CatalogGame]`, app falls back silently.
- Fix JSON to match schema exactly (`id`, `name`, `imageAssetName`) and republish.

#### Key mismatch between app and Firebase console

- Symptom: app always shows fallback/default catalog.
- Fix: align `catalogKey` in code with Firebase parameter name, then publish and relaunch.

### 2.7 Quick Verification Checklist

- Confirm key name in code (`FirebaseRemoteConfigGameCatalogService(catalogKey: ...)`).
- Confirm key exists and is published in Firebase Remote Config.
- Confirm JSON parses to `[CatalogGame]`.
- Confirm game list reflects remote updates after app launch.

## 3. Documentation-only Scope

- No runtime code/API/type changes are introduced by this document.
- This is a technical onboarding runbook with updated product framing.

## 4. Test Cases and Scenarios (Doc QA)

1. Every referenced class/method exists at listed source paths.
2. New joiner can answer in 2-3 minutes:
   - Where is key defined?
   - Which method fetches remote?
   - How to change key safely?
3. If key changed in code but not Firebase, troubleshooting points to mismatch and fallback behavior.
4. If JSON is malformed, troubleshooting explains decode fallback and corrective action.

## 5. Assumptions and Defaults

- "New JSON key" means Firebase Remote Config parameter key rename.
- Documentation language is English and onboarding-focused.
- JSON schema remains:
  - `id: String`
  - `name: String`
  - `imageAssetName: String?`
- `/Users/ericho/iosHub/Dragochi/config/game_setting.json` is the canonical sample payload.
